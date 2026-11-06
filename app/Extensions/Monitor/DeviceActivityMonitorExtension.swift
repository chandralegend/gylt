import DeviceActivity
import ManagedSettings

/// Runs even when the GYLT app is closed. Its only job: end the pause at the agreed time.
final class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    private let store = ManagedSettingsStore(named: .init(ShieldStoreName.name))

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        DebugLog.write("monitor", "intervalDidStart \(activity.rawValue)")
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        store.clearAllSettings()
        ShieldLeaseFile.clear()
        DebugLog.write("monitor", "intervalDidEnd \(activity.rawValue) -> shield cleared")
    }
}
