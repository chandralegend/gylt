import Foundation

// MARK: - Apps the user can choose to pause

/// Simulated app identities. On a device these are replaced by opaque Screen Time selection tokens.
public enum ProtectedApp: String, Codable, CaseIterable, Sendable, Identifiable {
    case instagram, tiktok, youtube
    public var id: String { rawValue }
    public var displayName: String {
        switch self {
        case .instagram: "Instagram"
        case .tiktok: "TikTok"
        case .youtube: "YouTube"
        }
    }
}

// MARK: - Commitment (the reusable plan)

public struct Commitment: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var revision: Int
    public var title: String
    public var summary: String
    public var firstStep: String
    public var iconName: String
    public var fullMinutes: Int
    public var minimumMinutes: Int
    public var startHour: Int
    public var startMinute: Int
    public var timeZoneIdentifier: String
    public var blockingEnabled: Bool
    public var protectedApps: Set<ProtectedApp>
    /// Length of any restriction, counted from the moment authority is granted.
    public var restrictionWindowMinutes: Int
    public var isEnabled: Bool

    public init(
        id: UUID = UUID(), revision: Int = 1, title: String, summary: String = "", firstStep: String = "",
        iconName: String = "zap", fullMinutes: Int, minimumMinutes: Int, startHour: Int, startMinute: Int = 0,
        timeZoneIdentifier: String = TimeZone.current.identifier, blockingEnabled: Bool = false,
        protectedApps: Set<ProtectedApp> = [], restrictionWindowMinutes: Int = 30, isEnabled: Bool = true
    ) {
        self.id = id; self.revision = revision; self.title = title; self.summary = summary; self.firstStep = firstStep
        self.iconName = iconName; self.fullMinutes = fullMinutes; self.minimumMinutes = minimumMinutes
        self.startHour = startHour; self.startMinute = startMinute; self.timeZoneIdentifier = timeZoneIdentifier
        self.blockingEnabled = blockingEnabled; self.protectedApps = protectedApps
        self.restrictionWindowMinutes = restrictionWindowMinutes; self.isEnabled = isEnabled
    }

    public static let walkID = UUID(uuidString: "00000000-0000-4000-8000-000000000001")!
    public static let bedID = UUID(uuidString: "00000000-0000-4000-8000-000000000002")!
    public static let nightID = UUID(uuidString: "00000000-0000-4000-8000-000000000003")!

    /// The three anchors from the design. Only the walk uses restrictions.
    public static func defaults(timeZone: TimeZone = .current) -> [Commitment] {
        [
            Commitment(id: walkID, title: "Evening walk", summary: "A little fresh air before the evening disappears.",
                       firstStep: "Shoes. Keys. Outside.", iconName: "human-run", fullMinutes: 20, minimumMinutes: 5,
                       startHour: 18, startMinute: 30, timeZoneIdentifier: timeZone.identifier, blockingEnabled: true,
                       protectedApps: Set(ProtectedApp.allCases)),
            Commitment(id: bedID, title: "Make your bed", summary: "Done before the first scroll.",
                       firstStep: "Straighten the sheets.", iconName: "bed", fullMinutes: 3, minimumMinutes: 1,
                       startHour: 7, startMinute: 30, timeZoneIdentifier: timeZone.identifier),
            Commitment(id: nightID, title: "Call it a night", summary: "Screens off. Tomorrow can wait.",
                       firstStep: "Put the phone down.", iconName: "moon", fullMinutes: 10, minimumMinutes: 3,
                       startHour: 22, startMinute: 30, timeZoneIdentifier: timeZone.identifier),
        ]
    }
}

// MARK: - Occurrence (one scheduled opportunity)

public enum OccurrenceState: String, Codable, Sendable {
    case scheduled, due, active, awaitingConfirmation
    case completedFull, completedMinimum, rescheduled, pausedForDay, overriddenUnfinished, missed

    public var isTerminal: Bool {
        switch self {
        case .scheduled, .due, .active, .awaitingConfirmation: false
        default: true
        }
    }
}

public enum OccurrenceKind: String, Codable, Sendable {
    /// A scheduled opportunity: counted in follow-through metrics.
    case scheduled
    /// Optional extra time ("five more minutes", "try again"): never counted as an opportunity.
    case extra
}

public enum SessionMode: String, Codable, Sendable {
    case full, minimum
}

public struct Session: Codable, Equatable, Sendable {
    public var id: UUID
    public var mode: SessionMode
    public var fullSeconds: Int
    public var minimumSeconds: Int
    public var startedAt: Date
    /// Active time from segments that have already ended.
    public var closedActiveSeconds: Double
    /// Start of the current running segment; nil while paused or finished.
    public var runningSince: Date?

    public var targetSeconds: Int { mode == .full ? fullSeconds : minimumSeconds }
    public var isRunning: Bool { runningSince != nil }

    public func activeSeconds(at now: Date) -> Double {
        closedActiveSeconds + (runningSince.map { max(0, now.timeIntervalSince($0)) } ?? 0)
    }
    public func remainingSeconds(at now: Date) -> Double {
        max(0, Double(targetSeconds) - activeSeconds(at: now))
    }
}

public enum LeaseStatus: String, Codable, Sendable { case active, released }

public enum ReleaseReason: String, Codable, Sendable {
    case completed, overridden, rescheduled, rested, expired, permissionRevoked, clockAnomaly, missed
}

