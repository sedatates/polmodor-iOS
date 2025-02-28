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
    @AppStorage("pomodorosUntilLongBreak") private var pomodorosUntilLongBreak = 4
    private var modelContext: ModelContext?

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

    // Configure with SwiftData ModelContext
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Public Methods
    func toggleTimer() {
        if isRunning {
            pauseTimer()
        } else {
            startTimer()
        }
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
    }

    func resetTimer() {
        pauseTimer()
        timeRemaining = totalTime
        progress = 0
        state = .work
        completedPomodoros = 0
    }

    func skipToNext() {
        let wasWorkState = state == .work

        switch state {
        case .work:
            completedPomodoros += 1

            // If completing a work session, increment the subtask's pomodoro count
            if let subtaskID = activeSubtaskID {
                incrementSubtaskPomodoro(subtaskID: subtaskID)
            }

            if completedPomodoros >= pomodorosUntilLongBreak {
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
    }

    // MARK: - Private Methods
    private func updateTimer() {
        guard timeRemaining > 0 else {
            handleTimerCompletion()
            return
        }

        timeRemaining -= 1
        progress = 1 - (timeRemaining / totalTime)
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
            // Increment pomodoro count for the active subtask
            if let subtaskID = activeSubtaskID {
                incrementSubtaskPomodoro(subtaskID: subtaskID)
            }
        }

        // Handle auto-transition based on settings
        let shouldAutoStart = UserDefaults.standard.bool(
            forKey: state == .work ? "autoStartBreaks" : "autoStartPomodoros")

        skipToNext()

        if shouldAutoStart {
            startTimer()
        }

        // Schedule notification if app is in background
        if UIApplication.shared.applicationState != .active {
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
                subtask.pomodoro = PomodoroCount(
                    total: subtask.pomodoro.total,
                    completed: subtask.pomodoro.completed + 1
                )

                // Also increment the parent task's completed pomodoros
                if let parentTask = subtask.task {
                    parentTask.completedPomodoros += 1
                }

                try context.save()
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
