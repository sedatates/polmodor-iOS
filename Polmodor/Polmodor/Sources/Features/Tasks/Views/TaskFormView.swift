import SwiftUI

struct TaskFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var description: String
    @State private var category: TaskCategory
    @State private var priority: TaskPriority
    @State private var iconName: String
    @State private var subTasks: [PolmodorSubTask]
    @State private var showingSubtaskSheet = false
    @State private var newSubtaskTitle = ""
    @State private var selectedPomodoroCount = 1
    @EnvironmentObject var taskViewModel: TaskViewModel

    private let task: PolmodorTask?
    private let onSave: (PolmodorTask) -> Void

    private var isValid: Bool {
        !title.isEmpty
    }

    init(task: PolmodorTask? = nil, onSave: @escaping (PolmodorTask) -> Void) {
        self.task = task
        self.onSave = onSave

        _title = State(initialValue: task?.title ?? "")
        _description = State(initialValue: task?.description ?? "")
        _category = State(initialValue: task?.category ?? .work)
        _priority = State(initialValue: task?.priority ?? .medium)
        _iconName = State(initialValue: task?.iconName ?? "checkmark.circle.fill")
        _subTasks = State(initialValue: task?.subTasks ?? [])
    }

    var body: some View {
        Form {
            Section(header: Text("Task Details")) {
                TextField("Title", text: $title)
                    .textInputAutocapitalization(.words)

                TextEditor(text: $description)
                    .frame(height: 100)

                Picker("Category", selection: $category) {
                    ForEach(taskViewModel.categories) { category in
                        Label(category.name, systemImage: category.iconName)
                            .foregroundColor(category.color)
                            .tag(category)
                    }
                }

                Picker("Priority", selection: $priority) {
                    ForEach(TaskPriority.allCases, id: \.self) { priority in
                        Label(priority.rawValue.capitalized, systemImage: priority.iconName)
                            .foregroundColor(priority.color)
                            .tag(priority)
                    }
                }

                IconPicker(selectedIcon: $iconName)
            }

            Section(header: Text("Subtasks")) {
                ForEach(subTasks) { subtask in
                    SubtaskRow(subtask: subtask)
                }
                .onDelete { indexSet in
                    subTasks.remove(atOffsets: indexSet)
                }

                Button(action: { showingSubtaskSheet = true }) {
                    Label("Add Subtask", systemImage: "plus.circle.fill")
                }
            }
        }
        .navigationTitle(task == nil ? "New Task" : "Edit Task")
        .navigationBarItems(
            leading: Button("Cancel") {
                dismiss()
            },
            trailing: Button("Save") {
                saveTask()
                dismiss()
            }
            .disabled(!isValid)
        )
        .sheet(isPresented: $showingSubtaskSheet) {
            AddSubtaskSheet(
                isPresented: $showingSubtaskSheet,
                newSubtaskTitle: $newSubtaskTitle,
                selectedPomodoroCount: $selectedPomodoroCount,
                addSubtask: addSubtask
            )
        }
    }

    private func addSubtask() {
        let newSubtask = PolmodorSubTask(
            title: newSubtaskTitle,
            pomodoro: .init(total: selectedPomodoroCount, completed: 0)
        )
        subTasks.append(newSubtask)
        newSubtaskTitle = ""
        selectedPomodoroCount = 1
    }

    private func saveTask() {
        let updatedTask = PolmodorTask(
            id: task?.id ?? UUID(),
            title: title,
            description: description,
            iconName: iconName,
            category: category,
            priority: priority,
            timeSpent: task?.timeSpent ?? 0,
            timeRemaining: Double(subTasks.reduce(0) { $0 + $1.pomodoro.total }) * 25 * 60,
            dueDate: task?.dueDate ?? Date().addingTimeInterval(86400 * 7),
            completed: task?.completed ?? false,
            isTimerRunning: task?.isTimerRunning ?? false,
            subTasks: subTasks,
            createdAt: task?.createdAt ?? Date(),
            completedAt: task?.completedAt,
            status: task?.status ?? .todo,
            completedPomodoros: task?.completedPomodoros ?? 0
        )
        onSave(updatedTask)
    }
}

private struct SubtaskRow: View {
    let subtask: PolmodorSubTask

    var body: some View {
        HStack {
            Text(subtask.title)
            Spacer()
            Text("\(subtask.pomodoro.total) 🍅")
                .foregroundColor(.gray)
        }
    }
}

private struct IconPicker: View {
    @Binding var selectedIcon: String

    private let icons = [
        "checkmark.circle.fill",
        "list.bullet",
        "book.fill",
        "graduationcap.fill",
        "briefcase.fill",
        "house.fill",
        "heart.fill",
        "star.fill",
        "flag.fill",
        "bell.fill",
    ]

    var body: some View {
        Picker("Icon", selection: $selectedIcon) {
            ForEach(icons, id: \.self) { icon in
                Label("", systemImage: icon)
                    .tag(icon)
            }
        }
    }
}

#Preview {
    NavigationView {
        TaskFormView { _ in }
            .environmentObject(TaskViewModel())
    }
}
