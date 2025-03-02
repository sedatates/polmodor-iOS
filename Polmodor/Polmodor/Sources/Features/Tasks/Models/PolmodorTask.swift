import Foundation
import SwiftData
import SwiftUI

@Model
final class PolmodorTask {
    var id: UUID
    var title: String
    var taskDescription: String
    var iconName: String
    
    var category: TaskCategory?
    
    // TaskPriority için enum değerini saklama
    var priorityRawValue: String
    
    var timeSpent: Double
    var timeRemaining: Double
    var dueDate: Date
    var completed: Bool
    var isTimerRunning: Bool
    
    // Alt görevlerle ilişki
    @Relationship(deleteRule: .cascade)
    var subTasks: [PolmodorSubTask] = []
    
    var createdAt: Date
    var completedAt: Date?
    
    // TaskStatus için enum değerini saklama
    var statusRawValue: String
    
    var completedPomodoros: Int
    
    init(
        id: UUID = UUID(),
        title: String,
        taskDescription: String = "",
        iconName: String,
        category: TaskCategory? = nil,
        priority: TaskPriority = .medium,
        timeSpent: Double = 0,
        timeRemaining: Double,
        dueDate: Date,
        completed: Bool = false,
        isTimerRunning: Bool = false,
        subTasks: [PolmodorSubTask] = [],
        createdAt: Date = Date(),
        completedAt: Date? = nil,
        status: TaskStatus = .todo,
        completedPomodoros: Int = 0
    ) {
        self.id = id
        self.title = title
        self.taskDescription = taskDescription
        self.iconName = iconName
        self.category = category
        self.priorityRawValue = priority.rawValue
        self.timeSpent = timeSpent
        self.timeRemaining = timeRemaining
        self.dueDate = dueDate
        self.completed = completed
        self.isTimerRunning = isTimerRunning
        self.subTasks = subTasks
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.statusRawValue = status.rawValue
        self.completedPomodoros = completedPomodoros
    }
    
    // Computed property for priority
    var priority: TaskPriority {
        get {
            TaskPriority(rawValue: priorityRawValue) ?? .medium
        }
        set {
            priorityRawValue = newValue.rawValue
        }
    }
    
    // Computed property for status
    var status: TaskStatus {
        get {
            TaskStatus(rawValue: statusRawValue) ?? .todo
        }
        set {
            statusRawValue = newValue.rawValue
        }
    }
    
    var progress: Double {
        guard timeRemaining > 0 else { return 0 }
        return timeSpent / timeRemaining
    }
    
    func incrementPomodoro() {
        completedPomodoros += 1
    }
}

// MARK: - Task Status
enum TaskStatus: String, Codable, Hashable, CaseIterable {
    case todo
    case inProgress
    case completed
    
    var displayName: String {
        switch self {
        case .todo: return "To Do"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        }
    }
    
    var iconName: String {
        switch self {
        case .todo: return "circle"
        case .inProgress: return "clock"
        case .completed: return "checkmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .todo: return .gray
        case .inProgress: return .blue
        case .completed: return .green
        }
    }
}

// MARK: - Mock Data
extension PolmodorTask {
    static var mockTasks: [PolmodorTask] {
        [
            PolmodorTask(
                id: UUID(),
                title: "iOS App Development",
                taskDescription: "Complete the Polmodor app features",
                iconName: "iphone",
                category: TaskCategory.defaultCategories[0],
                priority: .high,
                timeSpent: 120,
                timeRemaining: 240,
                dueDate: Date().addingTimeInterval(86400 * 2),
                completed: false,
                isTimerRunning: false,
                subTasks: [
                    PolmodorSubTask(
                        id: UUID(),
                        title: "Implement Task List",
                        completed: true,
                        pomodoro: .init(total: 4, completed: 2)
                    ),
                    PolmodorSubTask(
                        id: UUID(),
                        title: "Add Timer Feature",
                        completed: false,
                        pomodoro: .init(total: 3, completed: 1)
                    ),
                ]
            ),
            PolmodorTask(
                id: UUID(),
                title: "Study SwiftUI",
                taskDescription: "Learn advanced SwiftUI concepts",
                iconName: "book.fill",
                category: TaskCategory.defaultCategories[1],
                priority: .medium,
                timeSpent: 60,
                timeRemaining: 180,
                dueDate: Date().addingTimeInterval(86400 * 3),
                completed: false,
                isTimerRunning: false,
                subTasks: [
                    PolmodorSubTask(
                        id: UUID(),
                        title: "Animations",
                        completed: false,
                        pomodoro: .init(total: 2, completed: 1)
                    ),
                    PolmodorSubTask(
                        id: UUID(),
                        title: "Core Data",
                        completed: false,
                        pomodoro: .init(total: 3, completed: 0)
                    ),
                ]
            ),
            PolmodorTask(
                id: UUID(),
                title: "Go for a Run",
                taskDescription: "Exercise regularly to maintain health",
                iconName: "person.running",
                category: TaskCategory.defaultCategories[2],
                priority: .low,
                timeSpent: 30,
                timeRemaining: 150,
                dueDate: Date().addingTimeInterval(86400 * 5),
                completed: false,
                isTimerRunning: false,
                subTasks: []
            ),
            PolmodorTask(
                id: UUID(),
                title: "Go for a Run",
                taskDescription: "Exercise regularly to maintain health",
                iconName: "person.running",
                category: TaskCategory.defaultCategories[2],
                priority: .low,
                timeSpent: 30,
                timeRemaining: 150,
                dueDate: Date().addingTimeInterval(86400 * 5),
                completed: false,
                isTimerRunning: false,
                subTasks: [
                    PolmodorSubTask(
                        id: UUID(),
                        title: "Morning Run",
                        completed: false,
                        pomodoro: .init(total: 2, completed: 0)
                    ),
                    PolmodorSubTask(
                        id: UUID(),
                        title: "Evening Run",
                        completed: false,
                        pomodoro: .init(total: 2, completed: 0)
                    ),
                ]
            ),
        ]
    }
}
