import BackgroundTasks
import UIKit
import UserNotifications

final class MobileAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        Task {
            await AgentLogger.shared.log(
                category: "lifecycle",
                action: "launch",
                message: "Aplicação iniciada."
            )
        }
        UNUserNotificationCenter.current().delegate = self
        BackgroundRefreshCoordinator.shared.register()
        BackgroundRefreshCoordinator.shared.scheduleRefresh()

        // A device token is required for silent pushes even if the user declines
        // visible alerts. Registering it independently keeps on-demand sync
        // available without changing the user's notification preference.
        application.registerForRemoteNotifications()

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) {
            granted, error in
            Task {
                await AgentLogger.shared.log(
                    error == nil ? .info : .warning,
                    category: "notifications",
                    action: "authorization",
                    message: granted
                        ? "Notificações autorizadas."
                        : "Notificações não autorizadas."
                )
            }
        }
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        Task {
            await AgentLogger.shared.log(
                category: "lifecycle",
                action: "active",
                message: "Aplicação ativa."
            )
        }
        BackgroundRefreshCoordinator.shared.scheduleRefresh()
        NotificationCenter.default.post(name: .mobileAppDidBecomeActive, object: nil)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        Task {
            await AgentLogger.shared.log(
                category: "lifecycle",
                action: "background",
                message: "Aplicação em segundo plano."
            )
        }
        BackgroundRefreshCoordinator.shared.scheduleRefresh()
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        NotificationCenter.default.post(name: .didReceiveAPNSToken, object: deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        NotificationCenter.default.post(name: .didFailAPNSRegistration, object: error)
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        await AgentLogger.shared.log(
            category: "notifications",
            action: "foreground-received",
            message: "Notificação recebida em primeiro plano."
        )
        return [.banner, .badge, .sound]
    }
}

extension Notification.Name {
    static let didReceiveAPNSToken = Notification.Name("app.iwebit.didReceiveAPNSToken")
    static let didFailAPNSRegistration = Notification.Name("app.iwebit.didFailAPNSRegistration")
    static let mobileAppDidBecomeActive = Notification.Name("app.iwebit.mobileDidBecomeActive")
}
