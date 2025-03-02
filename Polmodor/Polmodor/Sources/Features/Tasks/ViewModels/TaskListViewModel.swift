import Combine
import Foundation
import SwiftUI

@MainActor
final class TaskListViewModel: ObservableObject {
    @Published var tasks: [PolmodorTask] = []
    @Published var showAddTask = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        loadTasks()
    }

    func filteredTasks(searchText: String, category: TaskCategory) -> [PolmodorTask] {
        var filtered = tasks

        if !searchText.isEmpty {
            filtered = filtered.filter { task in
                task.title.localizedCaseInsensitiveContains(searchText)
                    || task.taskDescription.localizedCaseInsensitiveContains(searchText)
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

    func toggleSubtaskCompletion(_ subtask: PolmodorSubTask) {
        guard
            let taskIndex = tasks.firstIndex(where: { task in
                task.subTasks.contains { $0.id == subtask.id }
            })
        else { return }

        guard
            let subtaskIndex = tasks[taskIndex].subTasks.firstIndex(where: { $0.id == subtask.id })
        else { return }

        tasks[taskIndex].subTasks[subtaskIndex].completed.toggle()
        updateTaskProgress(taskIndex)
        saveTasks()
    }

    private func updateTaskProgress(_ taskIndex: Int) {
        let task = tasks[taskIndex]
        let _ = task.subTasks.filter { $0.completed }.count
        let _ = task.subTasks.count

        // TODO: Implement task progress update logic
    }

    private func loadTasks() {
        // TODO: Implement CoreData or other persistence
        // For now, using mock data
        tasks = PolmodorTask.mockTasks
    }

    private func saveTasks() {
        // TODO: Implement CoreData or other persistence
    }
}
