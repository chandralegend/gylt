import Foundation

/// Applies and removes real app restrictions. The simulator uses `SimulatedRestrictionAdapter`;
/// a device build swaps in a FamilyControls/ManagedSettings implementation (Milestone 3).
public protocol RestrictionAdapter: Sendable {
    /// True only when restrictions are really enforced by the OS. The UI must say "simulated" otherwise.
    var isReal: Bool { get }
    var isAvailable: Bool { get }
    func apply(leaseId: UUID, apps: Set<ProtectedApp>, expiresAt: Date) async
    func release(leaseId: UUID) async
}

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
