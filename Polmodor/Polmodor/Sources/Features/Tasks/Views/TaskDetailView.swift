import SwiftData
import SwiftUI

struct TaskDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var task: PolmodorTask
    @Query(sort: \TaskCategory.name) private var categories: [TaskCategory]
    @State private var showAddSubtask = false

    var body: some View {
        List {
            Section("Task Details") {
                TextField("Title", text: $task.title)
                TextField("Description", text: $task.taskDescription, axis: .vertical)
                    .lineLimit(3...6)

                Picker("Category", selection: $task.category) {
                    ForEach(categories) { category in
                        Text(category.name)
                            .tag(TaskCategory?.some(category))
                    }
                }

                Picker("Priority", selection: $task.priority) {
                    ForEach(TaskPriority.allCases, id: \.self) { priority in
                        Label(priority.rawValue.capitalized, systemImage: priority.iconName)
                            .tag(priority)
                    }
                }

                Toggle("Completed", isOn: $task.completed)
            }

            Section("Time") {
                DatePicker("Due Date", selection: $task.dueDate)

                HStack {
                    Text("Time Spent")
                    Spacer()
                    Text(timeString(from: task.timeSpent))
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Time Remaining")
                    Spacer()
                    Text(timeString(from: task.timeRemaining))
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Completed Pomodoros")
                    Spacer()
                    Text("\(task.completedPomodoros)")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Subtasks") {
                ForEach(task.subTasks) { subtask in
                    SubtaskRow(subtask: subtask)
                }
                .onDelete(perform: deleteSubtasks)

                Button(action: {
                    showAddSubtask = true
                }) {
                    Label("Add Subtask", systemImage: "plus.circle")
                }
            }
        }
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddSubtask) {
            SubTaskAddView(task: task)
                .presentationDetents([.medium])
        }
        .withFloatingTabBarPadding()
    }

    private func timeString(from seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) / 60 % 60

        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else {
            return String(format: "%dm", minutes)
        }
    }

    private func deleteSubtasks(at offsets: IndexSet) {
        for index in offsets {
            let subtask = task.subTasks[index]
            modelContext.delete(subtask)
        }
    }

    private func addSubtask() {
        let subtask = PolmodorSubTask(
            title: "New Subtask",
            pomodoro: .init(total: 1, completed: 0)
        )
        task.subTasks.append(subtask)
    }
}

private struct SubtaskRow: View {
    @Bindable var subtask: PolmodorSubTask

    var body: some View {
        HStack {
            Toggle(isOn: $subtask.completed) {
                VStack(alignment: .leading) {
                    Text(subtask.title)

                    Text("\(subtask.pomodoro.completed)/\(subtask.pomodoro.total) pomodoros")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: PolmodorTask.self, configurations: config)
        let task = PolmodorTask.mockTasks[0]
        container.mainContext.insert(task)

        return NavigationStack {
            TaskDetailView(task: task)
        }
        .modelContainer(container)
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}
