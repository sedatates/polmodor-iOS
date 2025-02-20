import Combine
import Foundation
import SwiftUI

#if os(iOS)
    import UIKit
    import UserNotifications
#endif

protocol TimerServiceProtocol: AnyObject {
    var currentState: PomodoroState { get }
    var progress: Double { get }
    var timeRemaining: TimeInterval { get }
    var isRunning: Bool { get }

    func start()
    func pause()
    func reset()
    func skipToNext()
}

class TimerService: TimerServiceProtocol {
    private(set) var currentState: PomodoroState = .work
    private(set) var progress: Double = 0
    private(set) var timeRemaining: TimeInterval
    private(set) var isRunning = false

    private var timer: AnyCancellable?
    private var startTime: Date?
    private var backgroundTime: Date?

    init() {
        self.timeRemaining = PomodoroState.work.duration
        #if os(iOS)
            setupNotifications()
        #endif
    }

    #if os(iOS)
        private func setupNotifications() {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleBackgroundTransition),
                name: UIApplication.didEnterBackgroundNotification,
                object: nil
            )

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleForegroundTransition),
                name: UIApplication.willEnterForegroundNotification,
                object: nil
            )
        }

        @objc private func handleBackgroundTransition() {
            backgroundTime = Date()
        }

        @objc private func handleForegroundTransition() {
            guard let backgroundTime = backgroundTime else { return }
            let timeInBackground = Date().timeIntervalSince(backgroundTime)
            if isRunning {
                timeRemaining = max(0, timeRemaining - timeInBackground)
                if timeRemaining == 0 {
                    completeTimer()
                }
            }
        }
    #endif

    func start() {
        isRunning = true
        startTime = Date()

        timer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTimer()
            }
    }

    func pause() {
        isRunning = false
        timer?.cancel()
        timer = nil
    }

    func reset() {
        pause()
        timeRemaining = currentState.duration
        progress = 0
    }

    func skipToNext() {
        switch currentState {
        case .work:
            currentState = .shortBreak
        case .shortBreak:
            currentState = .work
        case .longBreak:
            currentState = .work
        }
        reset()
    }

    private func updateTimer() {
        guard let startTime = startTime else { return }
        let elapsedTime = Date().timeIntervalSince(startTime)
        timeRemaining = max(0, currentState.duration - elapsedTime)
        progress = 1 - (timeRemaining / currentState.duration)

        if timeRemaining == 0 {
            completeTimer()
        }
    }

    private func completeTimer() {
        pause()
        progress = 1
        timeRemaining = 0

        #if os(iOS)
            // Schedule notification if in background
            if UIApplication.shared.applicationState == .background {
                scheduleNotification()
            }
        #endif
    }

    #if os(iOS)
        private func scheduleNotification() {
            let content = UNMutableNotificationContent()
            content.title = "\(currentState.title) Completed"
            content.body = "Time for a \(currentState == .work ? "break" : "work session")!"
            content.sound = UNNotificationSound.default

            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil as UNNotificationTrigger?
            )

            UNUserNotificationCenter.current().add(request)
        }
    #endif
}
