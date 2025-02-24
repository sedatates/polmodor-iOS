import Combine
import Foundation
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

    // MARK: - Private Properties
    private var timer: AnyCancellable?
    @AppStorage("pomodorosUntilLongBreak") private var pomodorosUntilLongBreak = 4

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

    // MARK: - Initialization
    init() {
        self.timeRemaining = PomodoroState.work.duration
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
    }

    func pauseTimer() {
        isRunning = false
        timer?.cancel()
    }

    func resetTimer() {
        pauseTimer()
        timeRemaining = totalTime
        progress = 0
        state = .work
        completedPomodoros = 0
    }

    func skipToNext() {
        switch state {
        case .work:
            completedPomodoros += 1
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

        // Handle auto-transition based on settings
        let shouldAutoStart = UserDefaults.standard.bool(
            forKey: state == .work ? "autoStartBreaks" : "autoStartPomodoros")

        skipToNext()

        if shouldAutoStart {
            startTimer()
        }
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
