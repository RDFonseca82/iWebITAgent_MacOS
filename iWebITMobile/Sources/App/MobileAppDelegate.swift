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
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
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
}
