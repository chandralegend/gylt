import UIKit
import UserNotifications
import GYLTCore

/// One reminder at the agreed time and at most one gentle follow-up 10 minutes later. Never a loop.
final class LocalNotifier: Notifier, @unchecked Sendable {
    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func schedule(occurrenceId: UUID, at date: Date, title: String, body: String) async {
        await cancel(occurrenceId: occurrenceId)
        let reminders: [(String, TimeInterval, String)] = [("", 0, body), ("-nudge", 600, "Still time. The minimum counts.")]
        for (suffix, offset, text) in reminders {
            let fire = date.addingTimeInterval(offset)
            guard fire > Date().addingTimeInterval(5) else { continue }
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = text
            content.sound = .default
            content.interruptionLevel = .timeSensitive
            content.userInfo = ["occurrenceId": occurrenceId.uuidString]
            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: fire)
            let request = UNNotificationRequest(identifier: occurrenceId.uuidString + suffix, content: content,
                                                trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false))
            try? await center.add(request)
        }
    }

    func cancel(occurrenceId: UUID) async {
        let ids = [occurrenceId.uuidString, occurrenceId.uuidString + "-nudge"]
        center.removePendingNotificationRequests(withIdentifiers: ids)
        center.removeDeliveredNotifications(withIdentifiers: ids)
    }

    func cancelAll() async { center.removeAllPendingNotificationRequests() }

    static func status() async -> UNAuthorizationStatus { await UNUserNotificationCenter.current().notificationSettings().authorizationStatus }
}

/// Carries a notification tap to the model, even if the app was not running.
@MainActor
final class NotificationRouter {
    static let shared = NotificationRouter()
    var onOpen: ((UUID) -> Void)? { didSet { if let id = pending, let onOpen { pending = nil; onOpen(id) } } }
    private var pending: UUID?
    func open(_ id: UUID) { if let onOpen { onOpen(id) } else { pending = id } }
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        guard let s = response.notification.request.content.userInfo["occurrenceId"] as? String, let id = UUID(uuidString: s) else { return }
        await MainActor.run { NotificationRouter.shared.open(id) }
    }
}
