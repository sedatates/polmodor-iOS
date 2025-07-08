import Combine
import Foundation
import SwiftData
import SwiftUI

protocol TaskServiceProtocol {
    // MARK: - Properties

    var tasks: [PolmodorTask] { get }
    var categories: [TaskCategory] { get set }
    var searchText: String { get set }
    var showAddTask: Bool { get set }

    // MARK: - Task Management

    func fetchTasks() async throws -> [PolmodorTask]
    func fetchTask(withId id: UUID) async throws -> PolmodorTask?
    func fetchTasks(withStatus status: TaskStatus) async throws -> [PolmodorTask]
    func addTask(_ task: PolmodorTask) async throws
    func updateTask(_ task: PolmodorTask) async throws
    func deleteTask(_ task: PolmodorTask) async throws
    func deleteAllTasks() async throws

    func moveTask(from source: IndexSet, to destination: Int)
    func incrementPomodoro(for taskId: UUID)
    func toggleSubtaskCompletion(_ subtask: PolmodorSubTask)

    // MARK: - Category Management

    func addCategory(_ category: TaskCategory)
    func deleteCategory(_ category: TaskCategory)

    // MARK: - Task Statistics

    var completedTasksCount: Int { get }
    var totalPomodorosCompleted: Int { get }
    var totalTasksCount: Int { get }
    var completionRate: Double { get }

    // MARK: - Task Filtering

    var todoTasks: [PolmodorTask] { get }
    var inProgressTasks: [PolmodorTask] { get }
    var completedTasks: [PolmodorTask] { get }
}

// MARK: - Error Types

enum TaskServiceError: LocalizedError {
    case taskNotFound
    case saveFailed
    case deleteFailed
    case fetchFailed

    var errorDescription: String? {
        switch self {
        case .taskNotFound:
            return "Task could not be found"
        case .saveFailed:
            return "Failed to save task"
        case .deleteFailed:
            return "Failed to delete task"
        case .fetchFailed:
            return "Failed to fetch tasks"
        }
    }
}
