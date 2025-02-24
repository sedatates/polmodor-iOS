import SwiftUI

struct TaskListView: View {
    @EnvironmentObject var taskViewModel: TaskViewModel
    @State private var searchText = ""
    @State private var selectedCategory: TaskCategory = .all
    @Environment(\.colorScheme) var colorScheme
    @State private var showingAddTask = false
    @State private var showingTaskStats = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Stats Card
                TaskStatsCard(viewModel: taskViewModel)
                    .padding(.horizontal)

                // Category Filter
                CategoryFilterView(selectedCategory: $selectedCategory)
                    .padding(.horizontal)

                // Search Bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)

                // Tasks List
                LazyVStack(spacing: 12) {
                    ForEach(
                        taskViewModel.filteredTasks(
                            searchText: searchText,
                            category: selectedCategory
                        )
                    ) { task in
                        NavigationLink(destination: TaskDetailView(task: task)) {
                            TaskCardView(task: task, viewModel: taskViewModel)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Tasks")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddTask = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.tint)
                }
            }
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView()
                .environmentObject(taskViewModel)
        }
    }
}

// MARK: - Supporting Views
private struct TaskStatsCard: View {
    let viewModel: TaskViewModel

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Today's Progress")
                        .font(.headline)
                    Text("\(viewModel.completedTasksCount) of \(viewModel.totalTasksCount) tasks")
                        .foregroundColor(.secondary)
                }
                Spacer()
                CircularProgressView(progress: viewModel.completionRate)
                    .frame(width: 44, height: 44)
            }

            Divider()

            HStack(spacing: 24) {
                StatView(
                    icon: "checkmark.circle.fill",
                    color: .green,
                    value: "\(viewModel.completedTasksCount)",
                    title: "Completed"
                )

                StatView(
                    icon: "clock.fill",
                    color: .orange,
                    value: "\(viewModel.totalPomodorosCompleted)",
                    title: "Pomodoros"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

private struct StatView: View {
    let icon: String
    let color: Color
    let value: String
    let title: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(value)
                    .font(.headline)
            }
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

private struct CircularProgressView: View {
    let progress: Double

    var body: some View {
        Circle()
            .trim(from: 0, to: progress)
            .stroke(
                Color.accentColor,
                style: StrokeStyle(
                    lineWidth: 4,
                    lineCap: .round
                )
            )
            .rotationEffect(.degrees(-90))
            .overlay(
                Text("\(Int(progress * 100))%")
                    .font(.caption2)
                    .fontWeight(.medium)
            )
    }
}

private struct CategoryFilterView: View {
    @Binding var selectedCategory: TaskCategory
    @State private var showingAddCategory = false
    @EnvironmentObject var taskViewModel: TaskViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(taskViewModel.categories) { category in
                    CategoryButton(
                        title: category.name,
                        icon: category.iconName,
                        isSelected: selectedCategory.id == category.id,
                        color: category.color
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategory = category
                        }
                    }
                }

                Button(action: { showingAddCategory = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Category")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .cornerRadius(20)
                }
            }
            .padding(.vertical, 8)
        }
        .sheet(isPresented: $showingAddCategory) {
            AddCategorySheet(isPresented: $showingAddCategory)
                .environmentObject(taskViewModel)
        }
    }
}

