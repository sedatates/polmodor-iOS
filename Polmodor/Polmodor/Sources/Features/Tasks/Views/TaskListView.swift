import SwiftData
import SwiftUI

// Mark: - TaskListView

struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PolmodorTask.createdAt, order: .reverse) private var tasks: [PolmodorTask]
    @Query(sort: \TaskCategory.name) private var categories: [TaskCategory]

    @State private var selectedFilter: TaskStatus?
    @State private var selectedCategory: TaskCategory?
    @State private var searchText = ""
    @State private var showAddTask = false
    @State private var animateFilters = false

    private var filteredTasks: [PolmodorTask] {
        tasks.filter { task in
            let matchesSearch =
                searchText.isEmpty || task.title.localizedCaseInsensitiveContains(searchText)
                || task.taskDescription.localizedCaseInsensitiveContains(searchText)

            let matchesFilter = selectedFilter == nil || task.status == selectedFilter

            let matchesCategory =
                selectedCategory == nil || task.category?.id == selectedCategory?.id

            return matchesSearch && matchesFilter && matchesCategory
        }
    }

    // Count tasks by status
    private func taskCount(for status: TaskStatus?) -> Int {
        if let status = status {
            return tasks.filter { $0.status == status }.count
        } else {
            return tasks.count
        }
    }

    // Count tasks by category
    private func taskCount(for category: TaskCategory?) -> Int {
        if let category = category {
            return tasks.filter { $0.category?.id == category.id }.count
        } else {
            return tasks.count
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            statusFilterView
            categoryFilterView
            Divider()
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            taskListView
        }
        .navigationTitle("Tasks")
        .navigationBarTitleDisplayMode(.large)

        .searchable(text: $searchText, prompt: "Search tasks")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showAddTask = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Color(hex: "4CAF50"))
                }
            }
        }
        .sheet(isPresented: $showAddTask) {
            NavigationStack {
                AddTaskView()
            }
            .presentationDetents([.large])
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                animateFilters = true
            }
        }
        .withFloatingTabBarPadding()
    }

    // MARK: - Subviews

    private var statusFilterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                allTasksFilterChip
                statusFilterChips
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.05))
                .padding(.horizontal, 8)
        )
        .padding(.top, 8)
    }

    private var allTasksFilterChip: some View {
        FilterChip(
            title: "All",
            iconName: "list.bullet",
            color: .gray,
            isSelected: selectedFilter == nil,
            action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedFilter = nil
                }
            },
            count: taskCount(for: nil as TaskStatus?)
        )
        .offset(y: animateFilters ? 0 : 20)
        .opacity(animateFilters ? 1 : 0)
    }

    private var statusFilterChips: some View {
        ForEach(Array(TaskStatus.allCases.enumerated()), id: \.element) { index, status in
            FilterChip(
                title: status.displayName,
                iconName: status.iconName,
                color: status.color,
                isSelected: selectedFilter == status,
                action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedFilter = status
                    }
                },
                count: taskCount(for: status)
            )
            .offset(y: animateFilters ? 0 : 20)
            .opacity(animateFilters ? 1 : 0)
            .animation(
                .spring(response: 0.3, dampingFraction: 0.7).delay(
                    Double(index) * 0.05), value: animateFilters)
        }
    }

    private var categoryFilterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                allCategoriesFilterChip
                categoryFilterChips
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.05))
                .padding(.horizontal, 8)
        )
        .padding(.vertical, 4)
    }

    private var allCategoriesFilterChip: some View {
        FilterChip(
            title: "All Categories",
            iconName: "folder",
            color: .orange,
            isSelected: selectedCategory == nil,
            action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedCategory = nil
                }
            },
            count: taskCount(for: nil as TaskCategory?)
        )
        .offset(y: animateFilters ? 0 : 20)
        .opacity(animateFilters ? 1 : 0)
        .animation(
            .spring(response: 0.3, dampingFraction: 0.7).delay(0.1),
            value: animateFilters)
    }

    private var categoryFilterChips: some View {
        ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
            FilterChip(
                title: category.name,
                iconName: category.iconName,
                color: category.color,
                isSelected: selectedCategory?.id == category.id,
                action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedCategory = category
                    }
                },
                count: taskCount(for: category)
            )
            .offset(y: animateFilters ? 0 : 20)
            .opacity(animateFilters ? 1 : 0)
            .animation(
                .spring(response: 0.3, dampingFraction: 0.7).delay(
                    0.1 + Double(index) * 0.05), value: animateFilters)
        }
    }

    private var taskListView: some View {
        ScrollView {
            if filteredTasks.isEmpty {
                emptyTasksView
            } else {
                taskListContent
            }
        }
        .scrollIndicators(.hidden)
        .padding(.horizontal, 16)
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var emptyTasksView: some View {
        ContentUnavailableView {
            Label("No Tasks", systemImage: "list.bullet.clipboard")
        } description: {
            Text("Add a new task or change your filters")
        } actions: {
            Button("Add Task") {
                showAddTask = true
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: "4CAF50"))
        }
        .frame(maxWidth: .infinity)
        .listRowBackground(Color.clear)
        .padding(.top, 40)
    }

    private var taskListContent: some View {
        ForEach(filteredTasks) { task in
            PolmodorTaskRow(task: task)
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        withAnimation {
                            modelContext.delete(task)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }

                    if !task.completed {
                        Button {
                            withAnimation {
                                task.completed = true
                                task.completedAt = Date()
                            }
                        } label: {
                            Label("Complete", systemImage: "checkmark")
                        }
                        .tint(.green)
                    }
                }
        }
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct TaskListView_Previews: PreviewProvider {
    private let modelContainer2 = ModelContainerSetup.setupModelContainer()

    static var previews: some View {
        NavigationStack {
            TaskListView()

        }
        .modelContainer(ModelContainerSetup.setupModelContainer())
    }
}
