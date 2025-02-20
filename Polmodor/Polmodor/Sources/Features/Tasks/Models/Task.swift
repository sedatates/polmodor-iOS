import Foundation

struct PolmodorTask: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var description: String
    var pomodoroCount: Int
    var completedPomodoros: Int
    var status: TaskStatus
    var createdAt: Date
    var updatedAt: Date
    var completedAt: Date?

    enum TaskStatus: String, Codable, CaseIterable {
        case todo = "Todo"
        case inProgress = "In Progress"
        case completed = "Completed"

        var systemImage: String {
            switch self {
            case .todo:
                return "circle"
            case .inProgress:
                return "clock"
            case .completed:
                return "checkmark.circle.fill"
            }
        }
    }

    init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        pomodoroCount: Int = 1,
        completedPomodoros: Int = 0,
        status: TaskStatus = .todo,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.pomodoroCount = pomodoroCount
        self.completedPomodoros = completedPomodoros
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
    }

    var progress: Double {
        guard pomodoroCount > 0 else { return 0 }
        return Double(completedPomodoros) / Double(pomodoroCount)
    }

    mutating func incrementPomodoro() {
        completedPomodoros = min(completedPomodoros + 1, pomodoroCount)
        if completedPomodoros == pomodoroCount {
            status = .completed
            completedAt = Date()
        } else if status == .todo {
            status = .inProgress
        }
        updatedAt = Date()
    }
}

// MARK: - Sample Data
extension PolmodorTask {
    static let sampleTasks = [
        PolmodorTask(
            title: "Complete Project Documentation",
            description: "Write comprehensive documentation for the new features",
            pomodoroCount: 4,
            completedPomodoros: 2,
            status: .inProgress
        ),
        PolmodorTask(
            title: "Code Review",
            description: "Review pull requests from team members",
            pomodoroCount: 2,
            status: .todo
        ),
        PolmodorTask(
            title: "Bug Fixes",
            description: "Fix reported bugs in the latest release",
            pomodoroCount: 3,
            completedPomodoros: 3,
            status: .completed,
            completedAt: Date().addingTimeInterval(-3600)  // Completed 1 hour ago
        ),
    ]
}
