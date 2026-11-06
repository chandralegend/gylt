import Foundation

// MARK: - Configuration (no secrets in here; keys live in the Keychain)

public struct AIProviderConfig: Codable, Equatable, Sendable {
    public enum Kind: String, Codable, CaseIterable, Sendable {
        case builtIn, appleOnDevice, anthropic, openAI, custom

        public var title: String {
            switch self {
            case .builtIn: "Built-in coach"
            case .appleOnDevice: "Apple on-device"
            case .anthropic: "Anthropic"
            case .openAI: "OpenAI"
            case .custom: "Custom endpoint"
            }
        }
        /// Providers that need a key from the user.
        public var needsKey: Bool { self == .anthropic || self == .openAI || self == .custom }
        public var defaultModel: String {
            switch self {
            case .anthropic: "claude-haiku-5-5"
            case .openAI: "gpt-4o-mini"
            default: ""
            }
        }
        /// Keychain account name.
        public var account: String { "ai.\(rawValue)" }
    }

    public var kind: Kind = .builtIn
    public var model: String = ""
    /// Custom endpoint base URL, e.g. https://openrouter.ai/api/v1 or http://192.168.1.20:11434/v1
    public var baseURL: String = ""
    public init(kind: Kind = .builtIn, model: String = "", baseURL: String = "") {
        self.kind = kind; self.model = model; self.baseURL = baseURL
    }
    public var effectiveModel: String { model.isEmpty ? kind.defaultModel : model }
}

public enum CoachProviderError: Error, Equatable, Sendable {
    case missingKey, badEndpoint, http(Int), emptyReply, unreachable, unavailable
}

// MARK: - Endpoint policy

public enum EndpointPolicy {
    /// HTTPS always. Plain HTTP only for a model running on this device or the local network (e.g. Ollama on a Mac).
    public static func validate(_ string: String) -> URL? {
        guard let url = URL(string: string.trimmingCharacters(in: .whitespacesAndNewlines)),
              let scheme = url.scheme?.lowercased(), let host = url.host?.lowercased(), !host.isEmpty else { return nil }
        if scheme == "https" { return url }
        if scheme == "http", isLocal(host) { return url }
        return nil
    }

    public static func isLocal(_ host: String) -> Bool {
        if host == "localhost" || host == "127.0.0.1" || host == "::1" || host.hasSuffix(".local") { return true }
        let parts = host.split(separator: ".").compactMap { Int($0) }
        guard parts.count == 4 else { return false }
        return parts[0] == 10 || (parts[0] == 192 && parts[1] == 168) || (parts[0] == 172 && (16...31).contains(parts[1]))
    }

    /// What the user is told before a key is saved: where requests go and what they contain.
    public static func disclosure(for kind: AIProviderConfig.Kind, host: String?) -> String {
        let dest: String
        switch kind {
        case .anthropic: dest = "api.anthropic.com"
        case .openAI: dest = "api.openai.com"
        case .custom: dest = host ?? "your endpoint"
        default: return "Nothing leaves your phone."
        }
        return "Each coach line sends the promise’s name, its first step, your chosen tone and the moment (like “start” or “stuck”) from your phone straight to \(dest). Never your history, your apps, your location or health data. When you finish a promise, any photo or words you choose to show as proof go the same way, only when you send them. GYLT has no servers and does not see your key or your requests. The provider may charge you for usage."
    }
}

// MARK: - Prompt (small, structured, no history)

public enum CoachPromptBuilder {
    public static let maxTokens = 120

    public static func system(tone: Tone, persona: Persona) -> String {
        let voice: String
        switch tone {
        case .calm: voice = "warm and steady"
        case .direct: voice = "direct and brisk"
        case .savage: voice = "blunt and teasing, never cruel"
        }
        return """
        You are the coach in an accountability app. Persona: \(persona.rawValue). Voice: \(voice).
        Write at most two short sentences that help the person start or finish the commitment they chose.
        Rules: never insult the person's identity or body; never mention illness or medical advice; never promise to change, extend or add any rule, block or penalty; never ask for personal information.
        Reply with only this JSON: {"text": "<your line>", "suggestion": "<none|offerMinimum|askToReschedule|nextStep|takeRestDay>"}
        """
    }

    public static func user(_ c: CoachContext) -> String {
        let moment: String
        switch c.moment {
        case .intervention: moment = "It is time to start."
        case .started: moment = "They just started."
        case .stuck: moment = "They say they are stuck."
        case .finished(let minimum, _): moment = minimum ? "They finished the small minimum version." : "They finished the full version."
        }
        return "Commitment: \(c.commitmentTitle). First step: \(c.firstStep). The minimum version is \(c.minimumMinutes) minutes. \(moment)"
    }
}

// MARK: - Output is untrusted

public enum CoachReplyParser {
    /// Accepts the requested JSON, JSON wrapped in prose or a code fence, or plain text. Unknown suggestions are dropped.
    public static func parse(_ raw: String) -> CoachReply? {
        if let data = jsonObject(in: raw),
           let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let text = obj["text"] as? String {
            let clean = CoachOutputValidator.sanitize(text)
            guard !clean.isEmpty else { return nil }
            return CoachReply(text: clean, suggestion: CoachOutputValidator.suggestion(from: obj["suggestion"] as? String))
        }
        let clean = CoachOutputValidator.sanitize(raw)
        // Plain prose is fine. Something shaped like JSON that lacks a usable "text" is a malformed reply: never show it to the person.
        if clean.hasPrefix("{") || clean.hasPrefix("[") || clean.hasPrefix("```") { return nil }
        return clean.isEmpty ? nil : CoachReply(text: clean, suggestion: .none)
    }

