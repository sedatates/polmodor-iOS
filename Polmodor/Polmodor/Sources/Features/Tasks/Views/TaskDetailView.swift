import SwiftData
import SwiftUI

struct TaskDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var task: PolmodorTask
    @Query(sort: \TaskCategory.name) private var categories: [TaskCategory]
    @State private var showAddSubtask = false
    @State private var newSubtaskTitle = ""
    @State private var showInlineSubtaskAdd = false
    @EnvironmentObject private var timerViewModel: TimerViewModel

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
                    SubtaskRowView(subtask: subtask)
                }
                .onDelete(perform: deleteSubtasks)

                if showInlineSubtaskAdd {
                    HStack {
                        TextField("New subtask title", text: $newSubtaskTitle)
                            .submitLabel(.done)
                            .onSubmit {
                                if !newSubtaskTitle.isEmpty {
                                    addInlineSubtask()
                                    newSubtaskTitle = ""
                                    showInlineSubtaskAdd = false
                                }
                            }

                        Button(action: {
                            if !newSubtaskTitle.isEmpty {
                                addInlineSubtask()
                                newSubtaskTitle = ""
                            }
                            showInlineSubtaskAdd = false
                        }) {
                            Text("Add")
                                .font(.subheadline.bold())
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .controlSize(.mini)

                        Button(action: {
                            newSubtaskTitle = ""
                            showInlineSubtaskAdd = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Button(action: {
                        showInlineSubtaskAdd = true
                    }) {
                        Label("Quick Add Subtask", systemImage: "plus")
                    }
                }

                Button(action: {
                    showAddSubtask = true
                }) {
                    Label("Add Detailed Subtask", systemImage: "plus.circle")
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

    private func addInlineSubtask() {
        let subtask = PolmodorSubTask(
            title: newSubtaskTitle,
            pomodoro: .init(total: 1, completed: 0)
        )
        task.subTasks.append(subtask)
        try? modelContext.save()
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
                .environmentObject(TimerViewModel())
        }
        .modelContainer(container)
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}
