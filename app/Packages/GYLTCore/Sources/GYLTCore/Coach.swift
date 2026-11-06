import Foundation

// MARK: - Contract between the coach (any AI) and the app

public enum CoachMoment: Equatable, Sendable {
    case intervention
    case started
    case stuck
    case finished(minimum: Bool, minutes: Int)
}

/// The only information a provider ever receives: small and structured. No history, no app inventory.
public struct CoachContext: Sendable {
    public var commitmentTitle: String
    public var commitmentId: UUID
    public var firstStep: String
    public var minimumMinutes: Int
    public var tone: Tone
    public var persona: Persona
    public var moment: CoachMoment

    public init(commitmentTitle: String, commitmentId: UUID, firstStep: String, minimumMinutes: Int,
                tone: Tone, persona: Persona, moment: CoachMoment) {
        self.commitmentTitle = commitmentTitle; self.commitmentId = commitmentId; self.firstStep = firstStep
        self.minimumMinutes = minimumMinutes; self.tone = tone; self.persona = persona; self.moment = moment
    }
}

/// A fixed vocabulary. A model can propose one of these; it can never invent an action.
public enum CoachSuggestion: String, Codable, CaseIterable, Sendable {
    case none, offerMinimum, askToReschedule, nextStep, takeRestDay
}

public struct CoachReply: Equatable, Sendable {
    public var text: String
    public var suggestion: CoachSuggestion
    public init(text: String, suggestion: CoachSuggestion = .none) { self.text = text; self.suggestion = suggestion }
}

public protocol CoachProvider: Sendable {
    func reply(for context: CoachContext) async throws -> CoachReply
}

/// Treats model output as untrusted: unknown suggestions are dropped, text is bounded and stripped of control characters.
public enum CoachOutputValidator {
    public static let maxCharacters = 280

    public static func suggestion(from raw: String?) -> CoachSuggestion {
        guard let raw else { return .none }
        return CoachSuggestion(rawValue: raw.trimmingCharacters(in: .whitespacesAndNewlines)) ?? .none
    }

    public static func sanitize(_ text: String) -> String {
        let cleaned = text.unicodeScalars.filter { !CharacterSet.controlCharacters.subtracting(.newlines).contains($0) }
        let s = String(String.UnicodeScalarView(cleaned)).trimmingCharacters(in: .whitespacesAndNewlines)
        return s.count > maxCharacters ? String(s.prefix(maxCharacters)) + "…" : s
    }
}

// MARK: - Offline coach: always available, instant, free

public struct ScriptedCoach: CoachProvider {
    public init() {}

    public func reply(for context: CoachContext) async throws -> CoachReply {
        CoachReply(text: line(for: context), suggestion: suggestion(for: context.moment))
    }

    public func suggestion(for moment: CoachMoment) -> CoachSuggestion {
        moment == .stuck ? .offerMinimum : .none
    }

    public func line(for c: CoachContext) -> String {
        let isWalk = c.commitmentId == Commitment.walkID
        switch c.moment {
        case .intervention:
            guard isWalk else {
                switch c.tone {
                case .calm: return "This time is yours. Start with one small step: \(c.firstStep)"
                case .direct: return "You said you would. \(c.firstStep) Now."
                case .savage: return "Your excuses have had a long run. \(c.firstStep) Go."
                }
            }
            switch c.tone {
            case .calm: return "You made this time for yourself. Let’s start with your shoes."
            case .direct: return "You hired me for exactly this moment. Shoes on. Let’s go."
            case .savage: return "The sofa has completed its shift. Shoes on. Your walk starts now."
            }
        case .started:
            return "Good. You’re moving. I’ll leave you to it."
        case .stuck:
            return isWalk ? "Just your shoes and keys. Head to the door. We can figure out the rest outside."
                          : "\(c.firstStep) That’s the whole job for the next minute."
        case .finished(let minimum, let minutes):
            guard minimum else { return "You gave yourself the time. And you followed through." }
            // Never quote a number the timer doesn't back up.
            return minutes >= 1 ? "\(minutes) minute\(minutes == 1 ? "" : "s") beats “I’ll do it tomorrow.” The minimum counts."
                                : "A small start beats “I’ll do it tomorrow.” The minimum counts."
        }
    }

    /// The Coach screen’s quote, by tone.
    public static func quote(tone: Tone) -> String {
        switch tone {
        case .savage: "Your sofa has had enough of you. Shoes on."
        case .calm: "A small start is enough. I’m here when you need me."
        case .direct: "You said you would. I’m here to help you mean it."
        }
    }
}
