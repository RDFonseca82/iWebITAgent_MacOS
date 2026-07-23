import UIKit

extension MobileAppDelegate {
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any]
    ) async -> UIBackgroundFetchResult {
        let success = await MobileSyncTrigger.shared.performBackgroundSync()
        return success ? .newData : .failed
    }
}
