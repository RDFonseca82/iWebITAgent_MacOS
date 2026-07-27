import UIKit

extension MobileAppDelegate {
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any]
    ) async -> UIBackgroundFetchResult {
        await AgentLogger.shared.log(
            category: "notifications",
            action: "background-received",
            message: "Notificação silenciosa recebida."
        )
        let success = await MobileSyncTrigger.shared.performBackgroundSync()
        await AgentLogger.shared.log(
            success ? .info : .warning,
            category: "notifications",
            action: "background-result",
            message: success
                ? "Sincronização da notificação concluída."
                : "Sincronização da notificação falhou."
        )
        return success ? .newData : .failed
    }
}
