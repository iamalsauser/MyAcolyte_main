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
    
    func requestPermission(completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    DispatchQueue.main.async {
                        completion(granted)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion(settings.authorizationStatus == .authorized)
                }
            }
        }
    }
    
    func scheduleStudyReminder(title: String, message: String, date: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "study"
        
        // Extract time components
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        
        // Create trigger for specific time
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: "studyReminder-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        // Add to notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule study reminder: \(error.localizedDescription)")
            } else {
                print("✅ Study reminder scheduled for \(date)")
            }
        }
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

// Function to request notification permission - use at app startup
//func requestNotificationPermission() {
//    let center = UNUserNotificationCenter.current()
//    center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
//        if let error = error {
//            print("❌ Notification permission error: \(error.localizedDescription)")
//        } else {
//            print("✅ Notification permission granted: \(granted)")
//        }
//    }
//}
