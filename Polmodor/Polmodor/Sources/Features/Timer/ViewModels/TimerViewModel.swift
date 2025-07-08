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

    @Published var timeRemaining: TimeInterval = 0
    @Published var isRunning: Bool = false
    @Published var state: PomodoroState = .work
    @Published var completedPomodoros: Int = 0
    @Published var activeSubtaskID: UUID?

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
    }

    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        // Keep startedAt and originalDuration for resume
        saveState()
    }

    func reset() {
        stop()
        timeRemaining = state.duration
        originalDuration = state.duration
        startedAt = nil
        saveState()
    }

    func skipToNext() {
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
    }

    @MainActor
    func updateFromLiveActivity() {
        loadState()
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
    }

    private func updateSubtaskProgress() {
        guard let activeSubtaskID = activeSubtaskID,
              let modelContext = modelContext else { return }

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
                timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { @Sendable [weak self] _ in
                    self?.tick()
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
            
            // If timer is at full duration (hasn't been started), update to new duration
            if timeRemaining == originalDuration {
                timeRemaining = newDuration
                originalDuration = newDuration
                saveState()
            }
        }
    }
}
