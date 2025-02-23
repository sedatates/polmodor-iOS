import Foundation
import UserNotifications

class NotificationManager {
  static let shared = NotificationManager()

  private init() {}

  func requestAuthorization() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
      granted, error in
      if granted {
        print("Notification permission granted")
      } else if let error = error {
        print("Error requesting notification permission: \(error.localizedDescription)")
      }
    }
  }

  func scheduleTimerCompletionNotification(title: String, message: String) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = message
    content.sound = .default

    let request = UNNotificationRequest(
      identifier: UUID().uuidString,
      content: content,
      trigger: nil
    )

    UNUserNotificationCenter.current().add(request) { error in
      if let error = error {
        print("Error scheduling notification: \(error.localizedDescription)")
      }
    }
  }

  private func getNotificationBody(for state: PomodoroState) -> String {
    switch state {
    case .work:
      return "Great job! Time for a break."
    case .shortBreak:
      return "Break's over! Time to focus."
    case .longBreak:
      return "Long break completed. Ready for the next session?"
    }
  }
}
