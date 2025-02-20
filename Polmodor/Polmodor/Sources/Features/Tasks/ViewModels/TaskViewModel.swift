import Combine
import SwiftUI

@MainActor
class TaskViewModel: ObservableObject {
    @Published private(set) var tasks: [PolmodorTask] = []
    @Published var selectedFilter: PolmodorTask.TaskStatus?
    @Published var searchText = ""

    private let userDefaults = UserDefaults.standard
    private let tasksKey = "savedTasks"

    init() {
        loadTasks()
    }

    var filteredTasks: [PolmodorTask] {
        var filtered = tasks
        if let filter = selectedFilter {
            filtered = filtered.filter { $0.status == filter }
        }
        if !searchText.isEmpty {
            filtered = filtered.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
        return filtered
    }

    var todoTasks: [PolmodorTask] {
        filteredTasks.filter { $0.status == .todo }
    }

    var inProgressTasks: [PolmodorTask] {
        filteredTasks.filter { $0.status == .inProgress }
    }

    var completedTasks: [PolmodorTask] {
        filteredTasks.filter { $0.status == .completed }
    }

    func addTask(_ task: PolmodorTask) {
        tasks.append(task)
        saveTasks()
    }

    func updateTask(_ task: PolmodorTask) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index] = task
        saveTasks()
    }

    func deleteTask(_ task: PolmodorTask) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
    }

    func moveTask(from source: IndexSet, to destination: Int) {
        tasks.move(fromOffsets: source, toOffset: destination)
        saveTasks()
    }

    func incrementPomodoro(for taskId: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == taskId }) else { return }
        var task = tasks[index]
        task.incrementPomodoro()
        tasks[index] = task
        saveTasks()
    }

    private func loadTasks() {
        guard let data = userDefaults.data(forKey: tasksKey),
            let savedTasks = try? JSONDecoder().decode([PolmodorTask].self, from: data)
        else {
            return
        }
        tasks = savedTasks
    }

    private func saveTasks() {
        guard let data = try? JSONEncoder().encode(tasks) else { return }
        userDefaults.set(data, forKey: tasksKey)
    }
}

// MARK: - Task Statistics
extension TaskViewModel {
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
}

// MARK: - Task Sorting
extension TaskViewModel {
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
