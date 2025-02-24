import SwiftUI

struct TaskDetailView: View {
    @EnvironmentObject var taskViewModel: TaskViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var task: PolmodorTask
    @State private var isEditing = false
    
    init(task: PolmodorTask) {
        _task = State(initialValue: task)
    }
    
    var body: some View {
        List {
            
            HStack {
                Image(systemName: task.iconName)
                    .foregroundColor(task.categoryColor)
                Text(task.title)
                    .font(.headline)
            }
            
            if !task.description.isEmpty {
                Text(task.description)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Label("Category", systemImage: task.category.iconName)
                Spacer()
                Text(task.category.rawValue.capitalized)
                    .foregroundColor(task.categoryColor)
            }
            
            HStack {
                Label("Priority", systemImage: task.iconName)
                Spacer()
                Text(task.priority.rawValue.capitalized)
                    .foregroundColor(task.priority.color)
            }
            
            if !task.subTasks.isEmpty {
                HStack {
                    Label("Progress", systemImage: "chart.pie.fill")
                    Spacer()
                    Text("\(Int(task.progress * 100))%")
                }
            }
            
            
            if !task.subTasks.isEmpty {
                Section(header: Text("Subtasks")) {
                    ForEach(task.subTasks) { subtask in
                        HStack {
                            Button(action: { taskViewModel.toggleSubtaskCompletion(subtask) }) {
                                Image(
                                    systemName: subtask.completed
                                    ? "checkmark.circle.fill" : "circle"
                                )
                                .foregroundColor(subtask.completed ? .green : .gray)
                            }
                            
                            VStack(alignment: .leading) {
                                Text(subtask.title)
                                    .strikethrough(subtask.completed)
                                Text(
                                    "\(subtask.pomodoro.completed)/\(subtask.pomodoro.total) Pomodoros"
                                )
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            
            Section(header: Text("Time Management")) {
                HStack {
                    Label("Time Spent", systemImage: "clock")
                    Spacer()
                    Text(formatTime(task.timeSpent))
                }
                
                HStack {
                    Label("Time Remaining", systemImage: "timer")
                    Spacer()
                    Text(formatTime(task.timeRemaining))
                }
                
                if let completedAt = task.completedAt {
                    HStack {
                        Label("Completed", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Spacer()
                        Text(formatDate(completedAt))
                    }
                }
            }
        }
        .navigationTitle("Task Details")
        .navigationBarItems(
            trailing: Button("Edit") {
                isEditing = true
            }
        )
        .sheet(isPresented: $isEditing) {
            TaskFormView(task: task) { updatedTask in
                taskViewModel.updateTask(updatedTask)
                task = updatedTask
                isEditing = false
            }
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) / 60 % 60
        return String(format: "%dh %dm", hours, minutes)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationView {
        TaskDetailView(
            task: PolmodorTask(
                title: "Sample Task",
                description: "This is a sample task for preview",
                iconName: "star.fill",
                category: .work,
                priority: .high,
                timeSpent: 3600,
                timeRemaining: 7200,
                subTasks: [
                    PolmodorSubTask(
                        id: UUID(),
                        title: "Subtask 1",
                        completed: true,
                        pomodoro: .init(total: 2, completed: 1)
                    ),
                    PolmodorSubTask(
                        id: UUID(),
                        title: "Subtask 2",
                        completed: false,
                        pomodoro: .init(total: 3, completed: 0)
                    ),
                ]
            ))
    }
}
