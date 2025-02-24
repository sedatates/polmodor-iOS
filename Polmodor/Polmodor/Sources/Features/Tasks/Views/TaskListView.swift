import SwiftUI

struct TaskListView: View {
    @EnvironmentObject var taskViewModel: TaskViewModel
    @State private var searchText = ""
    @State private var selectedCategory: TaskCategory = .all
    @Environment(\.colorScheme) var colorScheme
    @State private var showingAddTask = false

    var body: some View {
        VStack(spacing: 0) {
            // Category Filter
            CategoryFilterView(selectedCategory: $selectedCategory)
                .padding(.horizontal)

            // Search Bar
            SearchBar(text: $searchText)
                .padding()

            // Task List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(
                        taskViewModel.filteredTasks(
                            searchText: searchText, category: selectedCategory)
                    ) { task in
                        TaskCardView(task: task, viewModel: taskViewModel)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Tasks")
        .navigationBarItems(
            trailing: Button(action: { showingAddTask = true }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
            }
        )
        .sheet(isPresented: $showingAddTask) {
            AddTaskView()
                .environmentObject(taskViewModel)
        }
    }
}

// MARK: - Supporting Views
private struct CategoryFilterView: View {
    @Binding var selectedCategory: TaskCategory

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TaskCategory.allCases, id: \.self) { category in
                    CategoryButton(
                        title: category.rawValue.capitalized,
                        isSelected: selectedCategory == category,
                        color: category.color
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}

private struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? color : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

private struct SearchBar: View {
    @Binding var text: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField("Search tasks...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

private struct TaskCardView: View {
    let task: PolmodorTask
    let viewModel: TaskViewModel
    @State private var isExpanded = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Task Header
            HStack {
                Image(systemName: task.iconName)
                    .foregroundColor(task.categoryColor)
                    .font(.title3)

                Text(task.title)
                    .font(.headline)

                Spacer()

                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.spring(), value: isExpanded)
                }
            }

            // Task Info
            HStack {
                PriorityBadge(priority: task.priority)
                Spacer()
                ProgressView(value: task.progress)
                    .frame(width: 100)
                Text("\(Int(task.progress * 100))%")
                    .font(.caption)
            }

            // Subtasks (if expanded)
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(task.subTasks) { subtask in
                        SubtaskRow(subtask: subtask, viewModel: viewModel)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1),
            radius: 5, x: 0, y: 2)
    }
}

private struct SubtaskRow: View {
    let subtask: PolmodorSubTask
    let viewModel: TaskViewModel

    var body: some View {
        HStack {
            Button(action: { viewModel.toggleSubtaskCompletion(subtask) }) {
                Image(systemName: subtask.completed ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(subtask.completed ? .green : .gray)
            }

            Text(subtask.title)
                .strikethrough(subtask.completed)

            Spacer()

            Text("\(subtask.pomodoro.completed)/\(subtask.pomodoro.total)")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

private struct PriorityBadge: View {
    let priority: TaskPriority

    var body: some View {
        Text(priority.rawValue.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(priority.color.opacity(0.2))
            .foregroundColor(priority.color)
            .cornerRadius(6)
    }
}

#Preview {
    NavigationView {
        TaskListView()
    }
}
