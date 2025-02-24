import Combine
import Foundation
import SwiftUI

protocol TaskServiceProtocol {
    // MARK: - Properties
    var tasks: [PolmodorTask] { get }
    var tasksPublisher: Published<[PolmodorTask]>.Publisher { get }
    var selectedFilter: PolmodorTask.TaskStatus? { get set }
    var searchText: String { get set }
    var showAddTask: Bool { get set }

    // MARK: - Task Management
    func filteredTasks(searchText: String, category: TaskCategory) -> [PolmodorTask]
    func addTask(_ task: PolmodorTask)
    func updateTask(_ task: PolmodorTask)
    func deleteTask(_ task: PolmodorTask)
    func moveTask(from source: IndexSet, to destination: Int)
    func incrementPomodoro(for taskId: UUID)
    func toggleSubtaskCompletion(_ subtask: PolmodorSubTask)
    func updateTaskProgress(_ taskIndex: Int)
    func loadTasks()
    func saveTasks()

    // MARK: - Task Statistics
    var completedTasksCount: Int { get }
    var totalPomodorosCompleted: Int { get }
    var totalTasksCount: Int { get }
    var completionRate: Double { get }

    // MARK: - Task Filtering
    var todoTasks: [PolmodorTask] { get }
    var inProgressTasks: [PolmodorTask] { get }
    var completedTasks: [PolmodorTask] { get }

    // MARK: - Task Sorting
    func sortedTasks(_ tasks: [PolmodorTask]) -> [PolmodorTask]
}

class TaskService: TaskServiceProtocol {
    // MARK: - Published Properties
    @Published private var taskArray: [PolmodorTask] = []

    private let userDefaults: UserDefaults
    private let tasksKey = "savedTasks"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        loadTasks()
    }

    var tasksPublisher: Published<[PolmodorTask]>.Publisher {
        $taskArray
    }

    var tasks: [PolmodorTask] {
        taskArray
    }

    var selectedFilter: PolmodorTask.TaskStatus?
    var searchText: String = ""
    var showAddTask: Bool = true

    func filteredTasks(searchText: String, category: TaskCategory) -> [PolmodorTask] {
        var filtered = tasks

        if !searchText.isEmpty {
            filtered = filtered.filter { task in
                task.title.localizedCaseInsensitiveContains(searchText)
                    || task.description.localizedCaseInsensitiveContains(searchText)
                    || task.subTasks.contains { subtask in
                        subtask.title.localizedCaseInsensitiveContains(searchText)
                    }
            }
        }

        if category != .all {
            filtered = filtered.filter { $0.category == category }
        }

        return filtered
    }

    func addTask(_ task: PolmodorTask) {
        taskArray.append(task)
        saveTasks()
    }

    func updateTask(_ task: PolmodorTask) {
        if let index = taskArray.firstIndex(where: { $0.id == task.id }) {
            taskArray[index] = task
            saveTasks()
        }
    }

    func deleteTask(_ task: PolmodorTask) {
        taskArray.removeAll { $0.id == task.id }
        saveTasks()
    }

    func moveTask(from source: IndexSet, to destination: Int) {
        taskArray.move(fromOffsets: source, toOffset: destination)
        saveTasks()
    }

    func incrementPomodoro(for taskId: UUID) {
        guard let index = taskArray.firstIndex(where: { $0.id == taskId }) else { return }
        var task = taskArray[index]
        task.incrementPomodoro()
        taskArray[index] = task
        saveTasks()
    }

    func toggleSubtaskCompletion(_ subtask: PolmodorSubTask) {
        guard
            let taskIndex = taskArray.firstIndex(where: { task in
                task.subTasks.contains { $0.id == subtask.id }
            })
        else { return }

        guard
            let subtaskIndex = taskArray[taskIndex].subTasks.firstIndex(where: {
                $0.id == subtask.id
            })
        else { return }

        var updatedTask = taskArray[taskIndex]
        updatedTask.subTasks[subtaskIndex].completed.toggle()
        taskArray[taskIndex] = updatedTask
        updateTaskProgress(taskIndex)
        saveTasks()
    }

    func updateTaskProgress(_ taskIndex: Int) {
        var tasks = taskArray
        let task = tasks[taskIndex]
        let completedSubtasks = task.subTasks.filter { $0.completed }.count
        let totalSubtasks = task.subTasks.count

        tasks[taskIndex].timeSpent =
            completedSubtasks > 0
            ? Double(completedSubtasks) / Double(totalSubtasks) * task.timeRemaining : 0

        taskArray = tasks
    }

    func loadTasks() {
        guard let data = userDefaults.data(forKey: tasksKey),
            let tasks = try? JSONDecoder().decode([PolmodorTask].self, from: data)
        else {
            return
        }
        taskArray = tasks
    }

    func saveTasks() {
        guard let data = try? JSONEncoder().encode(taskArray) else { return }
        userDefaults.set(data, forKey: tasksKey)
    }

    // MARK: - Task Statistics
    var completedTasksCount: Int {
        tasks.filter { $0.status == .completed }.count
    }

    var totalPomodorosCompleted: Int {
        tasks.reduce(0) { $0 + $1.completedPomodoros }
    }

    var totalTasksCount: Int {
        tasks.count
    }

    var completionRate: Double {
        guard totalTasksCount > 0 else { return 0 }
        return Double(completedTasksCount) / Double(totalTasksCount)
    }

    // MARK: - Task Filtering
    var todoTasks: [PolmodorTask] {
        tasks.filter { $0.status == .todo }
    }

    var inProgressTasks: [PolmodorTask] {
        tasks.filter { $0.status == .inProgress }
    }

    var completedTasks: [PolmodorTask] {
        tasks.filter { $0.status == .completed }
    }

    // MARK: - Task Sorting
    func sortedTasks(_ tasks: [PolmodorTask]) -> [PolmodorTask] {
        return tasks.sorted { (task1: PolmodorTask, task2: PolmodorTask) -> Bool in
            if task1.status == task2.status {
                if task1.status == .completed {
                    return task1.completedAt ?? Date() > task2.completedAt ?? Date()
                } else {
                    return task1.createdAt < task2.createdAt
                }
            }
            return task1.status.rawValue < task2.status.rawValue
        }
    }
}
