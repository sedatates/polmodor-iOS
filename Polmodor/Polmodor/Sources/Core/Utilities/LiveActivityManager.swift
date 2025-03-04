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
    isBreak: Bool,
    breakType: String,
    startedAt: Date? = Date(),
    pausedAt: Date? = nil,
    duration: Int,
    parentTaskName: String? = nil,
    completedPomodoros: Int = 0,
    totalPomodoros: Int = 0,
    isLocked: Bool = false
  ) {
    // Only start if the device supports Live Activities
    guard isLiveActivitySupported else { return }

    // If we already have an activity, end it
    if activity != nil {
      do {
        endLiveActivity()
      } catch {
        print("Failed to end previous Live Activity: \(error.localizedDescription)")
        // Önceki activity sonlandırılamazsa yeni bir tane başlatmayı deneyelim
      }
    }

    // Create the initial content state
    let initialContentState = PolmodorLiveActivityAttributes.ContentState(
      taskTitle: taskTitle,
      remainingTime: remainingTime,
      isBreak: isBreak,
      breakType: breakType,
      startedAt: startedAt,
      pausedAt: pausedAt,
      duration: duration,
      parentTaskName: parentTaskName,
      completedPomodoros: completedPomodoros,
      totalPomodoros: totalPomodoros,
      isLocked: isLocked
    )

    // Create the activity attributes
    let activityAttributes = PolmodorLiveActivityAttributes(
      name: "Polmodor Timer"
    )

    do {
      // Start the Live Activity
      activity = try Activity.request(
        attributes: activityAttributes,
        content: .init(state: initialContentState, staleDate: nil),
        pushType: nil
      )
      print("Started Live Activity: \(activity?.id ?? "unknown")")
    } catch {
      print("Error starting Live Activity: \(error.localizedDescription)")
      // Başarısız olursa activity değişkenini nil yapalım ki tekrar deneyebilelim
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
    parentTaskName: String? = nil,
    completedPomodoros: Int? = nil,
    totalPomodoros: Int? = nil,
    isLocked: Bool? = nil
  ) {
    guard let currentActivity = activity else { return }

    // Get the current state
    let currentState = currentActivity.content.state

    // Create updated state with new values or current values if not provided
    let updatedState = PolmodorLiveActivityAttributes.ContentState(
      taskTitle: taskTitle ?? currentState.taskTitle,
      remainingTime: remainingTime ?? currentState.remainingTime,
      isBreak: isBreak ?? currentState.isBreak,
      breakType: breakType ?? currentState.breakType,
      startedAt: startedAt ?? currentState.startedAt,
      pausedAt: pausedAt,  // We specifically want to handle nil case for pausedAt
      duration: duration ?? currentState.duration,
      parentTaskName: parentTaskName ?? currentState.parentTaskName,
      completedPomodoros: completedPomodoros ?? currentState.completedPomodoros,
      totalPomodoros: totalPomodoros ?? currentState.totalPomodoros,
      isLocked: isLocked ?? currentState.isLocked
    )

    // Update activity with the new state
    Task {
      await currentActivity.update(
        ActivityContent(state: updatedState, staleDate: nil)
      )
    }
  }

  /// End the current Live Activity
  @MainActor
  func endLiveActivity() {
    guard let currentActivity = activity else { return }

    Task {
      await currentActivity.end(
        ActivityContent(
          state: currentActivity.content.state,
          staleDate: nil
        ),
        dismissalPolicy: .immediate
      )
      activity = nil
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