private struct AddCategorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var taskViewModel: TaskViewModel
    @Binding var isPresented: Bool

    @State private var categoryName = ""
    @State private var selectedIcon = "tag.fill"
    @State private var selectedColor: Color = .blue

    private let icons = [
        "tag.fill",
        "folder.fill",
        "star.fill",
        "flag.fill",
        "bell.fill",
        "calendar",
        "doc.fill",
        "pencil",
        "paintbrush.fill",
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

    private let colors: [Color] = [
        .blue,
        .green,
        .red,
        .orange,
        .yellow,
        .purple,
        .pink,
        Color(hex: "4A90E2"),
        Color(hex: "50E3C2"),
        Color(hex: "FF5964"),
        Color(hex: "F7B267"),
        Color(hex: "A8E6CF"),
        Color(hex: "FFD3B6"),
        Color(hex: "FF8B94"),
        Color.timerColors.workStart,
        Color.timerColors.shortBreakStart,
        Color.timerColors.longBreakStart,
    ]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Category Details")) {
                    TextField("Category Name", text: $categoryName)
                        .textInputAutocapitalization(.words)
                }

                Section(header: Text("Icon")) {
                    LazyVGrid(
                        columns: [
                            GridItem(.adaptive(minimum: 44), spacing: 12)
                        ], spacing: 12
                    ) {
                        ForEach(icons, id: \.self) { icon in
                            IconSelectionButton(
                                icon: icon,
                                isSelected: selectedIcon == icon,
                                color: selectedColor
                            ) {
                                selectedIcon = icon
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section(header: Text("Color")) {
                    LazyVGrid(
                        columns: [
                            GridItem(.adaptive(minimum: 44), spacing: 12)
                        ], spacing: 12
                    ) {
                        ForEach(colors, id: \.self) { color in
                            ColorSelectionButton(
                                color: color,
                                isSelected: selectedColor == color
                            ) {
                                selectedColor = color
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("New Category")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Add") {
                    addCategory()
                    dismiss()
                }
                .disabled(categoryName.isEmpty)
            )
        }
    }

    private func addCategory() {
        let newCategory = TaskCategory(
            id: UUID(),
            name: categoryName,
            iconName: selectedIcon,
            color: selectedColor
        )
        taskViewModel.addCategory(newCategory)
    }
}

private struct IconSelectionButton: View {
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isSelected ? color : Color(.systemGray6))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : .primary)
            }
        }
    }
}

private struct ColorSelectionButton: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 44, height: 44)

                if isSelected {
                    Circle()
                        .strokeBorder(Color.white, lineWidth: 2)
                        .frame(width: 44, height: 44)
                }
            }
        }
    }
}

private struct CategoryButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
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
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

private struct TaskCardView: View {
    let task: PolmodorTask
    let viewModel: TaskViewModel
    @State private var isExpanded = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Task Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: task.iconName)
                            .foregroundColor(task.categoryColor)
                            .font(.title3)

                        Text(task.title)
                            .font(.headline)
                    }

                    if !task.description.isEmpty {
                        Text(task.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .foregroundColor(.secondary)
                }
            }

            // Task Progress
            VStack(spacing: 12) {
                HStack {
                    PriorityBadge(priority: task.priority)
                    Spacer()
                    Label(
                        "\(task.completedPomodoros) completed",
                        systemImage: "timer"
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                ProgressBar(value: task.progress)
            }

            // Subtasks
            if isExpanded && !task.subTasks.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Subtasks")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    ForEach(task.subTasks) { subtask in
                        SubtaskRow(subtask: subtask, viewModel: viewModel)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

private struct ProgressBar: View {
    let value: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color(.systemGray5))

                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: geometry.size.width * value)
            }
        }
        .frame(height: 8)
        .cornerRadius(4)
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

            VStack(alignment: .leading, spacing: 4) {
                Text(subtask.title)
                    .strikethrough(subtask.completed)

                HStack(spacing: 8) {
                    ForEach(0..<subtask.pomodoro.total, id: \.self) { index in
                        Image(systemName: "circle.fill")
                            .foregroundColor(index < subtask.pomodoro.completed ? .red : .gray)
                            .font(.caption2)
                    }
                }
            }

            Spacer()

            Text("\(subtask.pomodoro.completed)/\(subtask.pomodoro.total)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

private struct PriorityBadge: View {
    let priority: TaskPriority

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: priority.iconName)
            Text(priority.rawValue.capitalized)
        }
        .font(.caption)
        .fontWeight(.medium)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(priority.color.opacity(0.2))
        .foregroundColor(priority.color)
        .cornerRadius(8)
    }
}

#Preview {
    NavigationStack {
        TaskListView()
            .environmentObject(TaskViewModel())
    }
}
