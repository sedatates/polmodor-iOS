import Foundation
import SwiftData

@Model
final class PolmodorSubTask {
    var id: UUID
    var title: String
    var completed: Bool

    // SwiftData'da PomodoroCount bileşenlerini doğrudan sakla
    var pomodoroTotal: Int
    var pomodoroCompleted: Int

    @Relationship(inverse: \PolmodorTask.subTasks)
    var task: PolmodorTask?

    init(
        id: UUID = UUID(),
        title: String,
        completed: Bool = false,
        pomodoro: PomodoroCount
    ) {
        self.id = id
        self.title = title
        self.completed = completed
        pomodoroTotal = pomodoro.total
        pomodoroCompleted = pomodoro.completed
    }

    // Pomodoro Count için computed property
    var pomodoro: PomodoroCount {
        get {
            PomodoroCount(total: pomodoroTotal, completed: pomodoroCompleted)
        }
        set {
            pomodoroTotal = newValue.total
            pomodoroCompleted = newValue.completed
        }
    }
}

// Model olmayan basit yapı
struct PomodoroCount: Codable, Hashable {
    var total: Int
    var completed: Int

    init(total: Int, completed: Int = 0) {
        self.total = total
        self.completed = completed
    }
}
