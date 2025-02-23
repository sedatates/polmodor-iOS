import Combine
import Foundation
import SwiftUI
import UserNotifications

#if os(iOS)
    import UIKit
#endif

@MainActor
class TimerViewModel: ObservableObject {
    @Published var progress: Double = 0
    @Published var timeRemaining: TimeInterval = 0
    @Published var state: PomodoroState = .work
    @Published var isRunning: Bool = false

    private var timer: Timer?
    private var startTime: Date?
    private var cancellables = Set<AnyCancellable>()
    private var completedPomodoros: Int = 0

    @AppStorage("workDuration") private var workDuration: TimeInterval = 25 * 60
    @AppStorage("shortBreakDuration") private var shortBreakDuration: TimeInterval = 5 * 60
    @AppStorage("longBreakDuration") private var longBreakDuration: TimeInterval = 15 * 60
    @AppStorage("pomodorosUntilLongBreak") private var pomodorosUntilLongBreak: Int = 4
    @AppStorage("autoStartBreaks") private var autoStartBreaks: Bool = false
    @AppStorage("autoStartPomodoros") private var autoStartPomodoros: Bool = false

    private var currentDuration: TimeInterval {
        switch state {
        case .work:
            return workDuration
        case .shortBreak:
            return shortBreakDuration
        case .longBreak:
            return longBreakDuration
        }
    }

    var timeRemainingFormatted: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    init() {
        setupInitialState()
        setupSettingsObserver()
        NotificationManager.shared.requestAuthorization()
    }

    private func setupInitialState() {
        timeRemaining = currentDuration
    }

    private func setupSettingsObserver() {
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .sink { [weak self] _ in
                guard let self = self else { return }
                if !self.isRunning {
                    self.timeRemaining = self.currentDuration
                }
            }
            .store(in: &cancellables)
    }

    func startTimer() {
        if timeRemaining <= 0 {
            resetTimer()
        }

        isRunning = true
        startTime = Date()

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }

    func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    func resetTimer() {
        pauseTimer()
        timeRemaining = currentDuration
        progress = 0
    }

    private func updateTimer() {
        guard let startTime = startTime else { return }

        let elapsedTime = Date().timeIntervalSince(startTime)
        timeRemaining = max(currentDuration - elapsedTime, 0)
        progress = 1 - (timeRemaining / currentDuration)

        if timeRemaining <= 0 {
            handleTimerCompletion()
        }
    }

    private func handleTimerCompletion() {
        pauseTimer()
        playCompletionSound()
        scheduleNotification()

        if state == .work {
            completedPomodoros += 1
        }

        moveToNextState()

        // Auto-start next session if enabled
        if (state == .work && autoStartPomodoros)
            || ((state == .shortBreak || state == .longBreak) && autoStartBreaks)
        {
            startTimer()
        }
    }

    private func moveToNextState() {
        switch state {
        case .work:
            state = shouldTakeLongBreak() ? .longBreak : .shortBreak
        case .shortBreak, .longBreak:
            state = .work
        }
        timeRemaining = currentDuration
        progress = 0
    }

    private func shouldTakeLongBreak() -> Bool {
        return completedPomodoros % pomodorosUntilLongBreak == 0
    }

    private func playCompletionSound() {
        #if os(iOS)
            SoundManager.shared.playCompletionSound()
        #endif
    }

    private func scheduleNotification() {
        let title = "\(state.title) Completed"
        let message = getNotificationMessage()
        NotificationManager.shared.scheduleTimerCompletionNotification(
            title: title, message: message)
    }

    private func getNotificationMessage() -> String {
        switch state {
        case .work:
            return "Great job! Time for a break."
        case .shortBreak:
            return "Break's over! Time to focus."
        case .longBreak:
            return "Long break completed. Ready for the next session?"
        }
    }

    func handleForegroundTransition() {
        if isRunning {
            updateTimer()
        }
    }

    func handleBackgroundTransition() {
        // Handle background state if needed
    }
}

// MARK: - Accessibility
extension TimerViewModel {
    var accessibilityLabel: String {
        "\(state.title) Timer"
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
