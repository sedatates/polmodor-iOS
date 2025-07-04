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
    settingsCancellable = NotificationCenter.default.publisher(
      for: NSNotification.Name("SettingsChanged")
    )
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

    // Handle different timer states more safely
    if savedIsRunning && savedTimeRemaining > 0 {
      // Calculate actual remaining time based on when timer was started
      if let startedAt = savedStartedAt {
        let elapsedSinceStart = Date().timeIntervalSince(startedAt)
        let actualRemaining = max(0, originalDuration - elapsedSinceStart)

        if actualRemaining > 0 {
          self.timeRemaining = actualRemaining
          self.isRunning = false  // Will be started by UI
          print("🟢 Timer restored with \(Int(actualRemaining))s remaining")
        } else {
          // Timer completed while app was closed
          handleTimerCompletionFromBackground()
        }
      } else {
        // No start time, use saved remaining time
        self.timeRemaining = savedTimeRemaining
        self.isRunning = false
      }
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

      // Statistics'e kaydet
      saveCompletedPomodoroToStatistics()
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
    // Stop tuşuna basıldığında LiveActivity'yi sonlandır
    LiveActivityManager.shared.endLiveActivity()
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

    let totalElapsed = Date().timeIntervalSince(startedAt) * 10
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

      // Statistics'e kaydet
      saveCompletedPomodoroToStatistics()
    }

    // Schedule notification
    scheduleCompletionNotification()

    // Auto-transition after delay
    Task {
      try? await Task.sleep(for: .seconds(2))

      await MainActor.run {
        transitionToNextState()
        resetTimerForNewState()

        // Update live activity but don't auto-start
        startNewLiveActivity()
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
  
  private func selectNextAvailableSubtask() {
    guard let modelContext = modelContext else { return }
    
    do {
      // Tüm incomplete subtask'ları getir
      let descriptor = FetchDescriptor<PolmodorSubTask>(
        predicate: #Predicate { $0.pomodoroCompleted < $0.pomodoroTotal }
      )
      
      let availableSubtasks = try modelContext.fetch(descriptor)
      
      if let nextSubtask = availableSubtasks.first {
        // Yeni subtask seç
        setActiveSubtask(nextSubtask.id, title: nextSubtask.title)
        print("🔄 Selected next subtask: \(nextSubtask.title)")
      } else {
        // Hiç subtask kalmadı
        setActiveSubtask(nil, title: nil)
        print("✅ All subtasks completed!")
      }
    } catch {
      print("❌ Error selecting next subtask: \(error)")
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

    // Calculate accurate remaining time for live activity sync
    let accurateRemainingTime: Int
    if isRunning, let startedAt = sessionStartedAt {
      let elapsed = Date().timeIntervalSince(startedAt)
      accurateRemainingTime = max(0, Int(originalDuration - elapsed))
    } else {
      accurateRemainingTime = remainingTimeSeconds
    }

    LiveActivityManager.shared.startLiveActivity(
      taskTitle: taskTitle,
      remainingTime: accurateRemainingTime,
      sessionType: sessionType,
      startedAt: isRunning ? sessionStartedAt : nil,
      pausedAt: isRunning ? nil : sessionPausedAt,
      duration: duration,
      isLocked: false
    )

    print("✅ Started new Live Activity: \(taskTitle), \(accurateRemainingTime)s remaining")
  }

  // MARK: - Notification Methods

  private func scheduleCompletionNotification() {
    if SettingsManager.shared.isNotificationsEnabled {
      let title = "\(state.title) Completed!"
      let message =
        state == .work ? "Great job! Time for a break." : "Break finished! Ready to focus?"

      NotificationManager.shared.scheduleTimerCompletionNotification(
        title: title,
        message: message
      )
    }
  }

  // MARK: - Helper Methods

  private func incrementSubtaskPomodoro(subtaskID: UUID) {
    guard let modelContext = modelContext else { return }

    do {
      let descriptor = FetchDescriptor<PolmodorSubTask>(
        predicate: #Predicate { $0.id == subtaskID }
      )

      if let subtask = try modelContext.fetch(descriptor).first {
        subtask.pomodoroCompleted += 1

        // Parent task'ın pomodoro sayısını da artır
        if let task = subtask.task {
          task.incrementPomodoro()
        }

        try modelContext.save()
        print("✅ Pomodoro incremented for subtask: \(subtask.title)")
      }
    } catch {
      print("❌ Error incrementing subtask pomodoro: \(error)")
    }

    #if os(iOS)
      let generator = UIImpactFeedbackGenerator(style: .medium)
      generator.impactOccurred()
    #endif
  }

  private func updateActiveTaskStatus(isRunning: Bool) {
    print("✅ Task status update: \(isRunning ? "running" : "stopped")")
  }

  private func saveCompletedPomodoroToStatistics() {
    guard let modelContext = modelContext else { return }

    do {
      let calendar = Calendar.current
      let today = calendar.startOfDay(for: Date())
      let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

      let descriptor = FetchDescriptor<StatisticsModel>(
        predicate: #Predicate { $0.date >= today && $0.date < tomorrow }
      )

      let todayStats = try modelContext.fetch(descriptor).first

      if let existingStats = todayStats {
        // Bugün için kayıt var, güncelle
        existingStats.completedPomodoros += 1
        existingStats.totalFocusTime += originalDuration
      } else {
        // Yeni kayıt oluştur
        let newStats = StatisticsModel(
          date: today,
          completedPomodoros: 1,
          totalFocusTime: originalDuration
        )
        modelContext.insert(newStats)
      }

      try modelContext.save()
      print("✅ Statistics updated: +1 pomodoro, +\(Int(originalDuration/60)) min focus time")
    } catch {
      print("❌ Error saving statistics: \(error)")
    }
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
