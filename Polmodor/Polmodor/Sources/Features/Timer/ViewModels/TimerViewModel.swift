import Combine
import Foundation
import SwiftData
import SwiftUI
import UserNotifications

#if os(iOS)
    import UIKit
#endif

@MainActor
final class TimerViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var timeRemaining: TimeInterval
    @Published private(set) var isRunning = false
    @Published private(set) var progress: Double = 0
    @Published private(set) var state: PomodoroState = .work
    @Published private(set) var completedPomodoros: Int = 0
    @Published var activeSubtaskID: UUID?

    // MARK: - Private Properties
    private var timer: AnyCancellable?
    private var modelContext: ModelContext?
    private var settingsCancellable: AnyCancellable?

    private var totalTime: TimeInterval {
        state.duration
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

    var activeSubtaskTitle: String? {
        if let context = modelContext, let subtaskID = activeSubtaskID {
            do {
                let descriptor = FetchDescriptor<PolmodorSubTask>(
                    predicate: #Predicate { subtask in
                        subtask.id == subtaskID
                    }
                )
                let results = try context.fetch(descriptor)
                return results.first?.title
            } catch {
                print("Error fetching active subtask: \(error)")
                return nil
            }
        }
        return nil
    }

    // MARK: - Initialization
    init() {
        self.timeRemaining = PomodoroState.work.duration
    }

    // Initialize with ModelContainer
    convenience init(modelContainer: ModelContainer) {
        self.init()
        self.configure(with: modelContainer.mainContext)

        // Configure SettingsManager with the same context
        Task {
            SettingsManager.shared.configure(with: modelContainer.mainContext)
        }
    }

    // Configure with SwiftData ModelContext
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext

        // Configure TimerStateManager with the same context
        Task {
            TimerStateManager.shared.configure(with: modelContext)

            // Restore saved timer state
            restoreTimerState()
        }

        // Observe settings changes
        observeSettingsChanges()
    }

    // Observe settings changes to update timer behavior
    private func observeSettingsChanges() {
        // This would be implemented if SettingsManager exposed Combine publishers
        // For now, we'll rely on the PomodoroState.duration computed property
        // which reads from SettingsManager.shared
    }

    // MARK: - Timer State Persistence

    /// Saves the current timer state to persistent storage
    func saveTimerState() {
        TimerStateManager.shared.saveTimerState(
            activeSubtaskID: activeSubtaskID,
            timeRemaining: timeRemaining,
            pomodoroState: state,
            completedPomodoros: completedPomodoros,
            isRunning: isRunning
        )
    }

    /// Restores the timer state from persistent storage
    private func restoreTimerState() {
        let (
            savedSubtaskID, savedTimeRemaining, savedState, savedCompletedPomodoros, savedIsRunning
        ) =
            TimerStateManager.shared.loadTimerState()

        // Only restore if we have valid data
        if savedState.duration > 0 {
            self.state = savedState
            self.timeRemaining = savedTimeRemaining > 0 ? savedTimeRemaining : savedState.duration
            self.completedPomodoros = savedCompletedPomodoros

            // Calculate progress based on time remaining
            self.progress = 1 - (timeRemaining / state.duration)

            // Set the active subtask if one was saved
            self.activeSubtaskID = savedSubtaskID

            // If it was running, we don't auto-resume, but we update the UI state
            if savedIsRunning {
                // Note: we don't call startTimer() here because we want the user to explicitly restart
                // after relaunching the app
            }
        }
    }

    // MARK: - Public Methods
    func toggleTimer() {
        if isRunning {
            pauseTimer()
        } else {
            startTimer()
        }

        // Save state after toggling
        saveTimerState()
    }

    func startTimer() {
        guard !isRunning else { return }
        isRunning = true

        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTimer()
            }

        // If we have an active subtask, update its parent task's status
        updateActiveTaskStatus(isRunning: true)
    }

    func pauseTimer() {
        isRunning = false
        timer?.cancel()

        // Update the task status when paused
        updateActiveTaskStatus(isRunning: false)

        // Save timer state when paused
        saveTimerState()
    }

    func resetTimer() {
        pauseTimer()
        timeRemaining = totalTime
        progress = 0
        state = .work
        completedPomodoros = 0

        // Save state after reset
        saveTimerState()
    }

    func skipToNext() {
        let _ = state == .work  // Using underscore to indicate intentional unused check

        switch state {
        case .work:
            completedPomodoros += 1

            // If completing a work session, increment the subtask's pomodoro count
            if let subtaskID = activeSubtaskID {
                incrementSubtaskPomodoro(subtaskID: subtaskID)
            }

            if completedPomodoros >= SettingsManager.shared.pomodorosUntilLongBreakCount {
                state = .longBreak
                completedPomodoros = 0
            } else {
                state = .shortBreak
            }
        case .shortBreak, .longBreak:
            state = .work
        }
        timeRemaining = totalTime
        progress = 0
        if isRunning {
            startTimer()
        }

        // Save state after skipping
        saveTimerState()
    }

    // Set active subtask for the timer
    func setActiveSubtask(_ subtaskID: UUID?) {
        // If we're changing subtasks while timer is running, update the previous task status
        if isRunning && activeSubtaskID != nil && activeSubtaskID != subtaskID {
            updateActiveTaskStatus(isRunning: false)
        }

        activeSubtaskID = subtaskID

        // Update the new task status if timer is running
        if isRunning && subtaskID != nil {
            updateActiveTaskStatus(isRunning: true)
        }

        // Save state after changing active subtask
        saveTimerState()
    }

    // MARK: - Private Methods
    private func updateTimer() {
        guard timeRemaining > 0 else {
            handleTimerCompletion()
            return
        }

        timeRemaining -= 1
        progress = 1 - (timeRemaining / totalTime)

        // Save state periodically (e.g. every 15 seconds)
        if Int(timeRemaining) % 15 == 0 {
            saveTimerState()
        }
    }

    private func handleTimerCompletion() {
        pauseTimer()
        progress = 1

        // Notify completion with sound/haptic feedback
        #if os(iOS)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        #endif

        // If this was a work session that completed
        if state == .work {
            completedPomodoros += 1

            // Increment pomodoro count for the active subtask
            if let subtaskID = activeSubtaskID {
                incrementSubtaskPomodoro(subtaskID: subtaskID)
            }
        }

        // Handle auto-transition based on settings
        let shouldAutoStart =
            state == .work
            ? SettingsManager.shared.shouldAutoStartBreaks
            : SettingsManager.shared.shouldAutoStartPomodoros

        skipToNext()

        if shouldAutoStart {
            startTimer()
        }

        // Schedule notification if app is in background
        if UIApplication.shared.applicationState != .active
            && SettingsManager.shared.isNotificationsEnabled
        {
            let title = state == .work ? "Time to focus!" : "Time for a break!"
            let message =
                activeSubtaskTitle != nil
                ? "Continue working on: \(activeSubtaskTitle!)"
                : "Your \(state.rawValue) session is ready to begin"

            NotificationManager.shared.scheduleTimerCompletionNotification(
                title: title,
                message: message
            )
        }
    }

    // Increment the pomodoro count for a subtask
    private func incrementSubtaskPomodoro(subtaskID: UUID) {
        guard let context = modelContext else { return }

        do {
            let descriptor = FetchDescriptor<PolmodorSubTask>(
                predicate: #Predicate { subtask in
                    subtask.id == subtaskID
                }
            )
            let results = try context.fetch(descriptor)

            if let subtask = results.first {
                // Increment the completed pomodoro count
                let currentCompleted = subtask.pomodoro.completed
                let currentTotal = subtask.pomodoro.total

                // Only increment if we haven't reached the total
                if currentCompleted < currentTotal {
                    subtask.pomodoro = PomodoroCount(
                        total: currentTotal,
                        completed: currentCompleted + 1
                    )

                    // Also increment the parent task's completed pomodoros
                    if let parentTask = subtask.task {
                        parentTask.completedPomodoros += 1

                        // Update timeSpent
                        parentTask.timeSpent += state.duration
                    }

                    try context.save()

                    // Provide feedback for completed pomodoro
                    #if os(iOS)
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                    #endif
                }
            }
        } catch {
            print("Error updating subtask pomodoro count: \(error)")
        }
    }

    private func updateActiveTaskStatus(isRunning: Bool) {
        guard let context = modelContext, let subtaskID = activeSubtaskID else { return }

        do {
            let descriptor = FetchDescriptor<PolmodorSubTask>(
                predicate: #Predicate { subtask in
                    subtask.id == subtaskID
                }
            )
            let results = try context.fetch(descriptor)

            if let subtask = results.first, let parentTask = subtask.task {
                parentTask.isTimerRunning = isRunning

                // If starting a timer, also update the status to in progress
                if isRunning && parentTask.status == .todo {
                    parentTask.status = .inProgress
                }

                try context.save()
            }
        } catch {
            print("Error updating task status: \(error)")
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
