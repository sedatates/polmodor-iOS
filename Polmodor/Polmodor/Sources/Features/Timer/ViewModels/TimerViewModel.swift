import Combine
import SwiftUI

#if os(iOS)
    import UIKit
    import UserNotifications
#endif

@MainActor
class TimerViewModel: ObservableObject {
    @Published private(set) var state: PomodoroState = .work
    @Published private(set) var progress: Double = 0
    @Published private(set) var timeRemaining: TimeInterval
    @Published private(set) var isRunning = false

    private var timer: AnyCancellable?
    private var startTime: Date?
    private var backgroundTime: Date?

    init() {
        self.timeRemaining = PomodoroState.work.duration
    }

    func handleBackgroundTransition() {
        backgroundTime = Date()
    }

    func handleForegroundTransition() {
        guard let backgroundTime = backgroundTime else { return }
        let timeInBackground = Date().timeIntervalSince(backgroundTime)
        if isRunning {
            timeRemaining = max(0, timeRemaining - timeInBackground)
            if timeRemaining == 0 {
                completeTimer()
            }
        }
    }

    func startTimer() {
        isRunning = true
        startTime = Date()

        timer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTimer()
            }
    }

    func pauseTimer() {
        isRunning = false
        timer?.cancel()
        timer = nil
    }

    func resetTimer() {
        pauseTimer()
        timeRemaining = state.duration
        progress = 0
    }

    func skipToNext() {
        switch state {
        case .work:
            state = .shortBreak
        case .shortBreak:
            state = .work
        case .longBreak:
            state = .work
        }
        resetTimer()
    }

    private func updateTimer() {
        guard let startTime = startTime else { return }
        let elapsedTime = Date().timeIntervalSince(startTime)
        timeRemaining = max(0, state.duration - elapsedTime)
        progress = 1 - (timeRemaining / state.duration)

        if timeRemaining == 0 {
            completeTimer()
        }
    }

    private func completeTimer() {
        pauseTimer()
        progress = 1
        timeRemaining = 0

        #if os(iOS)
            // Play haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            // Schedule local notification if in background
            if UIApplication.shared.applicationState == .background {
                let content = UNMutableNotificationContent()
                content.title = "\(state.title) Completed"
                content.body = "Time to take a break!"
                content.sound = .default

                let request = UNNotificationRequest(
                    identifier: UUID().uuidString,
                    content: content,
                    trigger: nil
                )

                UNUserNotificationCenter.current().add(request)
            }
        #endif
    }
}

// MARK: - Time Formatting
extension TimerViewModel {
    var timeRemainingFormatted: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
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
