import SwiftData
import SwiftUI

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
            // Status Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
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

                    ForEach(Array(TaskStatus.allCases.enumerated()), id: \.element) {
                        index, status in
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
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.05))
                    .padding(.horizontal, 8)
            )
            .padding(.top, 8)

            // Category Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
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
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.05))
                    .padding(.horizontal, 8)
            )
            .padding(.vertical, 4)

            Divider()
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

            // Task List
            List {
                if filteredTasks.isEmpty {
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
                } else {
                    ForEach(filteredTasks) { task in
                        TaskRowView(task: task)
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
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
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
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let iconName: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    var count: Int? = nil

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: iconName)
                    .font(.system(size: 12, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)

                Text(title)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium))

                if let count = count, count > 0 {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? color : Color.secondary.opacity(0.3))
                        )
                        .foregroundColor(isSelected ? .white : .primary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? color.opacity(0.2) : Color.secondary.opacity(0.1))
            )
            .foregroundColor(isSelected ? color : .primary)
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? color : Color.clear, lineWidth: 1)
            )
            .shadow(color: isSelected ? color.opacity(0.3) : .clear, radius: 3, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Capsule())
    }
}

// MARK: - Task Row View
private struct TaskRowView: View {
    let task: PolmodorTask
    @State private var isExpanded = false
    @State private var showAddSubtask = false
    @Namespace private var animation
    @Environment(\.colorScheme) private var colorScheme

