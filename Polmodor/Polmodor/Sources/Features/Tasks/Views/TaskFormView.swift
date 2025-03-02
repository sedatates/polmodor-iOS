import SwiftData
import SwiftUI

struct TaskFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskCategory.name) private var categories: [TaskCategory]

    let task: PolmodorTask?
    let onSave: (PolmodorTask) -> Void

    @State private var title: String
    @State private var taskDescription: String
    @State private var selectedCategory: TaskCategory?
    @State private var selectedPriority: TaskPriority
    @State private var iconName: String
    @State private var timeRemaining: Double
    @State private var dueDate: Date

    init(task: PolmodorTask? = nil, onSave: @escaping (PolmodorTask) -> Void) {
        self.task = task
        self.onSave = onSave

        _title = State(initialValue: task?.title ?? "")
        _taskDescription = State(initialValue: task?.taskDescription ?? "")
        _selectedCategory = State(initialValue: task?.category)
        _selectedPriority = State(initialValue: task?.priority ?? .medium)
        _iconName = State(initialValue: task?.iconName ?? "circle.fill")
        _timeRemaining = State(initialValue: task?.timeRemaining ?? 25 * 60)
        _dueDate = State(initialValue: task?.dueDate ?? Date().addingTimeInterval(86400))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task Details") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $taskDescription, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Icon") {
                    IconPicker(selectedIcon: $iconName)
                }

                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        Text("None")
                            .tag(TaskCategory?.none)
                        ForEach(categories) { category in
                            Text(category.name)
                                .tag(TaskCategory?.some(category))
                        }
                    }
                }

                Section("Priority") {
                    Picker("Priority", selection: $selectedPriority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            Label(priority.rawValue.capitalized, systemImage: priority.iconName)
                                .tag(priority)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Time") {
                    DatePicker("Due Date", selection: $dueDate, in: Date()...)

                    Stepper(
                        "Time Required: \(Int(timeRemaining / 60)) minutes",
                        value: $timeRemaining,
                        in: 5 * 60...120 * 60,
                        step: 5 * 60
                    )
                }
            }
            .navigationTitle(task == nil ? "New Task" : "Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(task == nil ? "Add" : "Save") {
                        saveTask()
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    private func saveTask() {
        if let existingTask = task {
            // Update existing task
            existingTask.title = title
            existingTask.taskDescription = taskDescription
            existingTask.iconName = iconName
            existingTask.category = selectedCategory
            existingTask.priority = selectedPriority
            existingTask.timeRemaining = timeRemaining
            existingTask.dueDate = dueDate
            try? modelContext.save()
            onSave(existingTask)
        } else {
            // Create new task
            let newTask = PolmodorTask(
                title: title,
                taskDescription: taskDescription,
                iconName: iconName,
                category: selectedCategory,
                priority: selectedPriority,
                timeRemaining: timeRemaining,
                dueDate: dueDate
            )
            modelContext.insert(newTask)
            try? modelContext.save()
            onSave(newTask)
        }
    }
}

private struct IconPicker: View {
    @Binding var selectedIcon: String

    private let icons = [
        "circle.fill",
        "star.fill",
        "flag.fill",
        "bell.fill",
        "calendar",
        "doc.fill",
        "pencil",
        "hammer.fill",
        "wrench.fill",
        "link",
        "person.fill",
        "house.fill",
        "cart.fill",
        "gift.fill",
        "airplane",
        "car.fill",
        "leaf.fill",
        "gamecontroller.fill",
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(icons, id: \.self) { icon in
                    Button {
                        selectedIcon = icon
                    } label: {
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundStyle(selectedIcon == icon ? .blue : .gray)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(selectedIcon == icon ? .blue.opacity(0.2) : .clear)
                            )
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}
