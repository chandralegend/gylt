import Foundation

/// Applies and removes app pauses. The app uses Screen Time (FamilyControls and ManagedSettings); tests use `SimulatedRestrictionAdapter`.
public protocol RestrictionAdapter: Sendable {
    /// True only when the OS can really pause apps: Screen Time approved and apps chosen. The UI never claims a pause otherwise.
    var isReal: Bool { get }
    var isAvailable: Bool { get }
    func apply(leaseId: UUID, apps: Set<ProtectedApp>, expiresAt: Date) async
    func release(leaseId: UUID) async
    /// Runs when the engine has no active pause: make sure nothing is still shielded.
    func clearLeftovers()
}

public extension RestrictionAdapter {
    func clearLeftovers() {}
}

/// For tests only. Records what the engine asked for and does nothing else.

public final class SimulatedRestrictionAdapter: RestrictionAdapter, @unchecked Sendable {
    public struct Call: Equatable, Sendable {
        public enum Kind: Equatable, Sendable { case apply, release }
        public var kind: Kind
        public var leaseId: UUID
    }
    private let lock = NSLock()
    private var recorded: [Call] = []
    public init() {}
    public var isAvailable: Bool { true }
    public var isReal: Bool { false }
    public var calls: [Call] { lock.withLock { recorded } }
    public func apply(leaseId: UUID, apps: Set<ProtectedApp>, expiresAt: Date) async {
        lock.withLock { recorded.append(.init(kind: .apply, leaseId: leaseId)) }
    }
    public func release(leaseId: UUID) async {
        lock.withLock { recorded.append(.init(kind: .release, leaseId: leaseId)) }
    }
}

/// Reminder delivery. A bounded policy: one reminder at the agreed time and at most one gentle follow-up, never a loop.
public protocol Notifier: Sendable {
    func requestAuthorization() async -> Bool
    func schedule(occurrenceId: UUID, at date: Date, title: String, body: String) async
    func cancel(occurrenceId: UUID) async
    func cancelAll() async
}

/// Credentials. The app uses the Keychain; tests use memory. Never log, sync or export a secret.
public protocol SecretStore: Sendable {
    func read(account: String) -> String?
    func save(_ secret: String, account: String) throws
    func delete(account: String)
}

public final class InMemorySecretStore: SecretStore, @unchecked Sendable {
    private let lock = NSLock()
    private var items: [String: String] = [:]
    public init() {}
    public func read(account: String) -> String? { lock.withLock { items[account] } }
    public func save(_ secret: String, account: String) throws { lock.withLock { items[account] = secret } }
    public func delete(account: String) { lock.withLock { _ = items.removeValue(forKey: account) } }
}
