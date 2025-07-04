import ActivityKit
import Foundation
import SwiftUI

/// Manages Live Activities for the Pomodoro timer
@Observable final class LiveActivityManager {
  // MARK: - Singleton
  static let shared = LiveActivityManager()

  // MARK: - Properties
  private var activity: Activity<PolmodorLiveActivityAttributes>?

  // MARK: - Initialization
  private init() {}

  // MARK: - Public Methods

  /// Check if the device supports Live Activities
  var isLiveActivitySupported: Bool {
    if #available(iOS 16.1, *) {
      return ActivityAuthorizationInfo().areActivitiesEnabled
    } else {
      return false
    }
  }

  /// Start a new Live Activity for the current timer
  @MainActor
  func startLiveActivity(
    taskTitle: String,
    remainingTime: Int,
    sessionType: PolmodorLiveActivityAttributes.ContentState.SessionType,
    startedAt: Date? = nil,
    pausedAt: Date? = nil,
    duration: Int,
    isLocked: Bool = false
  ) {
    // Only start if the device supports Live Activities
    guard isLiveActivitySupported else {
      print("📱 Live Activities not supported on this device")
      return
    }

    print("🟢 Starting or updating Live Activity for: \(taskTitle)")

    // Always end existing activities first to avoid conflicts
    if let currentActivity = activity {
      print("🟢 Ending existing Live Activity before creating new one")
      Task {
        await currentActivity.end(nil, dismissalPolicy: .immediate)
        try? await Task.sleep(for: .seconds(0.2))

        // Create new activity after cleanup
        await startNewLiveActivity(
          taskTitle: taskTitle,
          remainingTime: remainingTime,
          sessionType: sessionType,
          startedAt: startedAt,
          pausedAt: pausedAt,
          duration: duration,
          isLocked: isLocked
        )
      }
    } else {
      // No existing activity, create a new one
      print("🟢 No existing activity, creating new Live Activity")
      Task {
        await startNewLiveActivity(
          taskTitle: taskTitle,
          remainingTime: remainingTime,
          sessionType: sessionType,
          startedAt: startedAt,
          pausedAt: pausedAt,
          duration: duration,
          isLocked: isLocked
        )
      }
    }
  }

  /// Yeni Live Activity başlatma işleminin asıl implementasyonu
  @MainActor
  private func startNewLiveActivity(
    taskTitle: String,
    remainingTime: Int,
    sessionType: PolmodorLiveActivityAttributes.ContentState.SessionType,
    startedAt: Date?,
    pausedAt: Date?,
    duration: Int,
    isLocked: Bool
  ) async {
    // Create the initial content state with current time sync
    let initialContentState = PolmodorLiveActivityAttributes.ContentState(
      taskTitle: taskTitle,
      remainingTime: remainingTime,
      sessionType: sessionType,
      startedAt: startedAt,  // Use the exact start time from timer
      pausedAt: pausedAt,
      duration: duration,
      isLocked: isLocked
    )

    // Create the activity attributes
    let activityAttributes = PolmodorLiveActivityAttributes(
      name: "Polmodor Timer"
    )

    do {
      print(
        "🟢 Creating Live Activity content with state: \(initialContentState.sessionType.rawValue)")

      // 60 dakikalık staleDate ile aktiviteyi başlat (varsayılan 1 saat yerine 2 saat)
      let staleDate =
        Calendar.current.date(byAdding: .hour, value: 2, to: Date())
        ?? Date().addingTimeInterval(7200)

      // Start the Live Activity
      activity = try Activity.request(
        attributes: activityAttributes,
        content: .init(
          state: initialContentState,
          staleDate: staleDate),
        pushType: nil
      )

      print("🟢 Successfully started Live Activity: \(activity?.id ?? "unknown")")

      // For troubleshooting, log active activities
      if #available(iOS 16.1, *) {
        for activity in Activity<PolmodorLiveActivityAttributes>.activities {
          print("🟢 Currently active activity: \(activity.id)")
        }
      }
    } catch {
      print("❌ Error starting Live Activity: \(error.localizedDescription)")
      activity = nil
    }
  }

  /// Update the current Live Activity with new state
  @MainActor
  func updateLiveActivity(
    taskTitle: String? = nil,
    remainingTime: Int? = nil,
    isBreak: Bool? = nil,
    breakType: String? = nil,
    startedAt: Date? = nil,
    pausedAt: Date? = nil,
    duration: Int? = nil,
    isLocked: Bool? = nil,
    progress: Double? = nil
  ) {
    guard let currentActivity = activity else { return }

    // Get the current state
    let currentState = currentActivity.content.state

    // Handle session type update if needed
    var sessionType = currentState.sessionType
    if let isBreak = isBreak, let breakType = breakType {
      if isBreak {
        sessionType = breakType == "long" ? .longBreak : .shortBreak
      } else {
        sessionType = .work
      }
    }

    // Create updated state with new values or current values if not provided
    let updatedState = PolmodorLiveActivityAttributes.ContentState(
      taskTitle: taskTitle ?? currentState.taskTitle,
      remainingTime: remainingTime ?? currentState.remainingTime,
      sessionType: sessionType,
      startedAt: startedAt ?? currentState.startedAt,
      pausedAt: pausedAt,  // We specifically want to handle nil case for pausedAt
      duration: duration ?? currentState.duration,
      isLocked: isLocked ?? currentState.isLocked,
      progress: progress  // Pass through the explicit progress value if provided
    )

    // Update activity with the new state
    Task {
      await currentActivity.update(
        ActivityContent(state: updatedState, staleDate: nil)
      )
    }
  }

  /// Update only the timer state (convenience method for common updates)
  @MainActor
  func updateLiveActivity(
    remainingTime: Int? = nil,
    pausedAt: Date? = nil
  ) {
    updateLiveActivity(
      remainingTime: remainingTime,
      pausedAt: pausedAt,
      progress: nil  // Don't provide explicit progress, let it be calculated
    )
  }

  /// End the current Live Activity
  @MainActor
  func endLiveActivity() {
    print("🔴 Attempting to end all Live Activities...")

    // Önce mevcut referanstaki aktiviteyi sonlandır
    if let currentActivity = activity {
      print("🔴 Ending specific Live Activity: \(currentActivity.id)")

      Task {
        // Immediate dismissal policy kullanarak Live Activity'yi ekrandan kaldır
        await currentActivity.end(
          ActivityContent(
            state: currentActivity.content.state,
            staleDate: Date()  // Hemen geçersiz kılmak için şimdiki zamanı kullan
          ),
          dismissalPolicy: .immediate
        )

        // Hata ayıklama mesajı
        print("🔴 Ended specific Live Activity with ID: \(currentActivity.id)")

        // Aktiviteyi nil yap ki yeni aktiviteler temiz başlayabilsin
        activity = nil
      }
    } else {
      print("🔴 No current activity reference found, will try to clean up any lingering activities")
    }

    // iOS 16.1+ cihazlar için tüm aktiviteleri temizle
    cleanupAllActivities()
  }

  /// Tüm mevcut Live Activity'leri temizler
  @MainActor
  private func cleanupAllActivities() {
    Task {
      if #available(iOS 16.1, *) {
        print("🔴 Cleaning up ALL Live Activities")

        // 1. İlk temizleme denemesi
        for activity in Activity<PolmodorLiveActivityAttributes>.activities {
          print("🔴 Found lingering activity: \(activity.id)")
          await activity.end(nil, dismissalPolicy: .immediate)
        }

        // 2. Kısa bir bekleme ve ikinci temizleme denemesi
        try? await Task.sleep(for: .seconds(0.3))
        for activity in Activity<PolmodorLiveActivityAttributes>.activities {
          print("🔴 Second attempt - terminating activity: \(activity.id)")
          await activity.end(nil, dismissalPolicy: .immediate)
        }

        // 3. Son bir temizleme denemesi (özellikle inatçı aktiviteler için)
        try? await Task.sleep(for: .seconds(0.3))
        for activity in Activity<PolmodorLiveActivityAttributes>.activities {
          print("🔴 Final cleanup - force terminating activity: \(activity.id)")

          let forcedContent = ActivityContent(
            state: activity.content.state,
            staleDate: Date(timeIntervalSinceNow: -3600)  // 1 saat öncesi tarih ile geçersiz kıl
          )

          await activity.end(forcedContent, dismissalPolicy: .immediate)
        }

        print("🔴 Live Activity cleanup completed")
      }
    }
  }

  /// Toggle the pause state of the Live Activity
  @MainActor
  func togglePauseLiveActivity(isPaused: Bool, remainingTime: Int) {
    guard let currentActivity = activity else { return }

    let pausedAt = isPaused ? Date() : nil

    updateLiveActivity(
      remainingTime: remainingTime,
      pausedAt: pausedAt
    )
  }

  /// Toggle the lock state of the Live Activity
  @MainActor
  func toggleLockLiveActivity(isLocked: Bool) {
    guard let currentActivity = activity else { return }

    updateLiveActivity(isLocked: isLocked)
  }
}
