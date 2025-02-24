import SwiftUI

struct AddTaskView: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject var taskViewModel: TaskViewModel
  @State private var title = ""
  @State private var description = ""
  @State private var category: TaskCategory
  @State private var priority: TaskPriority = .medium
  @State private var iconName = "checkmark.circle.fill"
  @State private var subtasks: [PolmodorSubTask] = []
  @State private var showingSubtaskSheet = false
  @State private var newSubtaskTitle = ""
  @State private var selectedPomodoroCount = 1

  init() {
    let defaultCategory = TaskCategory.work
    _category = State(initialValue: defaultCategory)
  }

  private var isValid: Bool {
    !title.isEmpty
  }

  var body: some View {
    NavigationView {
      Form {
        taskDetailsSection
        subtasksSection
      }
      .navigationTitle("New Task")
      .navigationBarItems(
        leading: cancelButton,
        trailing: saveButton
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
  }

  private var taskDetailsSection: some View {
    Section(header: Text("Task Details")) {
      TextField("Title", text: $title)
        .textInputAutocapitalization(.words)

      TaskDescriptionEditor(description: $description)

      Picker("Category", selection: $category) {
        ForEach(taskViewModel.categories) { category in
          Label(category.name, systemImage: category.iconName)
            .foregroundColor(category.color)
            .tag(category)
        }
      }

      PriorityPicker(priority: $priority)

      IconPicker(selectedIcon: $iconName)
    }
  }

  private var subtasksSection: some View {
    Section(
      header: Text("Subtasks"),
      footer: Text("Add subtasks to break down your task into smaller, manageable pieces")
    ) {
      ForEach(subtasks) { subtask in
        SubtaskRow(subtask: subtask)
      }
      .onDelete { indexSet in
        subtasks.remove(atOffsets: indexSet)
      }

      Button(action: { showingSubtaskSheet = true }) {
        Label("Add Subtask", systemImage: "plus.circle.fill")
      }
    }
  }

  private var cancelButton: some View {
    Button("Cancel") {
      dismiss()
    }
  }

  private var saveButton: some View {
    Button("Save") {
      saveTask()
      dismiss()
    }
    .disabled(!isValid)
  }

  private func addSubtask() {
    let newSubtask = PolmodorSubTask(
      title: newSubtaskTitle,
      pomodoro: .init(total: selectedPomodoroCount, completed: 0)
    )
    subtasks.append(newSubtask)
    newSubtaskTitle = ""
    selectedPomodoroCount = 1
  }

  private func saveTask() {
    let newTask = PolmodorTask(
      id: UUID(),
      title: title,
      description: description,
      iconName: iconName,
      category: category,
      priority: priority,
      timeSpent: 0,
      timeRemaining: Double(subtasks.reduce(0) { $0 + $1.pomodoro.total }) * 25 * 60,
      dueDate: Date().addingTimeInterval(86400 * 7),
      completed: false,
      isTimerRunning: false,
      subTasks: subtasks,
      createdAt: Date(),
      completedAt: nil,
      status: .todo,
      completedPomodoros: 0
    )
    taskViewModel.addTask(newTask)
  }
}

// MARK: - Supporting Views

private struct TaskDescriptionEditor: View {
  @Binding var description: String

  var body: some View {
    TextEditor(text: $description)
      .frame(height: 100)
      .overlay(
        Group {
          if description.isEmpty {
            Text("Description (optional)")
              .foregroundColor(.gray)
              .padding(.leading, 4)
              .padding(.top, 8)
          }
        },
        alignment: .topLeading
      )
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

private struct PriorityPicker: View {
  @Binding var priority: TaskPriority

  var body: some View {
    Picker("Priority", selection: $priority) {
      ForEach(TaskPriority.allCases, id: \.self) { priority in
        Label(
          priority.rawValue.capitalized,
          systemImage: priority.iconName
        )
        .foregroundColor(priority.color)
        .tag(priority)
      }
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
  AddTaskView()
    .environmentObject(TaskViewModel())
}
