import Combine
import Foundation
import SwiftData
import SwiftUI

@Observable
final class TaskViewModel {
    private var modelContext: ModelContext
    private var tasksDescriptor: FetchDescriptor<PolmodorTask>
    private var categoriesDescriptor: FetchDescriptor<TaskCategory>

    @ObservationIgnored private var cancellables = Set<AnyCancellable>()

    var tasks: [PolmodorTask] = []
    var categories: [TaskCategory] = []
    var selectedFilter: PolmodorTask.TaskStatus?
    var searchText: String = ""
    var showAddTask: Bool = false

    init(modelContainer: ModelContainer) {
        self.modelContext = modelContainer.mainContext

        self.tasksDescriptor = FetchDescriptor<PolmodorTask>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        self.categoriesDescriptor = FetchDescriptor<TaskCategory>(
            sortBy: [SortDescriptor(\.name)]
        )

        loadInitialData()
        setupObservers()
    }

    // MARK: - Data Loading
    private func loadInitialData() {
        do {
            tasks = try modelContext.fetch(tasksDescriptor)
            categories = try modelContext.fetch(categoriesDescriptor)

            if categories.isEmpty {
                categories = TaskCategory.defaultCategories
                categories.forEach { modelContext.insert($0) }
                try modelContext.save()
            }
        } catch {
            print("Error loading data: \(error)")
        }
    }

    private func setupObservers() {
        NotificationCenter.default.publisher(for: ModelContext.didSaveNotification)
            .sink { [weak self] _ in
                self?.loadInitialData()
            }
            .store(in: &cancellables)
    }

    // MARK: - Task Management
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

        if category.name != "All" {
            filtered = filtered.filter { $0.category.id == category.id }
        }

        return sortedTasks(filtered)
    }

    func addTask(_ task: PolmodorTask) {
        modelContext.insert(task)
        saveContext()
    }

    func updateTask(_ task: PolmodorTask) {
        saveContext()
    }

    func deleteTask(_ task: PolmodorTask) {
        modelContext.delete(task)
        saveContext()
    }

    func incrementPomodoro(for taskId: UUID) {
        guard let task = tasks.first(where: { $0.id == taskId }) else { return }
        task.incrementPomodoro()
        saveContext()
    }

    func toggleSubtaskCompletion(_ subtask: PolmodorSubTask) {
        subtask.completed.toggle()
        saveContext()
    }

    // MARK: - Category Management
    func addCategory(_ category: TaskCategory) {
        modelContext.insert(category)
        saveContext()
    }

    func deleteCategory(_ category: TaskCategory) {
        modelContext.delete(category)
        saveContext()
    }

    // MARK: - Statistics
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
    private func sortedTasks(_ tasks: [PolmodorTask]) -> [PolmodorTask] {
        tasks.sorted { task1, task2 in
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

    // MARK: - Context Management
    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}