/// Authority the user granted for one occurrence. `expiresAt` is a `let`: it cannot be moved later by any code path.
public struct RestrictionLease: Codable, Equatable, Sendable {
    public var id: UUID
    public let expiresAt: Date
    public var apps: Set<ProtectedApp>
    public var status: LeaseStatus
    public var grantedAt: Date
    public var releasedAt: Date?
    public var releaseReason: ReleaseReason?

    public init(id: UUID = UUID(), grantedAt: Date, expiresAt: Date, apps: Set<ProtectedApp>) {
        self.id = id; self.grantedAt = grantedAt; self.expiresAt = expiresAt; self.apps = apps
        self.status = .active
    }
}

public enum OutcomeKind: String, Codable, Sendable { case full, minimum, unfinished, rested, rescheduled, missed }
/// selfReport: the person said so. aiReviewed: the person showed a photo and/or explanation and their chosen model judged it.
public enum EvidenceSource: String, Codable, Sendable { case selfReport, aiReviewed, none }

public struct Outcome: Codable, Equatable, Sendable {
    public var kind: OutcomeKind
    public var activeMinutes: Double?
    public var evidence: EvidenceSource
    public var recordedAt: Date
    /// For a reviewed outcome: the model's short reason, shown back to the person. Never the photo or their own text.
    public var note: String?
}

public struct Occurrence: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var opportunityId: UUID
    public var rescheduledFromOccurrenceId: UUID?
    public var continuesOccurrenceId: UUID?
    public var kind: OccurrenceKind
    public var commitmentId: UUID
    public var commitmentRevision: Int
    public var localDate: String
    public var scheduledStart: Date
    public var state: OccurrenceState
    public var consentVersion: Int
    public var session: Session?
    public var lease: RestrictionLease?
    public var outcome: Outcome?

    public var hasActiveLease: Bool { lease?.status == .active }
}

// MARK: - Events

public enum EventType: String, Codable, Sendable {
    case occurrenceScheduled, occurrenceDue, sessionStarted, timerPaused, timerResumed, targetChanged, targetReached
    case outcomeRecorded, rescheduled, restedForDay, overridden, missed
    case restrictionApplied, restrictionReleased, restrictionExpired, permissionChanged, clockAnomaly
    case freshStartCreated, commitmentChanged, settingsChanged
}

public struct Event: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var sequence: Int
    public var occurrenceId: UUID?
    public var type: EventType
    public var at: Date
    public var detail: [String: String]
}

// MARK: - Settings and app state

public enum Tone: String, Codable, CaseIterable, Sendable { case calm = "Calm", direct = "Direct", savage = "Savage" }

public enum Persona: String, Codable, CaseIterable, Sendable {
    case coach = "The Coach", deadpanFriend = "The Deadpan Friend", operatorPersona = "The Operator"
    public var blurb: String {
        switch self {
        case .coach: "Firm, encouraging, no endless negotiations."
        case .deadpanFriend: "Dry humor. Unimpressed by your excuses."
        case .operatorPersona: "Calm, precise, one instruction at a time."
        }
    }
}

public struct Settings: Codable, Equatable, Sendable {
    public var tone: Tone = .direct
    public var persona: Persona = .coach
    public var coachAudioOn: Bool = false
    public var onboardingCompleted: Bool = false
    /// The version of the consent contract the user accepted; nil until they do.
    public var consentAcceptedVersion: Int?
    public var ai: AIProviderConfig = AIProviderConfig()
    public init() {}

    // Older saved states lack newer keys: decode what is there and default the rest, never discard the user's data.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        tone = try c.decodeIfPresent(Tone.self, forKey: .tone) ?? .direct
        persona = try c.decodeIfPresent(Persona.self, forKey: .persona) ?? .coach
        coachAudioOn = try c.decodeIfPresent(Bool.self, forKey: .coachAudioOn) ?? false
        onboardingCompleted = try c.decodeIfPresent(Bool.self, forKey: .onboardingCompleted) ?? false
        consentAcceptedVersion = try c.decodeIfPresent(Int.self, forKey: .consentAcceptedVersion)
        ai = try c.decodeIfPresent(AIProviderConfig.self, forKey: .ai) ?? AIProviderConfig()
    }
    enum Keys: String, CodingKey { case tone, persona, coachAudioOn, onboardingCompleted, consentAcceptedVersion, ai }
}

public struct Permissions: Codable, Equatable, Sendable {
    /// Whether the user has authorized restrictions. Simulated in the simulator.
    public var restrictionsAuthorized: Bool = true
    public init() {}
}

public struct AppState: Codable, Equatable, Sendable {
    public var commitments: [Commitment]
    public var occurrences: [Occurrence]
    public var events: [Event]
    public var nextSequence: Int
    public var lastObservedAt: Date?
    public var appliedCommandIds: [UUID]
    public var consentVersion: Int
    public var permissions: Permissions
    public var settings: Settings

    public init(commitments: [Commitment] = Commitment.defaults(), consentVersion: Int = 1) {
        self.commitments = commitments
        self.occurrences = []
        self.events = []
        self.nextSequence = 1
        self.lastObservedAt = nil
        self.appliedCommandIds = []
        self.consentVersion = consentVersion
        self.permissions = Permissions()
        self.settings = Settings()
    }

    public func commitment(_ id: UUID) -> Commitment? { commitments.first { $0.id == id } }
    public func occurrence(_ id: UUID) -> Occurrence? { occurrences.first { $0.id == id } }
}
