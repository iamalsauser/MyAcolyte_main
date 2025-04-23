//
//  notification.swift
//  MyAcolyte
//
//  Created by admin17 on 10/03/25.
//

import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    func sendNotification(title: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to send notification: \(error.localizedDescription)")
            } else {
                print("✅ Notification sent: \(title) - \(message)")
            }
        }
    }
}
