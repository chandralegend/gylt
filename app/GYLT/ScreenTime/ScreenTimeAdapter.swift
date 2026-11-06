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

    /// Screen Time approved and at least one app chosen.
    var isReal: Bool { ScreenTimeAccess.isApproved && !SelectionStore.isEmpty(SelectionStore.load()) }
    var isAvailable: Bool { isReal }

    static func activityName(for leaseId: UUID) -> DeviceActivityName { DeviceActivityName("gylt.lease.\(leaseId.uuidString)") }

    func apply(leaseId: UUID, apps: Set<ProtectedApp>, expiresAt: Date) async {
        let selection = SelectionStore.load()
        guard ScreenTimeAccess.isApproved, !SelectionStore.isEmpty(selection) else {
            DebugLog.write("app", "apply skipped: approved=\(ScreenTimeAccess.isApproved) selectionEmpty=\(SelectionStore.isEmpty(selection))")
            return
        }
        // 1. Shield now.
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
        ShieldLeaseFile.write(ShieldLeaseInfo(leaseId: leaseId, expiresAt: expiresAt, promiseTitle: nil))

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
            DebugLog.write("app", "shield applied; monitoring \(name.rawValue) until \(Self.clock(expiresAt))")
        } catch {
            // If the OS can't promise the end, don't leave an open-ended pause behind.
            store.clearAllSettings()
            ShieldLeaseFile.clear()
            DebugLog.write("app", "startMonitoring FAILED (\(error)); shield removed so nothing can outlive its deadline")
        }
    }

    /// Adds the promise's name to the shield's note, once the shield is up.
    func name(leaseId: UUID, promiseTitle: String) {
        guard var info = ShieldLeaseFile.read(), info.leaseId == leaseId else { return }
        info.promiseTitle = promiseTitle
        ShieldLeaseFile.write(info)
    }

    func release(leaseId: UUID) async {
        center.stopMonitoring([Self.activityName(for: leaseId)])
        store.clearAllSettings()
        ShieldLeaseFile.clear()
        DebugLog.write("app", "released lease \(leaseId.uuidString.prefix(8)); shield cleared")
    }

    /// Belt and braces: whenever the app runs and no pause is active, make sure no shield is left behind.
    func clearLeftovers() {
        DebugLog.write("app", "no active pause in the engine; clearing any shield and monitoring")
        clearEverything()
    }

    func clearEverything() {
        center.stopMonitoring()
        store.clearAllSettings()
        ShieldLeaseFile.clear()
    }

    static func clock(_ d: Date) -> String { let f = DateFormatter(); f.dateFormat = "HH:mm:ss"; return f.string(from: d) }
}
