import AppKit
import UserNotifications

final class MacStoreAppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
            DispatchQueue.main.async {
                NSApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    func application(
        _ application: NSApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        NotificationCenter.default.post(name: .macStoreDidReceiveAPNSToken, object: deviceToken)
    }

    func application(
        _ application: NSApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        NotificationCenter.default.post(name: .macStoreDidFailAPNSRegistration, object: error)
    }

    func application(
        _ application: NSApplication,
        didReceiveRemoteNotification userInfo: [String: Any]
    ) {
        NotificationCenter.default.post(name: .macStoreDidRequestSync, object: nil)
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .badge, .sound]
    }
}

extension Notification.Name {
    static let macStoreDidReceiveAPNSToken =
        Notification.Name("app.iwebit.mac-store.didReceiveAPNSToken")
    static let macStoreDidFailAPNSRegistration =
        Notification.Name("app.iwebit.mac-store.didFailAPNSRegistration")
    static let macStoreDidRequestSync =
        Notification.Name("app.iwebit.mac-store.didRequestSync")
}
