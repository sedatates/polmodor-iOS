import Foundation
import SwiftData
import SwiftUI

final class TimerViewModel: ObservableObject {
  private var timer: Timer?
  private var modelContext: ModelContext?
  private var isConfigured: Bool = false
  private var startedAt: Date?
  private var originalDuration: TimeInterval = 0
  private var settingsObserver: NSObjectProtocol?
  private let liveActivityManager = LiveActivityManager.shared

  @Published var timeRemaining: TimeInterval = 0
  @Published var isRunning: Bool = false
  @Published var state: PomodoroState = .work
  @Published var completedPomodoros: Int = 0
  @Published var activeSubtaskID: UUID? {
    didSet {
      // Update Live Activity when active subtask changes
      if isRunning && activeSubtaskID != oldValue {
        Task { @MainActor in
          await updateLiveActivityTask()
        }
      }
    }
  }

  var currentStateColor: Color { state.color }
  var canReset: Bool { timeRemaining < state.duration || !isRunning }

  var accessibilityLabel: String { "\(state.title) Timer" }
  var accessibilityValue: String {
    let minutes = Int(timeRemaining) / 60
    let seconds = Int(timeRemaining) % 60
    return "\(minutes) minutes and \(seconds) seconds remaining"
  }

  var accessibilityHint: String { isRunning ? "Timer is running" : "Timer is paused" }

  init() {
    resetToDefault()
  }

  deinit {
    // Don't invalidate timer on deinit - let it continue running
    // Timer will be managed by the singleton instance
    if let observer = settingsObserver {
      NotificationCenter.default.removeObserver(observer)
    }
  }

  @MainActor
  func configure(with modelContext: ModelContext) {
    // Prevent multiple configurations
    guard !isConfigured else { return }

    self.modelContext = modelContext
    TimerStateManager.shared.configure(with: modelContext)
    loadState()
    setupSettingsObserver()
    isConfigured = true
  }

  func toggleTimer() {
    isRunning ? pause() : start()
  }

  func start() {
    guard timeRemaining > 0 else { return }

    isRunning = true
    startedAt = Date()
    originalDuration = timeRemaining

    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { @Sendable [weak self] _ in
      self?.tick()
    }
    saveState()

    // Start Live Activity
    Task { @MainActor in
      await startLiveActivity()
    }
  }

  func pause() {
    isRunning = false
    timer?.invalidate()
    timer = nil
    // Keep startedAt and originalDuration for resume
    saveState()

    // Update Live Activity with paused state
    Task { @MainActor in
      await updateLiveActivityPauseState()
    }
  }

  func reset() {
    stop()
    timeRemaining = state.duration
    originalDuration = state.duration
    startedAt = nil
    saveState()

    // End Live Activity
    Task { @MainActor in
      await liveActivityManager.endLiveActivity()
    }
  }

  func skipToNext() {
    stop()

    if state == .work {
      completedPomodoros += 1
      state = (completedPomodoros % 4 == 0) ? .longBreak : .shortBreak
    } else {
      state = .work
    }

    timeRemaining = state.duration
    originalDuration = state.duration
    startedAt = nil
    saveState()

    // End Live Activity when skipping
    Task { @MainActor in
      await liveActivityManager.endLiveActivity()
    }
  }

  @MainActor
  func updateFromLiveActivity() {
    loadState()
  }

  @MainActor
  func setActiveSubtask(_ subtaskID: UUID?) {
    activeSubtaskID = subtaskID
    saveState()
  }

  private func stop() {
    isRunning = false
    timer?.invalidate()
    timer = nil
  }

  private func tick() {
    guard isRunning, let startedAt = startedAt else { return }

    let elapsed = Date().timeIntervalSince(startedAt)
    timeRemaining = max(0, originalDuration - elapsed)

    if timeRemaining <= 0 {
      completeSession()
    } else {
      // Update Live Activity with remaining time
      Task { @MainActor in
        await updateLiveActivityTime()
      }
    }
  }

  private func completeSession() {
    stop()

    if state == .work {
      completedPomodoros += 1
      updateSubtaskProgress()
      state = (completedPomodoros % 4 == 0) ? .longBreak : .shortBreak
    } else {
      state = .work
    }

    timeRemaining = state.duration
    originalDuration = state.duration
    startedAt = nil
    saveState()

    // End Live Activity when session completes
    Task { @MainActor in
      await liveActivityManager.endLiveActivity()
    }
  }

