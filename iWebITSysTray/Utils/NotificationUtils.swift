//
//  NotificationUtils.swift
//  MODA
//
//  Created by Admin on 10/04/2023.
//

import SwiftUI
import UserNotifications

func requestAuthorization(completionHandler: @escaping (_ granted: Bool, _ error: Error?) -> ()) {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
        completionHandler(success, error)
    }
}

func notify(title: String, subtitle: String) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.subtitle = subtitle
    content.sound = UNNotificationSound.default
    
    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
    
    UNUserNotificationCenter.current().add(request)
}
