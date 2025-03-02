import Foundation
import SwiftData
import SwiftUI

/// Manages the persistence of timer state between app launches
@Observable final class TimerStateManager {
  // MARK: - Singleton
  static let shared = TimerStateManager()

  // MARK: - UserDefaults Keys
  private enum Keys {
    static let activeSubtaskID = "TimerStateManager.activeSubtaskID"
    static let timeRemaining = "TimerStateManager.timeRemaining"
    static let pomodoroState = "TimerStateManager.pomodoroState"
    static let completedPomodoros = "TimerStateManager.completedPomodoros"
    static let isRunning = "TimerStateManager.isRunning"
    static let lastPauseDate = "TimerStateManager.lastPauseDate"
  }

  // MARK: - Private Properties
  private var modelContext: ModelContext?

  // MARK: - Initialization
  private init() {}

  // MARK: - Public Methods

  /// Configure the TimerStateManager with a ModelContext
  @MainActor
  func configure(with modelContext: ModelContext) {
    self.modelContext = modelContext
  }

  /// Save the current timer state to persistent storage
  func saveTimerState(
    activeSubtaskID: UUID?,
    timeRemaining: TimeInterval,
    pomodoroState: PomodoroState,
    completedPomodoros: Int,
    isRunning: Bool
  ) {
    // Save activeSubtaskID (can be nil)
    if let activeSubtaskID = activeSubtaskID {
      UserDefaults.standard.set(activeSubtaskID.uuidString, forKey: Keys.activeSubtaskID)
    } else {
      UserDefaults.standard.removeObject(forKey: Keys.activeSubtaskID)
    }

    // Save timer state
    UserDefaults.standard.set(timeRemaining, forKey: Keys.timeRemaining)
    UserDefaults.standard.set(pomodoroState.rawValue, forKey: Keys.pomodoroState)
    UserDefaults.standard.set(completedPomodoros, forKey: Keys.completedPomodoros)

    // Save running state and record timestamp if paused
    UserDefaults.standard.set(isRunning, forKey: Keys.isRunning)
    if !isRunning {
      UserDefaults.standard.set(Date(), forKey: Keys.lastPauseDate)
    } else {
      UserDefaults.standard.removeObject(forKey: Keys.lastPauseDate)
    }

    // Make sure changes are synchronized
    UserDefaults.standard.synchronize()
  }

  /// Load the timer state from persistent storage
  @MainActor
  func loadTimerState() -> (UUID?, TimeInterval, PomodoroState, Int, Bool) {
    // Load active subtask ID (if any)
    let activeSubtaskIDString = UserDefaults.standard.string(forKey: Keys.activeSubtaskID)
    let activeSubtaskID =
      activeSubtaskIDString != nil ? UUID(uuidString: activeSubtaskIDString!) : nil

    // Validate that the subtask still exists in the database
    let validatedSubtaskID = validateSubtaskID(activeSubtaskID)

    // Load timer state with fallbacks to defaults
    let timeRemaining = UserDefaults.standard.double(forKey: Keys.timeRemaining)
    let stateRawValue =
      UserDefaults.standard.string(forKey: Keys.pomodoroState) ?? PomodoroState.work.rawValue
    let state = PomodoroState(rawValue: stateRawValue) ?? .work
    let completedPomodoros = UserDefaults.standard.integer(forKey: Keys.completedPomodoros)

    // For the running state, we need to consider if the app was closed while running
    var isRunning = UserDefaults.standard.bool(forKey: Keys.isRunning)

    // If it was running but the app was closed for a while, adjust the time remaining
    if isRunning,
      let lastPauseDate = UserDefaults.standard.object(forKey: Keys.lastPauseDate) as? Date
    {
      let elapsedTimeSincePause = Date().timeIntervalSince(lastPauseDate)

      // If we've been closed for less than the timer duration, adjust the time
      // Otherwise, we'll use the default values
      if elapsedTimeSincePause < state.duration {
        // We don't auto-resume when the app relaunches
        isRunning = false
      }
    }

    return (validatedSubtaskID, timeRemaining, state, completedPomodoros, isRunning)
  }

  /// Clear all saved timer state
  func clearTimerState() {
    UserDefaults.standard.removeObject(forKey: Keys.activeSubtaskID)
    UserDefaults.standard.removeObject(forKey: Keys.timeRemaining)
    UserDefaults.standard.removeObject(forKey: Keys.pomodoroState)
    UserDefaults.standard.removeObject(forKey: Keys.completedPomodoros)
    UserDefaults.standard.removeObject(forKey: Keys.isRunning)
    UserDefaults.standard.removeObject(forKey: Keys.lastPauseDate)
    UserDefaults.standard.synchronize()
  }

  // MARK: - Private Methods

  /// Validates that the subtask ID still exists in the database
  @MainActor
  private func validateSubtaskID(_ subtaskID: UUID?) -> UUID? {
    guard let subtaskID = subtaskID, let context = modelContext else {
      return nil
    }

    do {
      let descriptor = FetchDescriptor<PolmodorSubTask>(
        predicate: #Predicate { subtask in
          subtask.id == subtaskID
        }
      )

      let results = try context.fetch(descriptor)
      return results.first?.id
    } catch {
      print("Error validating subtask ID: \(error)")
      return nil
    }
  }
}
