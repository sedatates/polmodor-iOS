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
    @Published var activeSubtaskID: UUID?

    // MARK: - Private Properties
    private var timer: AnyCancellable?
    private var modelContext: ModelContext?
    private var settingsCancellable: AnyCancellable?

    // MARK: - Live Activity Support
    private var supportsLiveActivity: Bool {
        if #available(iOS 16.1, *) {
            return ActivityAuthorizationInfo().areActivitiesEnabled
        }
        return false
    }

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

        // Setup notification observers for App Intents
        setupNotificationObservers()
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

        // Also save the active task title for widget and live activity use
        if let taskTitle = activeSubtaskTitle {
            UserDefaults.standard.set(taskTitle, forKey: "TimerStateManager.activeTaskTitle")
        } else {
            UserDefaults.standard.removeObject(forKey: "TimerStateManager.activeTaskTitle")
        }
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

    // MARK: - Live Activity Methods

    /// Start or update a Live Activity for the current timer
    private func updateLiveActivity() {
        // Early return if device doesn't support Live Activities
        guard supportsLiveActivity else { return }

        let taskTitle = activeSubtaskTitle ?? "Polmodor Timer"
        let remainingTimeSeconds = Int(timeRemaining)
        let duration = Int(state.duration)
        _ = state == .shortBreak ? "short" : (state == .longBreak ? "long" : "none")

        // Get parent task name if available
        var parentTaskName: String? = nil
        var totalPomodoros = 0
        var completedPomodoros = 0

        if let subtaskID = activeSubtaskID, let context = modelContext {
            do {
                // Fetch the subtask
                let subtaskDescriptor = FetchDescriptor<PolmodorSubTask>(
                    predicate: #Predicate { subtask in
                        subtask.id == subtaskID
                    }
                )
                let results = try context.fetch(subtaskDescriptor)

                if let subtask = results.first, let parentTask = subtask.task {
                    parentTaskName = parentTask.title
                    totalPomodoros = subtask.pomodoro.total
                    completedPomodoros = subtask.pomodoro.completed
                }
            } catch {
                print("Error fetching task details for Live Activity: \(error)")
            }
        }

        do {
            // Convert state to SessionType for Live Activity
            let sessionType: PolmodorLiveActivityAttributes.ContentState.SessionType
            switch state {
            case .work:
                sessionType = .work
            case .shortBreak:
                sessionType = .shortBreak
            case .longBreak:
                sessionType = .longBreak
            }

            LiveActivityManager.shared.startLiveActivity(
                taskTitle: taskTitle,
                remainingTime: remainingTimeSeconds,
                sessionType: sessionType,
                startedAt: isRunning ? Date() : nil,
                pausedAt: isRunning ? nil : Date(),
                duration: duration,
                isLocked: false
            )
        } catch {
            print("Failed to start Live Activity: \(error.localizedDescription)")
            // Live Activity hatası uygulama çökmesine neden olmamalı
        }
    }

    /// Update the existing Live Activity
    private func updateLiveActivityState() {
        // Early return if device doesn't support Live Activities
        guard supportsLiveActivity else { return }

        // Update the Live Activity with current timer state
        do {
            LiveActivityManager.shared.updateLiveActivity(
                remainingTime: Int(timeRemaining),
                pausedAt: isRunning ? nil : Date()
            )
        } catch {
            print("Failed to update Live Activity state: \(error.localizedDescription)")
            // Live Activity güncellemesi başarısız olursa uygulama çökmemeli
        }
    }

    /// End the current Live Activity
    private func endLiveActivity() {
        LiveActivityManager.shared.endLiveActivity()
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

        // Update Live Activity state
        updateLiveActivityState()
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

        // Create or update Live Activity based on current timer state
        updateLiveActivity()  // This will create a new one or update existing
    }

    func pauseTimer() {
        isRunning = false
        timer?.cancel()

        // Update the task status when paused
        updateActiveTaskStatus(isRunning: false)

        // Save timer state when paused
        saveTimerState()

        // Timer tamamen durduğunda Live Activity'yi de kapat
        if timeRemaining <= 0 {
            print("Timer completed, ending Live Activity")
            // Live Activity'yi kapat
            endLiveActivity()
        } else {
            // Timer sadece duraklatıldıysa Live Activity'yi güncelle
            updateLiveActivityState()
        }
    }

    func resetTimer() {
        pauseTimer()
        timeRemaining = totalTime
        progress = 0
        state = .work
        completedPomodoros = 0

        // Save state after reset
        saveTimerState()

        // Resetleme durumunda her zaman mevcut Live Activity'yi kapat
        endLiveActivity()

        // Kısa bir gecikme ekleyerek yeni Live Activity oluşumuna hazırlan
        Task {
            try? await Task.sleep(for: .seconds(0.5))
        }
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

        // Update Live Activity with new timer state
        updateLiveActivity()
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

        // Update Live Activity with new task title if running
        if isRunning {
            updateLiveActivity()
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

        // Save state periodically (e.g. every 15 seconds)
        if Int(timeRemaining) % 15 == 0 {
            saveTimerState()

            // Update Live Activity periodically
            updateLiveActivityState()
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

        // Explicitly end the Live Activity before state transition
        // This ensures the widget is properly dismissed when the timer completes
        endLiveActivity()

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

    // MARK: - App Intent Notification Handlers
    private func setupNotificationObservers() {
        // Observer for starting the next session
        NotificationCenter.default.addObserver(
            forName: Notification.Name("StartNextPomodorSession"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.startNextSession()
        }

        // Observer for toggling the timer
        NotificationCenter.default.addObserver(
            forName: Notification.Name("TogglePomodorTimer"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.toggleTimer()
        }

        // Observer for skipping the timer
        NotificationCenter.default.addObserver(
            forName: Notification.Name("SkipPomodorTimer"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.skipToNext()
        }

        // Observer for toggling lock state
        NotificationCenter.default.addObserver(
            forName: Notification.Name("ToggleLockPomodorTimer"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.toggleLock()
        }
    }

    // Function to toggle lock state - for Live Activity
    func toggleLock() {
        let isLockedNow = UserDefaults.standard.bool(forKey: "TimerLockState")
        UserDefaults.standard.set(!isLockedNow, forKey: "TimerLockState")

        // Update the Live Activity's lock state
        LiveActivityManager.shared.toggleLockLiveActivity(isLocked: !isLockedNow)
    }

    // Function to start the next session - for Live Activity
    func startNextSession() {
        if timeRemaining <= 0 {
            // If the timer has finished, start the next session type
            skipToNext()
            startTimer()
        } else {
            // Otherwise, just toggle the current timer
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