    private static func jsonObject(in raw: String) -> Data? {
        guard let start = raw.firstIndex(of: "{"), let end = raw.lastIndex(of: "}"), start < end else { return nil }
        return String(raw[start...end]).data(using: .utf8)
    }
}

// MARK: - Providers

public struct AnthropicProvider: CoachProvider {
    public let apiKey: String, model: String, session: URLSession, timeout: TimeInterval
    public init(apiKey: String, model: String, session: URLSession = .shared, timeout: TimeInterval = 8) {
        self.apiKey = apiKey; self.model = model; self.session = session; self.timeout = timeout
    }

    public func reply(for context: CoachContext) async throws -> CoachReply {
        guard !apiKey.isEmpty else { throw CoachProviderError.missingKey }
        var req = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!, timeoutInterval: timeout)
        req.httpMethod = "POST"
        req.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        let body: [String: Any] = [
            "model": model, "max_tokens": CoachPromptBuilder.maxTokens,
            "system": CoachPromptBuilder.system(tone: context.tone, persona: context.persona),
            "messages": [["role": "user", "content": CoachPromptBuilder.user(context)]],
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let data = try await Transport.send(req, session: session)
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let blocks = obj["content"] as? [[String: Any]],
              let text = blocks.compactMap({ $0["type"] as? String == "text" ? $0["text"] as? String : nil }).first,
              let reply = CoachReplyParser.parse(text) else { throw CoachProviderError.emptyReply }
        return reply
    }
}

/// OpenAI, and anything that speaks its chat-completions shape: OpenRouter, Groq, Ollama, LM Studio…
public struct OpenAICompatibleProvider: CoachProvider {
    public let baseURL: URL, apiKey: String, model: String, session: URLSession, timeout: TimeInterval
    public init(baseURL: URL, apiKey: String, model: String, session: URLSession = .shared, timeout: TimeInterval = 8) {
        self.baseURL = baseURL; self.apiKey = apiKey; self.model = model; self.session = session; self.timeout = timeout
    }

    public static let openAIBase = URL(string: "https://api.openai.com/v1")!

    public func reply(for context: CoachContext) async throws -> CoachReply {
        guard !apiKey.isEmpty else { throw CoachProviderError.missingKey }
        var req = URLRequest(url: baseURL.appendingPathComponent("chat/completions"), timeoutInterval: timeout)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        let body: [String: Any] = [
            "model": model, "max_tokens": CoachPromptBuilder.maxTokens,
            "messages": [["role": "system", "content": CoachPromptBuilder.system(tone: context.tone, persona: context.persona)],
                         ["role": "user", "content": CoachPromptBuilder.user(context)]],
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let data = try await Transport.send(req, session: session)
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = obj["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let text = message["content"] as? String,
              let reply = CoachReplyParser.parse(text) else { throw CoachProviderError.emptyReply }
        return reply
    }
}

enum Transport {
    static func send(_ request: URLRequest, session: URLSession) async throws -> Data {
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw CoachProviderError.unreachable }
            guard (200..<300).contains(http.statusCode) else { throw CoachProviderError.http(http.statusCode) }
            return data
        } catch let e as CoachProviderError {
            throw e
        } catch {
            throw CoachProviderError.unreachable
        }
    }
}

/// Builds the provider the user chose, or nil when only the built-in coach applies.
public enum CoachProviderFactory {
    public static func make(_ config: AIProviderConfig, secrets: SecretStore, session: URLSession = .shared) -> (any CoachProvider)? {
        switch config.kind {
        case .builtIn, .appleOnDevice: return nil   // the app supplies the on-device provider
        case .anthropic:
            guard let key = secrets.read(account: config.kind.account), !key.isEmpty else { return nil }
            return AnthropicProvider(apiKey: key, model: config.effectiveModel, session: session)
        case .openAI:
            guard let key = secrets.read(account: config.kind.account), !key.isEmpty else { return nil }
            return OpenAICompatibleProvider(baseURL: OpenAICompatibleProvider.openAIBase, apiKey: key, model: config.effectiveModel, session: session)
        case .custom:
            guard let url = EndpointPolicy.validate(config.baseURL), !config.effectiveModel.isEmpty else { return nil }
            // A local model may need no key; hosted endpoints do.
            let key = secrets.read(account: config.kind.account) ?? "none"
            return OpenAICompatibleProvider(baseURL: url, apiKey: key, model: config.effectiveModel, session: session)
        }
    }
}

/// The coach everyone gets: an AI line when a provider is set up and answers in time, otherwise the instant scripted line.
public struct FallbackCoach: Sendable {
    public let provider: (any CoachProvider)?
    public let scripted = ScriptedCoach()
    public init(provider: (any CoachProvider)?) { self.provider = provider }

    /// Returns the reply and whether it came from an AI provider.
    public func reply(for context: CoachContext) async -> (reply: CoachReply, fromAI: Bool) {
        if let provider, let r = try? await provider.reply(for: context) { return (r, true) }
        return (CoachReply(text: scripted.line(for: context), suggestion: scripted.suggestion(for: context.moment)), false)
    }
}
