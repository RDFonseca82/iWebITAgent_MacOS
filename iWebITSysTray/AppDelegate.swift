import SwiftUI
import UserNotifications


class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    var menuBarButton: MenuBarButton?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        Constants.shared.LOG_FILE = Constants.shared.LOG_FILE.appendingPathComponent("log_systray.log")
        Constants.shared.OLD_LOG_FILE = Constants.shared.OLD_LOG_FILE.appendingPathComponent("old_log_systray.log")
        log(Constants.AGENT_VERSION)
        
        menuBarButton = MenuBarButton()
        
        UNUserNotificationCenter.current().delegate = self
        
        requestAuthorization { granted, _ in
        }
    }
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.list, .sound, .banner])
    }
}
