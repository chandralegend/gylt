import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity
import GYLTCore

/// The user's chosen apps, stored as the opaque tokens Screen Time hands out (never as bundle IDs).
enum SelectionStore {
    private static var url: URL { AppGroup.file("selection.json") }

    static func load() -> FamilyActivitySelection {
        (try? Data(contentsOf: url)).flatMap { try? JSONDecoder().decode(FamilyActivitySelection.self, from: $0) } ?? FamilyActivitySelection()
    }
    static func save(_ selection: FamilyActivitySelection) {
        if let d = try? JSONEncoder().encode(selection) { try? d.write(to: url, options: .atomic) }
    }
    /// Apps + categories + sites the user really chose.
    static func count() -> Int {
        let s = load()
        return s.applicationTokens.count + s.categoryTokens.count + s.webDomainTokens.count
    }
    static func isEmpty(_ s: FamilyActivitySelection) -> Bool {
        s.applicationTokens.isEmpty && s.categoryTokens.isEmpty && s.webDomainTokens.isEmpty
    }
}

enum ScreenTimeAccess {
    static var status: AuthorizationStatus { AuthorizationCenter.shared.authorizationStatus }
    static var isApproved: Bool { status == .approved }
    static var statusText: String {
        switch status {
        case .approved: "Approved"
        case .denied: "Denied"
        case .notDetermined: "Not asked yet"
        @unknown default: "Unknown"
        }
    }

    /// Individual authorization: the user can always revoke it, and so can we describe it honestly.
    static func request() async throws {
        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
    }
}

/// Applies a shield to the chosen apps and asks the OS to end it at a fixed time, even if GYLT is closed.
final class ScreenTimeRestrictionAdapter: RestrictionAdapter, @unchecked Sendable {
    private let store = ManagedSettingsStore(named: .init(ShieldStoreName.name))
    private let center = DeviceActivityCenter()

    var isReal: Bool { ScreenTimeAccess.isApproved && !SelectionStore.isEmpty(SelectionStore.load()) }
    var isAvailable: Bool { isReal }

    static func activityName(for leaseId: UUID) -> DeviceActivityName { DeviceActivityName("gylt.lease.\(leaseId.uuidString)") }

    func apply(leaseId: UUID, apps: Set<ProtectedApp>, expiresAt: Date) async {
        await applyShield(leaseId: leaseId, expiresAt: expiresAt, isTest: false)
    }

    /// Used only by the Screen Time test screen.
    func applyTest(expiresAt: Date) async {
        await applyShield(leaseId: UUID(), expiresAt: expiresAt, isTest: true)
    }

    private func applyShield(leaseId: UUID, expiresAt: Date, isTest: Bool) async {
        let selection = SelectionStore.load()
        guard ScreenTimeAccess.isApproved, !SelectionStore.isEmpty(selection) else {
            SpikeLog.write("app", "apply skipped: approved=\(ScreenTimeAccess.isApproved) selectionEmpty=\(SelectionStore.isEmpty(selection))")
            return
        }
        // 1. Shield now.
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
        ShieldLeaseFile.write(ShieldLeaseInfo(leaseId: leaseId, expiresAt: expiresAt, isTest: isTest))

        // 2. Ask the OS to end it at the fixed time. The monitor extension clears the shield even if this app is not running.
        let cal = Calendar.current
        let start = Date().addingTimeInterval(-60)
        let schedule = DeviceActivitySchedule(
            intervalStart: cal.dateComponents([.hour, .minute, .second], from: start),
            intervalEnd: cal.dateComponents([.hour, .minute, .second], from: expiresAt),
            repeats: false)
        let name = Self.activityName(for: leaseId)
        do {
            try center.startMonitoring(name, during: schedule)
            SpikeLog.write("app", "shield applied\(isTest ? " (TEST)" : ""); monitoring \(name.rawValue) until \(Self.clock(expiresAt))")
        } catch {
            // If the OS can't promise the end, don't leave an open-ended restriction behind.
            store.clearAllSettings()
            ShieldLeaseFile.clear()
            SpikeLog.write("app", "startMonitoring FAILED (\(error)); shield removed so nothing can outlive its deadline")
        }
    }

    func release(leaseId: UUID) async {
        center.stopMonitoring([Self.activityName(for: leaseId)])
        store.clearAllSettings()
        ShieldLeaseFile.clear()
        SpikeLog.write("app", "released lease \(leaseId.uuidString.prefix(8)); shield cleared")
    }

    /// Belt and braces: whenever the app runs and no lease is active, make sure no shield is left behind.
    func clearEverything() {
        center.stopMonitoring()
        store.clearAllSettings()
        ShieldLeaseFile.clear()
    }

    static func clock(_ d: Date) -> String { let f = DateFormatter(); f.dateFormat = "HH:mm:ss"; return f.string(from: d) }
}

/// Uses the real adapter when the user has approved Screen Time and picked apps; otherwise simulates.
/// The UI asks `isReal` so it never claims apps are paused when they are not.
final class AdaptiveRestrictionAdapter: RestrictionAdapter, @unchecked Sendable {
    private let real = ScreenTimeRestrictionAdapter()
    private let simulated = SimulatedRestrictionAdapter()

    var isReal: Bool { real.isReal }
    var isAvailable: Bool { true }

    func apply(leaseId: UUID, apps: Set<ProtectedApp>, expiresAt: Date) async {
        if real.isReal { await real.apply(leaseId: leaseId, apps: apps, expiresAt: expiresAt) }
        else { await simulated.apply(leaseId: leaseId, apps: apps, expiresAt: expiresAt) }
    }

    /// Release always goes to both: ending a restriction must never depend on which adapter applied it.
    func release(leaseId: UUID) async {
        await real.release(leaseId: leaseId)
        await simulated.release(leaseId: leaseId)
    }

    /// Called when the app runs and the engine has no active lease. The engine is the source of truth, so any other
    /// shield is cleared (fail open), except a shield deliberately started from the test screen that has not expired yet.
    func clearLeftovers() {
        if let info = ShieldLeaseFile.read(), info.isTest == true, info.expiresAt > Date() {
            SpikeLog.write("app", "leftover check: test shield still running until \(ScreenTimeRestrictionAdapter.clock(info.expiresAt)); left alone")
            return
        }
        SpikeLog.write("app", "leftover check: no active lease in the engine; clearing any shield and monitoring")
        real.clearEverything()
    }
}
