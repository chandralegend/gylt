import Foundation
import ManagedSettings
import ManagedSettingsUI

/// Handles the two buttons on the shield. Neither needs the network, an AI or the main app.
final class ShieldActionExtension: ShieldActionDelegate {
    private let store = ManagedSettingsStore(named: .init(ShieldStoreName.name))

    private func respond(to action: ShieldAction, _ completion: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            DebugLog.write("shield", "primary pressed: close")
            completion(.close)
        case .secondaryButtonPressed:
            // The user ended it. Release immediately and leave a note for the app.
            let id = ShieldLeaseFile.read()?.leaseId
            store.clearAllSettings()
            ShieldLeaseFile.clear()
            OverrideInbox.append(OverrideRequest(leaseId: id, at: Date()))
            DebugLog.write("shield", "secondary pressed: override, shield cleared")
            completion(.close)
        @unknown default:
            completion(.close)
        }
    }

    override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        respond(to: action, completionHandler)
    }
    override func handle(action: ShieldAction, for webDomain: WebDomainToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        respond(to: action, completionHandler)
    }
    override func handle(action: ShieldAction, for category: ActivityCategoryToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        respond(to: action, completionHandler)
    }
}