    // Animation properties
    @State private var cardHeight: CGFloat = 0
    @State private var subtaskOpacity: Double = 0

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.15) : Color.white
    }

    private var accentColor: Color {
        task.category?.color ?? .blue
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main task card
            VStack(spacing: 0) {
                // Task header
                HStack(alignment: .center, spacing: 12) {
                    // Task icon with category color
                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(0.15))
                            .frame(width: 36, height: 36)

                        Image(systemName: task.iconName)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(accentColor)
                            .symbolRenderingMode(.hierarchical)
                    }

                    // Task content
                    VStack(alignment: .leading, spacing: 4) {
                        // Title row
                        Text(task.title)
                            .font(.headline)
                            .strikethrough(task.completed)
                            .foregroundStyle(task.completed ? .secondary : .primary)
                            .lineLimit(1)

                        // Description if available
                        if !task.taskDescription.isEmpty {
                            Text(task.taskDescription)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(isExpanded ? 3 : 1)
                                .animation(.easeInOut, value: isExpanded)
                        }
                    }

                    Spacer()

                    // Status indicators
                    HStack(spacing: 8) {
                        if task.completed {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .symbolRenderingMode(.hierarchical)
                                .font(.system(size: 18))
                        } else if task.isTimerRunning {
                            Image(systemName: "timer.circle.fill")
                                .foregroundStyle(.orange)
                                .symbolRenderingMode(.hierarchical)
                                .font(.system(size: 18))
                                .symbolEffect(.pulse, options: .repeating)
                        }

                        // Dropdown indicator
                        ZStack {
                            Circle()
                                .fill(Color.secondary.opacity(0.15))
                                .frame(width: 28, height: 28)

                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.secondary)
                                .rotationEffect(isExpanded ? .degrees(180) : .degrees(0))
                        }
                        .contentShape(Circle())
                        .onTapGesture {
                            withAnimation(
                                .spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.3)
                            ) {
                                isExpanded.toggle()
                                subtaskOpacity = isExpanded ? 1 : 0
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)

                // Metadata row
                HStack(spacing: 12) {
                    // Pomodoro count
                    HStack(spacing: 6) {
                        Image(systemName: "timer")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)

                        Text("\(task.completedPomodoros)")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Capsule())

                    // Due date if not completed
                    if !task.completed {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 12))
                                .foregroundStyle(isDueSoon(task.dueDate) ? .red : .secondary)

                            Text(formatDueDate(task.dueDate))
                                .font(.caption.weight(.medium))
                                .foregroundStyle(isDueSoon(task.dueDate) ? .red : .secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Capsule())
                    }

                    Spacer()

                    // Category tag
                    if let category = task.category {
                        Text(category.name)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(category.color.opacity(0.15))
                            .foregroundStyle(category.color)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)

                // Subtask progress indicator
                if !task.subTasks.isEmpty {
                    SubtaskProgressView(task: task)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }

                // Divider that appears when expanded
                if isExpanded {
                    Divider()
                        .padding(.horizontal, 16)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Subtasks section (expanded)
                if isExpanded {
                    VStack(spacing: 0) {
                        if task.subTasks.isEmpty {
                            // Empty state
                            VStack(spacing: 16) {
                                Image(systemName: "checklist")
                                    .font(.system(size: 36))
                                    .foregroundStyle(Color.secondary.opacity(0.3))
                                    .symbolRenderingMode(.hierarchical)
                                    .padding(.top, 16)

                                Text("Henüz subtask yok")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(Color.secondary)

                                Button(action: {
                                    showAddSubtask = true
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 16))
                                        Text("Subtask Ekle")
                                            .font(.subheadline.weight(.semibold))
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(
                                        Capsule()
                                            .fill(accentColor.opacity(0.15))
                                    )
                                    .foregroundStyle(accentColor)
                                }
                                .buttonStyle(ScaleButtonStyle())
                                .padding(.bottom, 16)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        } else {
                            // Subtask list
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Alt Görevler")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 16)
                                    .padding(.horizontal, 16)

                                ForEach(task.subTasks) { subtask in
                                    SubtaskRowView(subtask: subtask)
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                                .padding(.horizontal, 16)

                                HStack {
                                    Button(action: {
                                        showAddSubtask = true
                                    }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 14))
                                            Text("Yeni Subtask")
                                                .font(.subheadline.weight(.medium))
                                        }
                                        .foregroundStyle(accentColor)
                                    }
                                    .buttonStyle(ScaleButtonStyle())

                                    Spacer()

                                    NavigationLink(destination: TaskDetailView(task: task)) {
                                        HStack(spacing: 6) {
                                            Text("Tüm Detaylar")
                                                .font(.subheadline.weight(.medium))
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 12))
                                        }
                                        .foregroundStyle(accentColor)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                            }
                        }
                    }
                    .opacity(subtaskOpacity)
                    .animation(
                        .easeInOut(duration: 0.3).delay(isExpanded ? 0.1 : 0), value: isExpanded)
                }
            }
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.07), radius: 8, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.secondary.opacity(0.1), lineWidth: 1)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.3)) {
                    isExpanded.toggle()
                    subtaskOpacity = isExpanded ? 1 : 0
                }
            }
        }
        .padding(.vertical, 6)
        .sheet(isPresented: $showAddSubtask) {
            AddSubtaskView(task: task)
                .presentationDetents([.medium])
        }
        .contextMenu {
            NavigationLink(destination: TaskDetailView(task: task)) {
                Label("Detayları Görüntüle", systemImage: "info.circle")
            }

            if !task.completed {
                Button {
                    // Mark as completed logic
                } label: {
                    Label("Tamamlandı Olarak İşaretle", systemImage: "checkmark.circle")
                }
            }

            Button(role: .destructive) {
                // Delete task logic
            } label: {
                Label("Sil", systemImage: "trash")
            }
        }
    }

    private func formatDueDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func isDueSoon(_ date: Date) -> Bool {
        return date < Date().addingTimeInterval(24 * 60 * 60)  // 24 hours
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

// MARK: - Subtask Progress View
private struct SubtaskProgressView: View {
    let task: PolmodorTask

    private var completedCount: Int {
        task.subTasks.filter { $0.completed }.count
    }

    private var totalCount: Int {
        task.subTasks.count
    }

    private var progress: Double {
        totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("İlerleme")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(completedCount)/\(totalCount)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            // Dot-based progress indicator with animation
            HStack(spacing: 6) {
                ForEach(0..<min(totalCount, 10), id: \.self) { index in
                    Circle()
                        .fill(
                            index < completedCount
                                ? .green
                                : Color.secondary.opacity(0.2)
                        )
                        .frame(width: 8, height: 8)
                        .animation(
                            .spring(response: 0.3, dampingFraction: 0.7), value: completedCount
                        )
                        .scaleEffect(index < completedCount ? 1.2 : 1.0)
                        .animation(
                            .spring(response: 0.3, dampingFraction: 0.7), value: completedCount)
                }

                // If there are more than 10 subtasks, show a "+X more" indicator
                if totalCount > 10 {
                    Text("+\(totalCount - 10)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                }

                Spacer()
            }
        }
    }
}

// MARK: - Subtask Row View
private struct SubtaskRowView: View {
    let subtask: PolmodorSubTask
    @Environment(\.colorScheme) private var colorScheme

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.2) : Color(white: 0.97)
    }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                // Toggle completion logic
            }) {
                ZStack {
                    Circle()
                        .stroke(
                            subtask.completed ? Color.green : Color.secondary.opacity(0.3),
                            lineWidth: 1.5
                        )
                        .frame(width: 22, height: 22)

                    if subtask.completed {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())

            VStack(alignment: .leading, spacing: 4) {
                Text(subtask.title)
                    .font(.subheadline.weight(subtask.completed ? .regular : .medium))
                    .strikethrough(subtask.completed)
                    .foregroundStyle(subtask.completed ? .secondary : .primary)

                // Add creation date or other metadata if available
                if subtask.completed {
                    Text("Tamamlandı")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            Spacer()

            if subtask.completed {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
                    .background(Circle().fill(Color.green))
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.secondary.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Add Subtask View
private struct AddSubtaskView: View {
    let task: PolmodorTask
    @State private var subtaskTitle = ""
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.15) : Color.white
    }

    private var accentColor: Color {
        task.category?.color ?? .blue
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Task info card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Ana Görev")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(accentColor.opacity(0.15))
                                .frame(width: 36, height: 36)

                            Image(systemName: task.iconName)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(accentColor)
                                .symbolRenderingMode(.hierarchical)
                        }

                        Text(task.title)
                            .font(.headline)
                            .lineLimit(2)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)

                // Subtask input
                VStack(alignment: .leading, spacing: 12) {
                    Text("Subtask Başlığı")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    TextField("Subtask için başlık girin", text: $subtaskTitle)
                        .font(.body.weight(.medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.secondary.opacity(0.07))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)

                Spacer()

                Button("Subtask Ekle") {
                    addSubtask()
                }
                .disabled(subtaskTitle.isEmpty)
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(subtaskTitle.isEmpty ? Color.secondary.opacity(0.3) : accentColor)
                )
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
            .padding(.top, 16)
            .navigationTitle("Yeni Subtask")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func addSubtask() {
        // Add subtask logic
        dismiss()
    }
}

#Preview {
    NavigationStack {
        TaskListView()
    }
    .modelContainer(PreviewContainer.container)
}
