import SwiftData
import SwiftUI

struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PolmodorTask.createdAt, order: .reverse) private var tasks: [PolmodorTask]
    @Query(sort: \TaskCategory.name) private var categories: [TaskCategory]

    @State private var selectedFilter: TaskStatus?
    @State private var searchText = ""
    @State private var showAddTask = false

    private var filteredTasks: [PolmodorTask] {
        tasks.filter { task in
            let matchesSearch =
                searchText.isEmpty || task.title.localizedCaseInsensitiveContains(searchText)
                || task.taskDescription.localizedCaseInsensitiveContains(searchText)

            let matchesFilter = selectedFilter == nil || task.status == selectedFilter

            return matchesSearch && matchesFilter
        }
    }

    var body: some View {
        List {
            ForEach(filteredTasks) { task in
                TaskRowView(task: task)
            }
            .onDelete(perform: deleteTasks)
        }
        .navigationTitle("Tasks")
        .searchable(text: $searchText, prompt: "Search tasks")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddTask = true }) {
                    Image(systemName: "plus")
                }
            }

            ToolbarItem(placement: .navigationBarLeading) {
                Menu {
                    Button(action: { selectedFilter = nil }) {
                        Label("All Tasks", systemImage: "list.bullet")
                    }

                    Divider()

                    ForEach(TaskStatus.allCases, id: \.self) { status in
                        Button(action: { selectedFilter = status }) {
                            Label(status.displayName, systemImage: status.iconName)
                        }
                    }
                } label: {
                    Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .sheet(isPresented: $showAddTask) {
            NavigationStack {
                AddTaskView()
            }
            .presentationDetents([.large])
        }
    }

    private func deleteTasks(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredTasks[index])
        }
    }
}

private struct TaskRowView: View {
    let task: PolmodorTask

    var body: some View {
        NavigationLink(destination: TaskDetailView(task: task)) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: task.iconName)
                        .foregroundStyle(task.category?.color ?? .gray)

                    Text(task.title)
                        .font(.headline)

                    Spacer()

                    if task.completed {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }

                if !task.taskDescription.isEmpty {
                    Text(task.taskDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack {
                    Label("\(task.completedPomodoros)", systemImage: "timer")
                        .font(.caption)

                    Spacer()

                    if let category = task.category {
                        Text(category.name)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(category.color.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    NavigationStack {
        TaskListView()
    }
    .modelContainer(PreviewContainer.container)
}
