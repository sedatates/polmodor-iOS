import SwiftUI

struct AddTaskView: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject var taskViewModel: TaskViewModel
  @State private var title = ""
  @State private var description = ""
  @State private var category: TaskCategory = .work
  @State private var priority: TaskPriority = .medium
  @State private var iconName = "checkmark.circle.fill"
    @State private var subtasks: [PolmodorSubTask] = []
  @State private var showingSubtaskSheet = false
  @State private var newSubtaskTitle = ""
  @State private var selectedPomodoroCount = 1

  private var isValid: Bool {
    !title.isEmpty
  }

  var body: some View {
    NavigationView {
      Form {
        Section(header: Text("Task Details")) {
          TextField("Title", text: $title)
            .textInputAutocapitalization(.words)

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

          Picker("Category", selection: $category) {
            ForEach(TaskCategory.allCases.filter { $0 != .all }, id: \.self) { category in
              Label(
                category.rawValue.capitalized,
                systemImage: category.iconName
              )
              .foregroundColor(category.color)
              .tag(category)
            }
          }

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

          IconPicker(selectedIcon: $iconName)
        }

        Section(
          header: Text("Subtasks"),
          footer: Text("Add subtasks to break down your task into smaller, manageable pieces")
        ) {
          ForEach(subtasks) { subtask in
            HStack {
              Text(subtask.title)
              Spacer()
              Text("\(subtask.pomodoro.total) 🍅")
                .foregroundColor(.gray)
            }
          }
          .onDelete { indexSet in
            subtasks.remove(atOffsets: indexSet)
          }

          Button(action: { showingSubtaskSheet = true }) {
            Label("Add Subtask", systemImage: "plus.circle.fill")
          }
        }
      }
      .navigationTitle("New Task")
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
        NavigationView {
          Form {
            TextField("Subtask Title", text: $newSubtaskTitle)

            Stepper(
              "Pomodoros: \(selectedPomodoroCount)",
              value: $selectedPomodoroCount, in: 1...10
            )
          }
          .navigationTitle("Add Subtask")
          .navigationBarItems(
            leading: Button("Cancel") {
              showingSubtaskSheet = false
              newSubtaskTitle = ""
              selectedPomodoroCount = 1
            },
            trailing: Button("Add") {
              addSubtask()
              showingSubtaskSheet = false
              newSubtaskTitle = ""
              selectedPomodoroCount = 1
            }
            .disabled(newSubtaskTitle.isEmpty)
          )
        }
        .presentationDetents([.medium])
      }
    }
  }

  private func addSubtask() {
      let newSubtask = PolmodorSubTask(
      id: UUID(),
      title: newSubtaskTitle,
      completed: false,
      pomodoro: .init(total: selectedPomodoroCount, completed: 0)
    )
    subtasks.append(newSubtask)
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
      timeRemaining: Double(subtasks.reduce(0) { $0 + $1.pomodoro.total }) * 25,
      dueDate: Date().addingTimeInterval(86400 * 7),
      completed: false,
      isTimerRunning: false,
      subTasks: subtasks
    )

    taskViewModel.addTask(newTask)
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


