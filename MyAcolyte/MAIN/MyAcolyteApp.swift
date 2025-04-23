import SwiftUI
import UserNotifications

@main
struct MyAcolyteApp: App {
    var body: some Scene {
        WindowGroup {
            FileSystemView()
        }
    }
}

func requestNotificationPermission() {
    let center = UNUserNotificationCenter.current()
    center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
        if let error = error {
            print("❌ Notification permission error: \(error.localizedDescription)")
        } else {
            print("✅ Notification permission granted: \(granted)")
        }
    }
}
