import Foundation
import SwiftData
import SwiftUI

struct TimerState {
    var activeSubtaskID: UUID?
    var originalDuration: TimeInterval
    var state: PomodoroState
    var completedPomodoros: Int
    var isRunning: Bool
    var startedAt: Date?
}

/// Manages the persistence of timer state between app launches
@Observable final class TimerStateManager {
    static let shared = TimerStateManager()

    private enum Keys {
        static let activeSubtaskID = "TimerStateManager.activeSubtaskID"
        static let originalDuration = "TimerStateManager.originalDuration"
        static let pomodoroState = "TimerStateManager.pomodoroState"
        static let completedPomodoros = "TimerStateManager.completedPomodoros"
        static let isRunning = "TimerStateManager.isRunning"
        static let startedAt = "TimerStateManager.startedAt"
    }

    private var modelContext: ModelContext?

    private init() {}

    @MainActor
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func save(_ timerState: TimerState) {
        if let activeSubtaskID = timerState.activeSubtaskID {
            UserDefaults.standard.set(activeSubtaskID.uuidString, forKey: Keys.activeSubtaskID)
        } else {
            UserDefaults.standard.removeObject(forKey: Keys.activeSubtaskID)
        }

        UserDefaults.standard.set(timerState.originalDuration, forKey: Keys.originalDuration)
        UserDefaults.standard.set(timerState.state.rawValue, forKey: Keys.pomodoroState)
        UserDefaults.standard.set(timerState.completedPomodoros, forKey: Keys.completedPomodoros)
        UserDefaults.standard.set(timerState.isRunning, forKey: Keys.isRunning)

        if let startedAt = timerState.startedAt {
            UserDefaults.standard.set(startedAt, forKey: Keys.startedAt)
        } else {
            UserDefaults.standard.removeObject(forKey: Keys.startedAt)
        }

        UserDefaults.standard.synchronize()
    }

    @MainActor
    func load() -> TimerState {
        let activeSubtaskIDString = UserDefaults.standard.string(forKey: Keys.activeSubtaskID)
        let activeSubtaskID = activeSubtaskIDString.flatMap { UUID(uuidString: $0) }
        let validatedSubtaskID = validateSubtaskID(activeSubtaskID)

        let originalDuration = UserDefaults.standard.double(forKey: Keys.originalDuration)
        let stateRawValue = UserDefaults.standard.string(forKey: Keys.pomodoroState) ?? PomodoroState.work.rawValue
        let state = PomodoroState(rawValue: stateRawValue) ?? .work
        let completedPomodoros = UserDefaults.standard.integer(forKey: Keys.completedPomodoros)
        let isRunning = UserDefaults.standard.bool(forKey: Keys.isRunning)
        let startedAt = UserDefaults.standard.object(forKey: Keys.startedAt) as? Date

        return TimerState(
            activeSubtaskID: validatedSubtaskID,
            originalDuration: originalDuration > 0 ? originalDuration : state.duration,
            state: state,
            completedPomodoros: completedPomodoros,
            isRunning: isRunning,
            startedAt: startedAt
        )
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: Keys.activeSubtaskID)
        UserDefaults.standard.removeObject(forKey: Keys.originalDuration)
        UserDefaults.standard.removeObject(forKey: Keys.pomodoroState)
        UserDefaults.standard.removeObject(forKey: Keys.completedPomodoros)
        UserDefaults.standard.removeObject(forKey: Keys.isRunning)
        UserDefaults.standard.removeObject(forKey: Keys.startedAt)
        UserDefaults.standard.synchronize()
    }

    @MainActor
    private func validateSubtaskID(_ subtaskID: UUID?) -> UUID? {
        guard let subtaskID = subtaskID, let context = modelContext else {
            return nil
        }

        do {
            let descriptor = FetchDescriptor<PolmodorSubTask>(
                predicate: #Predicate { subtask in
                    subtask.id == subtaskID
                }
            )

            let results = try context.fetch(descriptor)
            return results.first?.id
        } catch {
            print("Error validating subtask ID: \(error)")
            return nil
        }
    }
}
