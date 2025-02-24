import Foundation
import SwiftUI

struct PolmodorTask: Identifiable, Codable {
  let id: UUID
  var title: String
  var description: String
  var iconName: String
  var category: TaskCategory
  var priority: TaskPriority
  var timeSpent: Double
  var timeRemaining: Double
  var dueDate: Date
  var completed: Bool
  var isTimerRunning: Bool
  var subTasks: [PolmodorSubTask]
  var createdAt: Date
  var completedAt: Date?
  var status: TaskStatus
  var completedPomodoros: Int

  var progress: Double {
    let completedSubtasks = subTasks.filter { $0.completed }.count
    return subTasks.isEmpty ? 0 : Double(completedSubtasks) / Double(subTasks.count)
  }

  var categoryColor: Color {
    category.color
  }

  enum TaskStatus: Int, Codable {
    case todo
    case inProgress
    case completed
  }

  init(
    id: UUID = UUID(),
    title: String,
    description: String = "",
    iconName: String = "checkmark.circle.fill",
    category: TaskCategory = .work,
    priority: TaskPriority = .medium,
    timeSpent: Double = 0,
    timeRemaining: Double = 0,
    dueDate: Date = Date().addingTimeInterval(86400),
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
    self.description = description
    self.iconName = iconName
    self.category = category
    self.priority = priority
    self.timeSpent = timeSpent
    self.timeRemaining = timeRemaining
    self.dueDate = dueDate
    self.completed = completed
    self.isTimerRunning = isTimerRunning
    self.subTasks = subTasks
    self.createdAt = createdAt
    self.completedAt = completedAt
    self.status = status
    self.completedPomodoros = completedPomodoros
  }

  mutating func incrementPomodoro() {
    completedPomodoros += 1
    if !subTasks.isEmpty {
      let totalPomodoros = subTasks.reduce(0) { $0 + $1.pomodoro.total }
      if completedPomodoros >= totalPomodoros {
        completed = true
        completedAt = Date()
        status = .completed
      } else {
        status = .inProgress
      }
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
        description: "Complete the Polmodor app features",
        iconName: "iphone",
        category: .work,
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
        description: "Learn advanced SwiftUI concepts",
        iconName: "book.fill",
        category: .study,
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
    ]
  }
}
