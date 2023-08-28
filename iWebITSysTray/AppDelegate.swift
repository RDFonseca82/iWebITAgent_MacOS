import SwiftUI
import UserNotifications


class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    var menuBarButton: MenuBarButton?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBarButton = MenuBarButton()
        
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                
                print("Permission granted: \(granted)")
                guard granted else { return }
                
                let notificationCenter = UNUserNotificationCenter.current()
                notificationCenter.getNotificationSettings
                { (settings) in
                    if settings.authorizationStatus == .authorized {
                        print("Notifications Still Allowed")
                        
                        let content = UNMutableNotificationContent();
                        content.title = "summary" ;
                        content.body = "title" ;
                        content.sound =  UNNotificationSound.default
                        
                        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false);
                        
                        let uuidString = UUID().uuidString ;
                        let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: nil);
                        
                        // Schedule the request with the system.
                        notificationCenter.add(request, withCompletionHandler:
                                                { (error) in
                            if error != nil
                            {
                                print("ERROR: \(String(describing: error))")
                            }
                            print("HEY")
                        })
                    }
                }
            }
    }
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.list, .sound, .banner])
    }
}
