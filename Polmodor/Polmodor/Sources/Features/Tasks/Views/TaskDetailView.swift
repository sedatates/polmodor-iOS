import SwiftUI

struct TaskDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var task: PolmodorTask
    private let onUpdate: (PolmodorTask) -> Void
    
    init(task: PolmodorTask, onUpdate: @escaping (PolmodorTask) -> Void) {
        _task = State(initialValue: task)
        self.onUpdate = onUpdate
    }
    
    var body: some View {
        Form {
            Section {
                TextField("Title", text: $task.title)
                TextEditor(text: $task.description)
                    .frame(minHeight: 100)
            }
            
            Section("Pomodoros") {
                Stepper("Count: \(task.pomodoroCount)", value: $task.pomodoroCount, in: 1...10)
                Stepper("Completed: \(task.completedPomodoros)", value: $task.completedPomodoros, in: 0...task.pomodoroCount)
                
                ProgressView(value: task.progress)
                    .tint(task.status == .completed ? .green : .accentColor)
            }
            
            Section {
                Picker("Status", selection: $task.status) {
                    ForEach(PolmodorTask.TaskStatus.allCases, id: \.self) { status in
                        Label(status.rawValue, systemImage: status.systemImage)
                            .tag(status)
                    }
                }
            }
            
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Created")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(task.createdAt.formatted())
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last Updated")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(task.updatedAt.formatted())
                }
            }
        }
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    onUpdate(task)
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        TaskDetailView(
            task: PolmodorTask(
                title: "Sample Task",
                description: "This is a sample task description",
                pomodoroCount: 4,
                completedPomodoros: 2
            )
        ) { _ in }
    }
} 