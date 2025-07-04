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
    static let originalDuration = "TimerStateManager.originalDuration"
    static let pomodoroState = "TimerStateManager.pomodoroState"
    static let completedPomodoros = "TimerStateManager.completedPomodoros"
    static let isRunning = "TimerStateManager.isRunning"
    static let startedAt = "TimerStateManager.startedAt"
    static let pausedAt = "TimerStateManager.pausedAt"
    static let timeElapsedBeforePause = "TimerStateManager.timeElapsedBeforePause"
    static let activeTaskTitle = "TimerStateManager.activeTaskTitle"
    static let sessionStartedAt = "TimerStateManager.sessionStartedAt"
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
    originalDuration: TimeInterval,
    pomodoroState: PomodoroState,
    completedPomodoros: Int,
    isRunning: Bool,
    startedAt: Date?,
    pausedAt: Date?,
    timeElapsedBeforePause: TimeInterval,
    activeTaskTitle: String? = nil
  ) {
    // Save activeSubtaskID (can be nil)
    if let activeSubtaskID = activeSubtaskID {
      UserDefaults.standard.set(activeSubtaskID.uuidString, forKey: Keys.activeSubtaskID)
    } else {
      UserDefaults.standard.removeObject(forKey: Keys.activeSubtaskID)
    }

    // Save timer state
    UserDefaults.standard.set(originalDuration, forKey: Keys.originalDuration)
    UserDefaults.standard.set(pomodoroState.rawValue, forKey: Keys.pomodoroState)
    UserDefaults.standard.set(completedPomodoros, forKey: Keys.completedPomodoros)
    UserDefaults.standard.set(isRunning, forKey: Keys.isRunning)
    UserDefaults.standard.set(timeElapsedBeforePause, forKey: Keys.timeElapsedBeforePause)

    // Save timestamps
    if let startedAt = startedAt {
      UserDefaults.standard.set(startedAt, forKey: Keys.startedAt)
    } else {
      UserDefaults.standard.removeObject(forKey: Keys.startedAt)
    }

    if let pausedAt = pausedAt {
      UserDefaults.standard.set(pausedAt, forKey: Keys.pausedAt)
    } else {
      UserDefaults.standard.removeObject(forKey: Keys.pausedAt)
    }

    // Save task title for widgets
    if let activeTaskTitle = activeTaskTitle {
      UserDefaults.standard.set(activeTaskTitle, forKey: Keys.activeTaskTitle)
    } else {
      UserDefaults.standard.removeObject(forKey: Keys.activeTaskTitle)
    }

    // Save session start time
    if isRunning && startedAt != nil {
      UserDefaults.standard.set(Date(), forKey: Keys.sessionStartedAt)
    }

    // Make sure changes are synchronized
    UserDefaults.standard.synchronize()
  }

  /// Load the timer state from persistent storage with elapsed time calculation
  @MainActor
  func loadTimerState() -> (UUID?, TimeInterval, PomodoroState, Int, Bool, Date?, Date?, TimeInterval) {
    // Load active subtask ID (if any)
    let activeSubtaskIDString = UserDefaults.standard.string(forKey: Keys.activeSubtaskID)
    let activeSubtaskID =
      activeSubtaskIDString != nil ? UUID(uuidString: activeSubtaskIDString!) : nil

    // Validate that the subtask still exists in the database
    let validatedSubtaskID = validateSubtaskID(activeSubtaskID)

    // Load timer state with fallbacks to defaults
    let originalDuration = UserDefaults.standard.double(forKey: Keys.originalDuration)
    let stateRawValue =
      UserDefaults.standard.string(forKey: Keys.pomodoroState) ?? PomodoroState.work.rawValue
    let state = PomodoroState(rawValue: stateRawValue) ?? .work
    let completedPomodoros = UserDefaults.standard.integer(forKey: Keys.completedPomodoros)
    var isRunning = UserDefaults.standard.bool(forKey: Keys.isRunning)
    
    let startedAt = UserDefaults.standard.object(forKey: Keys.startedAt) as? Date
    let pausedAt = UserDefaults.standard.object(forKey: Keys.pausedAt) as? Date
    let timeElapsedBeforePause = UserDefaults.standard.double(forKey: Keys.timeElapsedBeforePause)
    
    // Calculate current remaining time based on state
    var currentTimeRemaining: TimeInterval = 0
    
    if let startedAt = startedAt {
      if let pausedAt = pausedAt {
        // Timer was paused - use elapsed time before pause
        currentTimeRemaining = max(0, originalDuration - timeElapsedBeforePause)
        isRunning = false
        print("🟡 Timer was paused - remaining: \(Int(currentTimeRemaining))s")
      } else if isRunning {
        // Timer is running - calculate elapsed time from start
        let totalElapsed = Date().timeIntervalSince(startedAt)
        currentTimeRemaining = max(0, originalDuration - totalElapsed)
        
        if currentTimeRemaining <= 0 {
          isRunning = false
          print("🟢 Timer completed while app was closed - elapsed: \(Int(totalElapsed))s")
        } else {
          print("🟢 Timer running - elapsed: \(Int(totalElapsed))s, remaining: \(Int(currentTimeRemaining))s")
        }
      } else {
        // Timer was stopped
        currentTimeRemaining = originalDuration > 0 ? originalDuration : state.duration
      }
    } else {
      // No start time - use default duration
      currentTimeRemaining = originalDuration > 0 ? originalDuration : state.duration
    }

    return (validatedSubtaskID, currentTimeRemaining, state, completedPomodoros, isRunning, startedAt, pausedAt, timeElapsedBeforePause)
  }

  /// Clear all saved timer state
  func clearTimerState() {
    UserDefaults.standard.removeObject(forKey: Keys.activeSubtaskID)
    UserDefaults.standard.removeObject(forKey: Keys.originalDuration)
    UserDefaults.standard.removeObject(forKey: Keys.pomodoroState)
    UserDefaults.standard.removeObject(forKey: Keys.completedPomodoros)
    UserDefaults.standard.removeObject(forKey: Keys.isRunning)
    UserDefaults.standard.removeObject(forKey: Keys.startedAt)
    UserDefaults.standard.removeObject(forKey: Keys.pausedAt)
    UserDefaults.standard.removeObject(forKey: Keys.timeElapsedBeforePause)
    UserDefaults.standard.removeObject(forKey: Keys.activeTaskTitle)
    UserDefaults.standard.removeObject(forKey: Keys.sessionStartedAt)
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
