import SwiftData
import SwiftUI

// Mark: - TaskListView

struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PolmodorTask.createdAt, order: .reverse) private var tasks: [PolmodorTask]
    @Query(sort: \TaskCategory.name) private var allCategories: [TaskCategory]
    
    // Remove duplicate categories based on unique ID
    private var categories: [TaskCategory] {
        var uniqueCategories: [TaskCategory] = []
        var seenIds = Set<UUID>()
        
        for category in allCategories {
            if !seenIds.contains(category.id) {
                uniqueCategories.append(category)
                seenIds.insert(category.id)
            }
        }
        
        return uniqueCategories.sorted { $0.name < $1.name }
    }

    @State private var selectedFilter: TaskStatus?
    @State private var selectedCategory: TaskCategory?
    @State private var searchText = ""
    @State private var showAddTask = false
    @State private var scrollOffset: CGFloat = 0
    @State private var lastScrollOffset: CGFloat = 0
    @State private var showFilters = true

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
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // Main Content
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack {
                            // Header spacing to prevent overlap
                            Color.clear
                                .frame(height: 120)
                                .id("headerSpacer")
                            
                            // Filter section with animated hiding
                            if showFilters {
                                VStack(spacing: 16) {
                                    statusFilterSection
                                    categoryFilterSection
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                                .padding(.bottom, 8)
                                .background(
                                    Color(.systemBackground)
                                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                                )
                                .transition(.move(edge: .top).combined(with: .opacity))
                                .id("filters")
                            }
                            
                            // Task List Content
                            LazyVStack(spacing: 12) {
                                if filteredTasks.isEmpty {
                                    emptyStateView
                                        .padding(.top, 20)
                                } else {
                                    ForEach(filteredTasks) { task in
                                        ModernTaskCard(task: task)
                                            .contextMenu {
                                                taskContextMenu(for: task)
                                            }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 100)
                        }
                        .background(
                            GeometryReader { geometry in
                                Color.clear
                                    .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scrollView")).minY)
                            }
                        )
                    }
                    .coordinateSpace(name: "scrollView")
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        handleScrollOffset(value)
                    }
                }
                
                // Header Section
                headerSection
                    .background(Color(.systemBackground).opacity(0.95))
                    .background(.ultraThinMaterial)
                    .zIndex(1000)
            }
        }
        .navigationBarHidden(true)
        .searchable(text: $searchText, prompt: "Search tasks...")
        .sheet(isPresented: $showAddTask) {
            NavigationStack {
                AddTaskView()
            }
            .presentationDetents([.large])
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tasks")
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(.primary)
                    
                    Text("\(filteredTasks.count) task\(filteredTasks.count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 16) {
                    // Filter Toggle Button
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showFilters.toggle()
                        }
                    } label: {
                        Image(systemName: showFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .font(.title2)
                            .foregroundColor(showFilters ? .blue : .secondary)
                    }
                    
                    // Add Task Button
                    Button {
                        showAddTask = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
    }

    private var statusFilterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Status")
                .font(.headline.weight(.semibold))
                .foregroundColor(.primary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ModernFilterChip(
                        title: "All",
                        count: taskCount(for: nil as TaskStatus?),
                        isSelected: selectedFilter == nil,
                        color: .gray
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedFilter = nil
                        }
                    }
                    
                    ForEach(TaskStatus.allCases, id: \.self) { status in
                        ModernFilterChip(
                            title: status.displayName,
                            count: taskCount(for: status),
                            isSelected: selectedFilter == status,
                            color: status.color
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedFilter = selectedFilter == status ? nil : status
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.horizontal, -16)
        }
    }

    private var categoryFilterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(.headline.weight(.semibold))
                .foregroundColor(.primary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ModernFilterChip(
                        title: "All",
                        count: taskCount(for: nil as TaskCategory?),
                        isSelected: selectedCategory == nil,
                        color: .orange
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedCategory = nil
                        }
                    }
                    
                    ForEach(categories, id: \.id) { category in
                        ModernFilterChip(
                            title: category.name,
                            count: taskCount(for: category),
                            isSelected: selectedCategory?.id == category.id,
                            color: category.color
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedCategory = selectedCategory?.id == category.id ? nil : category
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.horizontal, -16)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.badge.xmark")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No Tasks")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.primary)
                
                Text("Create your first task to get started with the Pomodoro technique")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                showAddTask = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                    Text("Add Task")
                }
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(.blue)
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
    }

    @ViewBuilder
    private func taskContextMenu(for task: PolmodorTask) -> some View {
        if !task.completed {
            Button {
                withAnimation {
                    task.completed = true
                    task.completedAt = Date()
                    task.status = .completed
                }
            } label: {
                Label("Complete", systemImage: "checkmark")
            }
        }
        
        Button(role: .destructive) {
            withAnimation {
                modelContext.delete(task)
            }
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    private func handleScrollOffset(_ offset: CGFloat) {
        let diff = offset - lastScrollOffset
        lastScrollOffset = offset
        
        // Hide filters when scrolling down, show when scrolling up
        if diff < -30 && showFilters {
            withAnimation(.easeInOut(duration: 0.3)) {
                showFilters = false
            }
        } else if diff > 30 && !showFilters {
            withAnimation(.easeInOut(duration: 0.3)) {
                showFilters = true
            }
        }
    }
}

struct ModernTaskCard: View {
    let task: PolmodorTask
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationLink(destination: TaskDetailView(task: task)) {
            VStack(alignment: .leading, spacing: 16) {
                // Header Section
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(task.title)
                                .font(.headline.weight(.semibold))
                                .foregroundColor(.primary)
                                .lineLimit(2)
                            
                            Spacer()
                            
                            statusBadge
                        }
                        
                        if !task.taskDescription.isEmpty {
                            Text(task.taskDescription)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
                
                // Progress Section
                if !task.subTasks.isEmpty {
                    progressSection
                }
                
                // Footer Section
                footerSection
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var statusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: task.status.iconName)
                .font(.caption2)
            Text(task.status.displayName)
                .font(.caption.weight(.medium))
        }
        .foregroundColor(task.status.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(task.status.color.opacity(0.15))
        )
    }
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Subtasks")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(completedSubtasks)/\(task.subTasks.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.primary)
            }
            
            ProgressView(value: progressValue, total: 1.0)
                .tint(task.category?.color ?? .blue)
                .scaleEffect(y: 1.5)
        }
    }
    
    private var footerSection: some View {
        HStack {
            // Category
            if let category = task.category {
                HStack(spacing: 6) {
                    Circle()
                        .fill(category.color)
                        .frame(width: 8, height: 8)
                    
                    Text(category.name)
                        .font(.caption.weight(.medium))
                        .foregroundColor(category.color)
                }
            }
            
            Spacer()
            
            // Pomodoros
            HStack(spacing: 4) {
                Image(systemName: "timer.circle.fill")
                    .font(.caption)
                    .foregroundColor(.red.opacity(0.8))
                
                Text("\(task.completedPomodoros)")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)
            }
            
            // Priority
            HStack(spacing: 4) {
                Image(systemName: task.priority.iconName)
                    .font(.caption)
                    .foregroundColor(task.priority.color)
                
                Text(task.priority.rawValue.capitalized)
                    .font(.caption.weight(.medium))
                    .foregroundColor(task.priority.color)
            }
        }
    }
    
    private var completedSubtasks: Int {
        task.subTasks.filter { $0.completed }.count
    }
    
    private var progressValue: Double {
        guard !task.subTasks.isEmpty else { return 0 }
        return Double(completedSubtasks) / Double(task.subTasks.count)
    }
}

