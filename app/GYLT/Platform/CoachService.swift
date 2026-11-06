import Foundation
import GYLTCore
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Apple's on-device model: free, private, no key. Only on iPhones and OS versions that support it.
enum AppleOnDevice {
    static var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            if case .available = SystemLanguageModel.default.availability { return true }
        }
        #endif
        return false
    }

    static func makeJudge() -> (any ProofJudge)? {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), isAvailable { return OnDeviceJudge() }
        #endif
        return nil
    }

    static func makeProvider() -> (any CoachProvider)? {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), isAvailable { return OnDeviceProvider() }
        #endif
        return nil
    }
}

#if canImport(FoundationModels)
@available(iOS 26.0, *)
private struct OnDeviceProvider: CoachProvider {
    func reply(for context: CoachContext) async throws -> CoachReply {
        let session = LanguageModelSession(instructions: CoachPromptBuilder.system(tone: context.tone, persona: context.persona))
        let response = try await session.respond(to: CoachPromptBuilder.user(context))
        guard let reply = CoachReplyParser.parse(response.content) else { throw CoachProviderError.emptyReply }
        return reply
    }
}

/// Text only: Apple's on-device model can't look at photos.
@available(iOS 26.0, *)
private struct OnDeviceJudge: ProofJudge {
    var acceptsPhotos: Bool { false }
    func judge(_ c: ProofContext) async throws -> ProofVerdict {
        guard c.hasExplanation else { throw ProofError.nothingToReview }
        let session = LanguageModelSession(instructions: ProofPromptBuilder.system(tone: c.tone, persona: c.persona))
        let response = try await session.respond(to: ProofPromptBuilder.user(c))
        guard let verdict = ProofVerdictParser.parse(response.content) else { throw ProofError.unreadableVerdict }
        return verdict
    }
}
#endif

/// Picks the coach the user chose and always falls back to the scripted one. Counts calls so cost is visible.
@MainActor
final class CoachService {
    let secrets: SecretStore
    init(secrets: SecretStore) { self.secrets = secrets }

    private var usageKey: String {
        let c = Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: .now)
        return "coachCalls.\(c.yearForWeekOfYear ?? 0)-\(c.weekOfYear ?? 0)"
    }
    var callsThisWeek: Int { UserDefaults.standard.integer(forKey: usageKey) }
    private func countCall() { UserDefaults.standard.set(callsThisWeek + 1, forKey: usageKey) }

    func provider(for config: AIProviderConfig) -> (any CoachProvider)? {
        config.kind == .appleOnDevice ? AppleOnDevice.makeProvider() : CoachProviderFactory.make(config, secrets: secrets)
    }

    /// Who can judge proof for this setup: a hosted provider with a key, Apple's on-device model, or nobody (built-in coach).
    func judge(config: AIProviderConfig) -> (any ProofJudge)? {
        config.kind == .appleOnDevice ? AppleOnDevice.makeJudge() : ProofJudgeFactory.make(config, secrets: secrets)
    }

    func review(_ context: ProofContext, config: AIProviderConfig) async throws -> ProofVerdict {
        guard let judge = judge(config: config) else { throw CoachProviderError.unavailable }
        var ctx = context
        if !judge.acceptsPhotos { ctx.photoJPEG = nil }
        if config.kind != .appleOnDevice { countCall() }
        return try await judge.judge(ctx)
    }

    func reply(for context: CoachContext, config: AIProviderConfig) async -> (reply: CoachReply, fromAI: Bool) {
        let provider = provider(for: config)
        if provider != nil, config.kind != .appleOnDevice { countCall() }
        return await FallbackCoach(provider: provider).reply(for: context)
    }

    /// For the "Test connection" button: a real request, with a plain-language result and no secrets in it.
    func test(config: AIProviderConfig) async -> (ok: Bool, message: String) {
        guard let provider = provider(for: config) else {
            return (false, config.kind == .appleOnDevice ? "Apple’s on-device model isn’t available on this iPhone." : "Add a key (and a model for a custom endpoint) first.")
        }
        let ctx = CoachContext(commitmentTitle: "Test", commitmentId: UUID(), firstStep: "Say hello.", minimumMinutes: 1,
                               tone: .direct, persona: .coach, moment: .started)
        do {
            let r = try await provider.reply(for: ctx)
            if config.kind != .appleOnDevice { countCall() }
            return (true, "Connected. The coach replied: “\(r.text)”")
        } catch CoachProviderError.http(let code) {
            return (false, code == 401 || code == 403 ? "The provider rejected the key (\(code))." : "The provider returned an error (\(code)). Check the model name.")
        } catch CoachProviderError.unreachable {
            return (false, "Couldn’t reach the provider. Check your connection and the address.")
        } catch CoachProviderError.emptyReply {
            return (false, "The provider answered, but GYLT couldn’t use the reply. Try another model.")
        } catch {
            // Local errors (e.g. the on-device model declining) carry no secrets, so they are safe to show.
            let note = config.kind == .appleOnDevice ? " Apple’s on-device model may not run in the simulator; try an iPhone with Apple Intelligence." : ""
            return (false, "The coach couldn’t answer: \(error.localizedDescription)\(note)")
        }
    }
}
