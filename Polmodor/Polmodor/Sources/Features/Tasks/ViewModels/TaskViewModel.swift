import Combine
import Foundation
import SwiftData
import SwiftUI

@Observable
@MainActor
final class TaskViewModel {
    private var modelContext: ModelContext
    private var tasksDescriptor: FetchDescriptor<PolmodorTask>
    private var categoriesDescriptor: FetchDescriptor<TaskCategory>

    @ObservationIgnored private var cancellables = Set<AnyCancellable>()

    var tasks: [PolmodorTask] = []
    var categories: [TaskCategory] = []
    var selectedFilter: TaskStatus?
    var searchText: String = ""
    var showAddTask: Bool = false

    init(modelContainer: ModelContainer) {
        modelContext = modelContainer.mainContext

        tasksDescriptor = FetchDescriptor<PolmodorTask>(
            sortBy: [SortDescriptor(\PolmodorTask.createdAt, order: .reverse)]
        )

        categoriesDescriptor = FetchDescriptor<TaskCategory>(
            sortBy: [SortDescriptor(\TaskCategory.name)]
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
                let defaultCategories = TaskCategory.defaultCategories
                defaultCategories.forEach { modelContext.insert($0) }
                try modelContext.save()
                categories = defaultCategories
            }
        } catch {
            print("Error loading data: \(error)")
        }
    }

    private func setupObservers() {
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .sink { [weak self] _ in
                self?.loadInitialData()
            }
            .store(in: &cancellables)
    }

    // MARK: - Task Management

    func addTask(_ task: PolmodorTask) {
        modelContext.insert(task)
        try? modelContext.save()
    }

    func updateTask(_: PolmodorTask) {
        try? modelContext.save()
    }

    func deleteTask(_ task: PolmodorTask) {
        modelContext.delete(task)
        try? modelContext.save()
    }

    func toggleTaskCompletion(_ task: PolmodorTask) {
        task.completed.toggle()
        if task.completed {
            task.completedAt = Date()
            task.status = .completed
        } else {
            task.completedAt = nil
            task.status = task.timeSpent > 0 ? .inProgress : .todo
        }
        try? modelContext.save()
    }

    func incrementPomodoro(for taskId: UUID) {
        guard let task = tasks.first(where: { $0.id == taskId }) else { return }
        task.incrementPomodoro()
        try? modelContext.save()
    }

    func toggleSubtaskCompletion(_ subtask: PolmodorSubTask) {
        subtask.completed.toggle()
        try? modelContext.save()
    }

    // MARK: - Category Management

    func addCategory(_ category: TaskCategory) {
        modelContext.insert(category)
        try? modelContext.save()
    }

    func deleteCategory(_ category: TaskCategory) {
        modelContext.delete(category)
        try? modelContext.save()
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

    func sortedTasks(_ tasks: [PolmodorTask]) -> [PolmodorTask] {
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
}