struct ModernFilterChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                // Icon indicator
                Circle()
                    .fill(isSelected ? .white : color)
                    .frame(width: 8, height: 8)
                    .shadow(color: isSelected ? .white.opacity(0.3) : .clear, radius: 2)
                
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(isSelected ? .white : .primary)
                
                // Count badge with modern design
                Text("\(count)")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(isSelected ? color : .white)
                    .frame(minWidth: 18, minHeight: 18)
                    .background(
                        Circle()
                            .fill(isSelected ? .white.opacity(0.9) : color)
                            .shadow(
                                color: isSelected ? .black.opacity(0.1) : color.opacity(0.3),
                                radius: isSelected ? 2 : 1,
                                x: 0,
                                y: 1
                            )
                    )
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    if isSelected {
                        // Gradient background for selected state
                        LinearGradient(
                            gradient: Gradient(colors: [color, color.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        // Glass morphism effect for unselected
                        Color(.systemBackground)
                            .opacity(0.8)
                    }
                }
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 16)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? .clear : color.opacity(0.3),
                        lineWidth: 1.5
                    )
            )
            .shadow(
                color: isSelected ? color.opacity(0.4) : .black.opacity(0.05),
                radius: isSelected ? 8 : 4,
                x: 0,
                y: isSelected ? 4 : 2
            )
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
    }
}

// Alternative chip designs - you can switch between them

struct MinimalFilterChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(isSelected ? color : .secondary)
                
                HStack(spacing: 2) {
                    Circle()
                        .fill(color)
                        .frame(width: 4, height: 4)
                    
                    Text("\(count)")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(isSelected ? color : .secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? color.opacity(0.1) : .clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                isSelected ? color : Color(.systemGray4),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
    }
}

struct SegmentedFilterChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                
                Text("\(count)")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(isSelected ? .white : color.opacity(0.2))
                    )
                    .foregroundColor(isSelected ? color : color.opacity(0.8))
            }
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? color : color.opacity(0.08))
            )
            .overlay(
                Capsule()
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
        }
        .scaleEffect(isSelected ? 1.0 : 0.95)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - View Extensions
extension View {
    func withFloatingTabBarPadding() -> some View {
        self.safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 100)
        }
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
