import Combine
import Foundation
import SwiftData
import SwiftUI
import UserNotifications

#if os(iOS)
  import UIKit
  import ActivityKit
#endif

@MainActor
final class TimerViewModel: ObservableObject {
  // MARK: - Published Properties
  @Published private(set) var timeRemaining: TimeInterval
  @Published private(set) var isRunning = false
  @Published private(set) var progress: Double = 0
  @Published private(set) var state: PomodoroState = .work
  @Published private(set) var completedPomodoros: Int = 0
  @Published var activeSubtaskID: UUID? {
    didSet {
      updateActiveSubtaskTitle()
    }
  }
  @Published private(set) var activeSubtaskTitle: String?

  // MARK: - Private Properties
  private var timer: AnyCancellable?
  private var modelContext: ModelContext?
  private var settingsCancellable: AnyCancellable?
  
  // Timer state tracking
  private var originalDuration: TimeInterval = 0
  private var sessionStartedAt: Date?
  private var sessionPausedAt: Date?
  private var timeElapsedBeforePause: TimeInterval = 0

  // MARK: - Live Activity Support
  private var supportsLiveActivity: Bool {
    if #available(iOS 16.1, *) {
      return ActivityAuthorizationInfo().areActivitiesEnabled
    }
    return false
  }

  // MARK: - Computed Properties
  var timeString: String {
    let minutes = Int(timeRemaining) / 60
    let seconds = Int(timeRemaining) % 60
    return String(format: "%02d:%02d", minutes, seconds)
  }

  var currentStateTitle: String {
    state.title
  }

  var currentStateColor: Color {
    switch state {
    case .work:
      return .red
    case .shortBreak:
      return .green
    case .longBreak:
      return .blue
    }
  }

  // MARK: - Initialization
  init() {
    self.timeRemaining = PomodoroState.work.duration
    self.originalDuration = PomodoroState.work.duration
    setupNotificationObservers()
  }

  convenience init(modelContainer: ModelContainer) {
    self.init()
    self.configure(with: modelContainer.mainContext)

    Task {
      SettingsManager.shared.configure(with: modelContainer.mainContext)
    }
  }

  func configure(with modelContext: ModelContext) {
    self.modelContext = modelContext

    Task {
      TimerStateManager.shared.configure(with: modelContext)
      restoreTimerState()
    }

    observeSettingsChanges()
  }

  private func observeSettingsChanges() {
    settingsCancellable = NotificationCenter.default.publisher(for: NSNotification.Name("SettingsChanged"))
      .sink { [weak self] _ in
        Task { @MainActor in
          self?.handleSettingsChange()
        }
      }
  }

  private func handleSettingsChange() {
    let newDuration = state.duration
    if newDuration != originalDuration {
      resetTimer()
      originalDuration = newDuration
      timeRemaining = newDuration
      updateProgress()
      saveTimerState()
      startNewLiveActivity()
    }
  }

  // MARK: - Timer State Management

  /// Save current timer state to persistent storage
  func saveTimerState() {
    TimerStateManager.shared.saveTimerState(
      activeSubtaskID: activeSubtaskID,
      originalDuration: originalDuration,
      pomodoroState: state,
      completedPomodoros: completedPomodoros,
      isRunning: isRunning,
      startedAt: sessionStartedAt,
      pausedAt: sessionPausedAt,
      timeElapsedBeforePause: timeElapsedBeforePause,
      activeTaskTitle: activeSubtaskTitle
    )
  }

  /// Restore timer state from persistent storage
  private func restoreTimerState() {
    let (
      savedSubtaskID, savedTimeRemaining, savedState, savedCompletedPomodoros, savedIsRunning,
      savedStartedAt, savedPausedAt, savedTimeElapsedBeforePause
    ) = TimerStateManager.shared.loadTimerState()

    // Restore basic state
    self.state = savedState
    self.completedPomodoros = savedCompletedPomodoros
    self.activeSubtaskID = savedSubtaskID
    self.sessionStartedAt = savedStartedAt
    self.sessionPausedAt = savedPausedAt
    self.timeElapsedBeforePause = savedTimeElapsedBeforePause
    
    // Set original duration
    self.originalDuration = savedState.duration
    
    // Handle different timer states
    if savedIsRunning && savedTimeRemaining > 0 {
      // Timer was running and has time left
      self.timeRemaining = savedTimeRemaining
      self.isRunning = false // Will be started by UI
      print("🟢 Timer restored with \(Int(savedTimeRemaining))s remaining")
    } else if savedIsRunning && savedTimeRemaining <= 0 {
      // Timer completed while app was closed
      handleTimerCompletionFromBackground()
    } else {
      // Timer was paused or stopped
      self.timeRemaining = savedTimeRemaining > 0 ? savedTimeRemaining : savedState.duration
      self.isRunning = false
    }
    
    // Calculate progress
    updateProgress()
  }

  /// Handle timer completion when app was closed
  private func handleTimerCompletionFromBackground() {
    print("🟢 Handling timer completion from background")
    
    // Mark as completed
    if state == .work {
      completedPomodoros += 1
      
      if let subtaskID = activeSubtaskID {
        incrementSubtaskPomodoro(subtaskID: subtaskID)
      }
    }

    // Transition to next state
    transitionToNextState()
    
    // Reset timer for new state
    resetTimerForNewState()
    
    // Save the new state
    saveTimerState()
  }

  /// Update timer from LiveActivity when app comes to foreground
  func updateFromLiveActivity() {
    restoreTimerState()
    
    // Update Live Activity to sync with current app state
    if isRunning || timeRemaining > 0 {
      startNewLiveActivity()
    }
  }

  // MARK: - Timer Control Methods

  func toggleTimer() {
    if isRunning {
      pauseTimer()
    } else {
      startTimer()
    }
  }

  func startTimer() {
    guard !isRunning else { return }
    
    // Set up timer state
    if sessionStartedAt == nil {
      // Starting fresh
      sessionStartedAt = Date()
      timeElapsedBeforePause = 0
    } else if sessionPausedAt != nil {
      // Resuming from pause - calculate new start time
      let pauseDuration = Date().timeIntervalSince(sessionPausedAt!)
      sessionStartedAt = sessionStartedAt!.addingTimeInterval(pauseDuration)
    }
    
    sessionPausedAt = nil
    isRunning = true
    
    // Start the UI timer
    timer = Timer.publish(every: 1, on: .main, in: .common)
      .autoconnect()
      .sink { [weak self] _ in
        self?.updateTimer()
      }

    updateActiveTaskStatus(isRunning: true)
    startNewLiveActivity()
    saveTimerState()
    
    print("🟢 Timer started - duration: \(Int(originalDuration))s")
  }

  func pauseTimer() {
    guard isRunning else { return }
    
    isRunning = false
    timer?.cancel()
    
    // Calculate elapsed time before pause
    if let startedAt = sessionStartedAt {
      timeElapsedBeforePause = Date().timeIntervalSince(startedAt)
    }
    
    sessionPausedAt = Date()
    
    updateActiveTaskStatus(isRunning: false)
    updateLiveActivityPause()
    saveTimerState()
    
    print("🟡 Timer paused - elapsed: \(Int(timeElapsedBeforePause))s")
  }

  func resetTimer() {
    pauseTimer()
    
    // Reset all timer state
    timeRemaining = state.duration
    originalDuration = state.duration
    progress = 0
    sessionStartedAt = nil
    sessionPausedAt = nil
    timeElapsedBeforePause = 0
    
    saveTimerState()
    LiveActivityManager.shared.endLiveActivity()
    
    print("🔄 Timer reset")
  }

  func skipToNext() {
    let wasWorkSession = state == .work
    
    // Handle completion if it was a work session
    if wasWorkSession {
      completedPomodoros += 1
      
      if let subtaskID = activeSubtaskID {
        incrementSubtaskPomodoro(subtaskID: subtaskID)
      }
    }

    // Transition to next state
    transitionToNextState()
    
    // Reset timer for new state
    resetTimerForNewState()
    
    // Auto-start if it was running
    if isRunning {
      startTimer()
    }
    
    saveTimerState()
    startNewLiveActivity()
    
    print("⏭️ Skipped to next: \(state.rawValue)")
  }

  // MARK: - Private Timer Methods

  private func updateTimer() {
    guard let startedAt = sessionStartedAt else {
      handleTimerCompletion()
      return
    }
    
    let totalElapsed = Date().timeIntervalSince(startedAt)
    timeRemaining = max(0, originalDuration - totalElapsed)
    
    updateProgress()
    
    // Save state periodically
    if Int(timeRemaining) % 15 == 0 {
      saveTimerState()
    }
    
    // Check completion
    if timeRemaining <= 0 {
      handleTimerCompletion()
    }
  }

  private func handleTimerCompletion() {
    pauseTimer()
    timeRemaining = 0
    progress = 1
    
    // Haptic feedback
    #if os(iOS)
      let generator = UINotificationFeedbackGenerator()
      generator.notificationOccurred(.success)
    #endif

    // Handle work session completion
    if state == .work {
      completedPomodoros += 1
      
      if let subtaskID = activeSubtaskID {
        incrementSubtaskPomodoro(subtaskID: subtaskID)
      }
    }

    // Schedule notification
    scheduleCompletionNotification()

    // Auto-transition after delay
    Task {
      try? await Task.sleep(for: .seconds(2))
      
      await MainActor.run {
        transitionToNextState()
        resetTimerForNewState()
        
        // Auto-start breaks
        if state != .work {
          startTimer()
        } else {
          startNewLiveActivity()
        }
      }
    }
    
    print("✅ Timer completed: \(state.rawValue)")
  }

  private func transitionToNextState() {
    switch state {
    case .work:
      if completedPomodoros >= SettingsManager.shared.pomodorosUntilLongBreakCount {
        state = .longBreak
        completedPomodoros = 0
      } else {
        state = .shortBreak
      }
    case .shortBreak, .longBreak:
      state = .work
    }
  }

  private func resetTimerForNewState() {
    originalDuration = state.duration
    timeRemaining = originalDuration
    progress = 0
    sessionStartedAt = nil
    sessionPausedAt = nil
    timeElapsedBeforePause = 0
  }

  private func updateProgress() {
    if originalDuration > 0 {
      progress = 1 - (timeRemaining / originalDuration)
    } else {
      progress = 0
    }
  }

  // MARK: - Subtask Management

  func setActiveSubtask(_ subtaskID: UUID?, title: String? = nil) {
    if isRunning && activeSubtaskID != nil && activeSubtaskID != subtaskID {
      updateActiveTaskStatus(isRunning: false)
    }

    activeSubtaskID = subtaskID

    if let title = title {
      activeSubtaskTitle = title
    }

    if isRunning && subtaskID != nil {
      updateActiveTaskStatus(isRunning: true)
    }

    saveTimerState()

    if isRunning {
      startNewLiveActivity()
    }
  }

  private func updateActiveSubtaskTitle() {
    if activeSubtaskID != nil {
      activeSubtaskTitle = "Focus Session"
    } else {
      activeSubtaskTitle = nil
    }
  }

  // MARK: - Live Activity Methods

  private func startNewLiveActivity() {
    guard supportsLiveActivity else { return }

    let taskTitle = activeSubtaskTitle ?? "Polmodor Timer"
    let remainingTimeSeconds = Int(timeRemaining)
    let duration = Int(originalDuration)

    let sessionType: PolmodorLiveActivityAttributes.ContentState.SessionType
    switch state {
    case .work: sessionType = .work
    case .shortBreak: sessionType = .shortBreak
    case .longBreak: sessionType = .longBreak
    }

    LiveActivityManager.shared.startLiveActivity(
      taskTitle: taskTitle,
      remainingTime: remainingTimeSeconds,
      sessionType: sessionType,
      startedAt: isRunning ? sessionStartedAt : nil,
      pausedAt: isRunning ? nil : sessionPausedAt,
      duration: duration,
      isLocked: false
    )

    print("✅ Started new Live Activity: \(taskTitle), \(remainingTimeSeconds)s remaining")
  }

  private func updateLiveActivityPause() {
    guard supportsLiveActivity else { return }

    LiveActivityManager.shared.updateLiveActivity(
      remainingTime: Int(timeRemaining),
      pausedAt: sessionPausedAt
    )
  }

  // MARK: - Notification Methods

  private func scheduleCompletionNotification() {
    if SettingsManager.shared.isNotificationsEnabled {
      let title = "\(state.title) Completed!"
      let message = state == .work ? "Great job! Time for a break." : "Break finished! Ready to focus?"

      NotificationManager.shared.scheduleTimerCompletionNotification(
        title: title,
        message: message
      )
    }
  }

  // MARK: - Helper Methods

  private func incrementSubtaskPomodoro(subtaskID: UUID) {
    #if os(iOS)
      let generator = UIImpactFeedbackGenerator(style: .medium)
      generator.impactOccurred()
    #endif
    print("✅ Pomodoro increment for subtask: \(subtaskID)")
  }

  private func updateActiveTaskStatus(isRunning: Bool) {
    print("✅ Task status update: \(isRunning ? "running" : "stopped")")
  }

  // MARK: - App Intent Notification Handlers
  private func setupNotificationObservers() {
    NotificationCenter.default.addObserver(
      forName: Notification.Name("StartNextPomodorSession"),
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.startNextSession()
    }

    NotificationCenter.default.addObserver(
      forName: Notification.Name("TogglePomodorTimer"),
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.toggleTimer()
    }

    NotificationCenter.default.addObserver(
      forName: Notification.Name("SkipPomodorTimer"),
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.skipToNext()
    }

    NotificationCenter.default.addObserver(
      forName: Notification.Name("ToggleLockPomodorTimer"),
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.toggleLock()
    }

    NotificationCenter.default.addObserver(
      forName: Notification.Name("SyncWithLiveActivity"),
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.updateFromLiveActivity()
    }
  }

  func toggleLock() {
    let isLockedNow = UserDefaults.standard.bool(forKey: "TimerLockState")
    UserDefaults.standard.set(!isLockedNow, forKey: "TimerLockState")
    LiveActivityManager.shared.toggleLockLiveActivity(isLocked: !isLockedNow)
  }

  func startNextSession() {
    if timeRemaining <= 0 {
      skipToNext()
      startTimer()
    } else {
      toggleTimer()
    }
  }
}

// MARK: - Accessibility
extension TimerViewModel {
  var accessibilityLabel: String {
    let baseLabel = "\(state.title) Timer"
    if let title = activeSubtaskTitle {
      return "\(baseLabel) for \(title)"
    }
    return baseLabel
  }

  var accessibilityValue: String {
    let minutes = Int(timeRemaining) / 60
    let seconds = Int(timeRemaining) % 60
    return String(format: "%d minutes %d seconds remaining", minutes, seconds)
  }

  var accessibilityHint: String {
    isRunning ? "Double tap to pause timer" : "Double tap to start timer"
  }
}