  private func updateSubtaskProgress() {
    guard let activeSubtaskID = activeSubtaskID,
      let modelContext = modelContext
    else { return }

    Task { @MainActor in
      do {
        let descriptor = FetchDescriptor<PolmodorSubTask>(
          predicate: #Predicate { subtask in
            subtask.id == activeSubtaskID
          }
        )

        let subtasks = try modelContext.fetch(descriptor)
        if let subtask = subtasks.first {
          subtask.pomodoro.completed = min(subtask.pomodoro.completed + 1, subtask.pomodoro.total)

          if subtask.pomodoro.completed >= subtask.pomodoro.total {
            subtask.completed = true
          }

          try modelContext.save()
        }
      } catch {
        print("Error updating subtask progress: \(error)")
      }
    }
  }

  private func saveState() {
    let currentState = TimerState(
      activeSubtaskID: activeSubtaskID,
      originalDuration: originalDuration,
      state: state,
      completedPomodoros: completedPomodoros,
      isRunning: isRunning,
      startedAt: startedAt
    )
    TimerStateManager.shared.save(currentState)
  }

  @MainActor
  private func loadState() {
    let savedState = TimerStateManager.shared.load()

    activeSubtaskID = savedState.activeSubtaskID
    originalDuration = savedState.originalDuration
    state = savedState.state
    completedPomodoros = savedState.completedPomodoros
    startedAt = savedState.startedAt

    // Calculate current time remaining based on elapsed time
    if let startedAt = savedState.startedAt, savedState.isRunning {
      let elapsed = Date().timeIntervalSince(startedAt)
      timeRemaining = max(0, savedState.originalDuration - elapsed)

      if timeRemaining > 0 {
        isRunning = true
        // Restart the timer
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) {
          @Sendable [weak self] _ in
          self?.tick()
        }

        // Update Live Activity with current state
        Task { @MainActor in
          await startLiveActivity()
        }
      } else {
        // Timer completed while app was closed
        isRunning = false
        completeSession()
      }
    } else {
      // Timer was not running or no start time
      timeRemaining = savedState.originalDuration > 0 ? savedState.originalDuration : state.duration
      isRunning = false
    }
  }

  private func resetToDefault() {
    state = .work
    timeRemaining = state.duration
    originalDuration = state.duration
    isRunning = false
    completedPomodoros = 0
    activeSubtaskID = nil
    startedAt = nil
  }

  @MainActor
  private func setupSettingsObserver() {
    settingsObserver = NotificationCenter.default.addObserver(
      forName: NSNotification.Name("SettingsChanged"),
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.handleSettingsChange()
    }
  }

  @MainActor
  private func handleSettingsChange() {
    // Update duration if timer is not currently running
    // If timer is running, it will use the new duration after the current session
    if !isRunning {
      let newDuration = state.duration

      // Always update to new duration when timer is not running
      timeRemaining = newDuration
      originalDuration = newDuration
      saveState()
    }
  }

  // MARK: - Live Activity Integration

  @MainActor
  private func startLiveActivity() async {
    let taskTitle = await getCurrentTaskTitle()
    let sessionType = getSessionType()

    await liveActivityManager.startLiveActivity(
      taskTitle: taskTitle,
      remainingTime: Int(timeRemaining),
      sessionType: sessionType,
      startedAt: startedAt,
      pausedAt: nil,
      duration: Int(originalDuration),
      isLocked: false
    )
  }

  @MainActor
  private func updateLiveActivityTime() async {
    await liveActivityManager.updateLiveActivity(
      remainingTime: Int(timeRemaining),
      pausedAt: nil
    )
  }

  @MainActor
  private func updateLiveActivityPauseState() async {
    await liveActivityManager.updateLiveActivity(
      remainingTime: Int(timeRemaining),
      pausedAt: isRunning ? nil : Date()
    )
  }

  @MainActor
  private func updateLiveActivityTask() async {
    let taskTitle = await getCurrentTaskTitle()

    await liveActivityManager.updateLiveActivity(
      taskTitle: taskTitle,
      remainingTime: Int(timeRemaining),
      pausedAt: isRunning ? nil : Date()
    )
  }

  @MainActor
  private func getCurrentTaskTitle() async -> String {
    guard let activeSubtaskID = activeSubtaskID,
      let modelContext = modelContext
    else {
      return state.title
    }

    do {
      let descriptor = FetchDescriptor<PolmodorSubTask>(
        predicate: #Predicate { subtask in
          subtask.id == activeSubtaskID
        }
      )

      let subtasks = try modelContext.fetch(descriptor)
      if let subtask = subtasks.first {
        return subtask.title
      }
    } catch {
      print("Error fetching current task: \(error)")
    }

    return state.title
  }

  private func getSessionType() -> PolmodorLiveActivityAttributes.ContentState.SessionType {
    switch state {
    case .work:
      return .work
    case .shortBreak:
      return .shortBreak
    case .longBreak:
      return .longBreak
    }
  }
}
