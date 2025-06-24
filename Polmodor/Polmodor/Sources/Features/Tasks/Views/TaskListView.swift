import SwiftData
import SwiftUI
import UIKit

// MARK: - TaskListView

struct TaskListView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var timerViewModel: TimerViewModel
  @StateObject private var viewModel = TaskListViewModel()
  @Query(sort: \PolmodorTask.createdAt, order: .reverse) private var allTasks: [PolmodorTask]
  @Query(sort: \TaskCategory.name) private var allCategories: [TaskCategory]

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        // Quick Actions Toolbar
        quickActionsToolbar

        // Page Header with counts
        pageHeader

        // Main Content - Simple Page Display
        taskPageView(for: viewModel.currentPage)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .animation(.easeInOut(duration: 0.3), value: viewModel.currentPage)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .navigationBarHidden(true)
      .searchable(text: $viewModel.searchText, prompt: "Search tasks...")
      .sheet(isPresented: $viewModel.showAddTask) {
        NavigationStack {
          AddTaskView()
        }
        .presentationDetents([.large])
      }
      .sheet(isPresented: $viewModel.showFilterSheet) {
        filterBottomSheet
          .presentationDetents([.medium, .large])
          .presentationDragIndicator(.visible)
      }
      .overlay(alignment: .bottom) {
        if viewModel.showBatchActions {
          batchActionsBar
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
      }
      .onAppear {
        viewModel.configure(
          modelContext: modelContext, allTasks: allTasks, allCategories: allCategories)
      }
      .onChange(of: allTasks) { oldValue, newValue in
        viewModel.configure(
          modelContext: modelContext, allTasks: newValue, allCategories: allCategories)
      }
      .onChange(of: allCategories) { oldValue, newValue in
        viewModel.configure(modelContext: modelContext, allTasks: allTasks, allCategories: newValue)
      }
    }
  }

  // MARK: - Quick Actions Toolbar

  private var quickActionsToolbar: some View {
    HStack {
      // Back Button - only show if we can go back
      Button {
        dismiss()
      } label: {
        Image(systemName: "chevron.left")
          .font(.title2.weight(.semibold))
          .foregroundColor(.primary)
          .frame(width: 44, height: 44)
          .background(Color(.systemGray6))
          .clipShape(Circle())
      }
      .opacity(viewModel.canGoBack ? 1 : 0)
      .disabled(!viewModel.canGoBack)

      Spacer()
        .frame(width: 0)

      Spacer()

      HStack(spacing: 12) {
        // View Mode Toggle
        Button {
          viewModel.toggleViewMode()
        } label: {
          Image(systemName: viewModel.viewMode == .list ? "square.grid.2x2" : "list.bullet")
            .font(.title3)
            .foregroundColor(.primary)
            .frame(width: 44, height: 44)
            .background(Color(.systemGray6))
            .clipShape(Circle())
        }

        // Sort Menu
        Menu {
          ForEach(SortOption.allCases, id: \.self) { option in
            Button {
              viewModel.updateSort(option: option)
            } label: {
              HStack {
                Text(option.displayName)
                if viewModel.sortOption == option {
                  Image(systemName: viewModel.sortOrder == .ascending ? "arrow.up" : "arrow.down")
                }
              }
            }
          }
        } label: {
          Image(systemName: "arrow.up.arrow.down")
            .font(.title3)
            .foregroundColor(.primary)
            .frame(width: 44, height: 44)
            .background(Color(.systemGray6))
            .clipShape(Circle())
        }

        // Batch Select
        Button {
          viewModel.toggleBatchActions()
        } label: {
          Image(
            systemName: viewModel.showBatchActions ? "checkmark.circle.fill" : "checkmark.circle"
          )
          .font(.title3)
          .foregroundColor(viewModel.showBatchActions ? .blue : .primary)
          .frame(width: 44, height: 44)
          .background(Color(.systemGray6))
          .clipShape(Circle())
        }

        // Filter
        Button {
          viewModel.showFilterSheet = true
        } label: {
          ZStack {
            Image(systemName: "line.3.horizontal.decrease")
              .font(.title3)
              .foregroundColor(.primary)

            if viewModel.hasActiveFilters {
              Circle()
                .fill(.red)
                .frame(width: 8, height: 8)
                .offset(x: 12, y: -12)
            }
          }
          .frame(width: 44, height: 44)
          .background(Color(.systemGray6))
          .clipShape(Circle())
        }

        // Add Task
        Button {
          viewModel.showAddTask = true
        } label: {
          Image(systemName: "plus")
            .font(.title3)
            .foregroundColor(.white)
            .frame(width: 44, height: 44)
            .background(.blue)
            .clipShape(Circle())
        }
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
    .background(Color(.systemBackground))
  }

  // MARK: - Page Header

  private var pageHeader: some View {
    HStack(spacing: 8) {
      // Active Tasks Button
      Button {
        viewModel.changePage(to: .active)
      } label: {
        HStack(spacing: 8) {
          Image(systemName: "circle")
            .font(.caption.weight(.medium))
            .foregroundColor(viewModel.currentPage == .active ? .white : .blue)

          Text("Active")
            .font(.subheadline.weight(.medium))
            .foregroundColor(viewModel.currentPage == .active ? .white : .blue)

          Text("\(viewModel.activeTasks.count)")
            .font(.subheadline.weight(.bold))
            .foregroundColor(viewModel.currentPage == .active ? .white : .blue)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
              Capsule()
                .fill(
                  viewModel.currentPage == .active
                    ? Color.white.opacity(0.2) : Color.blue.opacity(0.15))
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
          Capsule()
            .fill(viewModel.currentPage == .active ? .blue : .blue.opacity(0.08))
        )
        .overlay(
          Capsule()
            .stroke(viewModel.currentPage == .active ? .clear : .blue.opacity(0.3), lineWidth: 1)
        )
      }

      // Completed Tasks Button
      Button {
        viewModel.changePage(to: .completed)
      } label: {
        HStack(spacing: 8) {
          Image(systemName: "checkmark.circle.fill")
            .font(.caption.weight(.medium))
            .foregroundColor(viewModel.currentPage == .completed ? .white : .green)

          Text("Completed")
            .font(.subheadline.weight(.medium))
            .foregroundColor(viewModel.currentPage == .completed ? .white : .green)

          Text("\(viewModel.completedTasks.count)")
            .font(.subheadline.weight(.bold))
            .foregroundColor(viewModel.currentPage == .completed ? .white : .green)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
              Capsule()
                .fill(
                  viewModel.currentPage == .completed
                    ? Color.white.opacity(0.2) : Color.green.opacity(0.15))
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
          Capsule()
            .fill(viewModel.currentPage == .completed ? .green : .green.opacity(0.08))
        )
        .overlay(
          Capsule()
            .stroke(
              viewModel.currentPage == .completed ? .clear : .green.opacity(0.3), lineWidth: 1)
        )
      }

      Spacer()
    }
    .padding(.horizontal, 16)
    .padding(.bottom, 12)
  }

  // MARK: - Task Page View

  @ViewBuilder
  private func taskPageView(for page: TaskPage) -> some View {
    let tasks = viewModel.filteredTasks(for: page)

    if tasks.isEmpty {
      emptyStateView(for: page)
    } else {
      List {
        ForEach(tasks) { task in
          ModernTaskCard(
            task: task,
            isSelected: viewModel.selectedTasks.contains(task.id),
            showBatchActions: viewModel.showBatchActions,
            viewMode: viewModel.viewMode
          ) {
            // Selection action
            if viewModel.showBatchActions {
              viewModel.toggleTaskSelection(task.id)
            }
          }
          .environmentObject(timerViewModel)
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)
          .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        }

        // Add bottom spacing for batch actions
        if viewModel.showBatchActions {
          Color.clear
            .frame(height: 80)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
      }
      .listStyle(.plain)
      .scrollContentBackground(.hidden)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }

  // MARK: - Empty State View

  @ViewBuilder
  private func emptyStateView(for page: TaskPage) -> some View {
    VStack(spacing: 24) {
      Image(systemName: page == .active ? "checkmark.circle.badge.xmark" : "checkmark.circle")
        .font(.system(size: 60))
        .foregroundColor(.secondary.opacity(0.6))

      VStack(spacing: 8) {
        Text(page == .active ? "No Active Tasks" : "No Completed Tasks")
          .font(.title2.weight(.semibold))
          .foregroundColor(.primary)

        Text(
          page == .active
            ? "Create your first task to get started" : "Complete some tasks to see them here"
        )
        .font(.subheadline)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
      }

      if page == .active {
        Button {
          viewModel.showAddTask = true
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
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.horizontal, 32)
  }

  // MARK: - Batch Actions Bar

  private var batchActionsBar: some View {
    HStack {
      Button {
        viewModel.selectedTasks.removeAll()
        viewModel.showBatchActions = false
      } label: {
        Text("Cancel")
          .foregroundColor(.secondary)
      }

      Spacer()

      Text("\(viewModel.selectedTasks.count) selected")
        .font(.subheadline.weight(.medium))
        .foregroundColor(.primary)

      Spacer()

      HStack(spacing: 16) {
        // Complete/Uncomplete
        Button {
          viewModel.batchCompleteToggle()
        } label: {
          Image(
            systemName: viewModel.currentPage == .active ? "checkmark.circle" : "arrow.clockwise"
          )
          .font(.title3)
          .foregroundColor(.green)
        }
        .disabled(viewModel.selectedTasks.isEmpty)

        // Delete
        Button {
          viewModel.batchDelete()
        } label: {
          Image(systemName: "trash")
            .font(.title3)
            .foregroundColor(.red)
        }
        .disabled(viewModel.selectedTasks.isEmpty)
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(.ultraThinMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .padding(.horizontal, 16)
    .padding(.bottom, 16)
  }
}

// MARK: - Filter Bottom Sheet

extension TaskListView {
  private var filterBottomSheet: some View {
    NavigationStack {
      VStack(spacing: 0) {
        // Header
        HStack {
          Text("Filters")
            .font(.title2.weight(.bold))

          Spacer()

          Button("Clear All") {
            viewModel.clearAllFilters()
          }
          .foregroundColor(.red)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)

        ScrollView {
          VStack(spacing: 24) {
            // Status Filter
            filterSection(
              title: "Status",
              icon: "circle.badge.checkmark"
            ) {
              LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(TaskStatus.allCases, id: \.self) { status in
                  FilterToggleButton(
                    title: status.displayName,
                    icon: status.iconName,
                    color: status.color,
                    isSelected: viewModel.selectedStatuses.contains(status)
                  ) {
                    viewModel.toggleStatusFilter(status)
                  }
                }
              }
            }

            // Category Filter
            if !viewModel.categories.isEmpty {
              filterSection(
                title: "Categories",
                icon: "folder"
              ) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                  ForEach(viewModel.categories, id: \.id) { category in
                    FilterToggleButton(
                      title: category.name,
                      icon: "circle.fill",
                      color: category.color,
                      isSelected: viewModel.selectedCategories.contains(category.id)
                    ) {
                      viewModel.toggleCategoryFilter(category.id)
                    }
                  }
                }
              }
            }

            // Priority Filter
            filterSection(
              title: "Priority",
              icon: "exclamationmark.triangle"
            ) {
              LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(TaskPriority.allCases, id: \.self) { priority in
                  FilterToggleButton(
                    title: priority.rawValue.capitalized,
                    icon: priority.iconName,
                    color: priority.color,
                    isSelected: viewModel.selectedPriorities.contains(priority)
                  ) {
                    viewModel.togglePriorityFilter(priority)
                  }
                }
              }
            }

            // Date Range Filter
            filterSection(
              title: "Date Range",
              icon: "calendar"
            ) {
              VStack(spacing: 12) {
                ForEach(DateRange.presets, id: \.self) { preset in
                  FilterToggleButton(
                    title: preset.displayName,
                    icon: "calendar.circle",
                    color: .blue,
                    isSelected: viewModel.dateRange == preset
                  ) {
                    viewModel.setDateRange(preset)
                  }
                }
              }
            }
          }
          .padding(.horizontal, 20)
          .padding(.bottom, 20)
        }
      }
      .navigationBarHidden(true)
    }
  }

  @ViewBuilder
  private func filterSection<Content: View>(
    title: String,
    icon: String,
    @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack(spacing: 8) {
        Image(systemName: icon)
          .font(.headline)
          .foregroundColor(.blue)

        Text(title)
          .font(.headline.weight(.semibold))
          .foregroundColor(.primary)
      }

      content()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

// MARK: - Filter Toggle Button

struct FilterToggleButton: View {
  let title: String
  let icon: String
  let color: Color
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 8) {
        Image(systemName: icon)
          .font(.subheadline)
          .foregroundColor(isSelected ? .white : color)

        Text(title)
          .font(.subheadline.weight(.medium))
          .foregroundColor(isSelected ? .white : .primary)

        Spacer()

        if isSelected {
          Image(systemName: "checkmark")
            .font(.caption.weight(.bold))
            .foregroundColor(.white)
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(isSelected ? color : Color(.systemGray6))
      )
    }
  }
}

// MARK: - Supporting Types

enum TaskPage: CaseIterable {
  case active, completed

  var displayName: String {
    switch self {
    case .active: return "Active"
    case .completed: return "Completed"
    }
  }

  var iconName: String {
    switch self {
    case .active: return "circle"
    case .completed: return "checkmark.circle.fill"
    }
  }

  var color: Color {
    switch self {
    case .active: return .blue
    case .completed: return .green
    }
  }
}

enum ViewMode: CaseIterable {
  case list, grid

  var displayName: String {
    switch self {
    case .list: return "List"
    case .grid: return "Grid"
    }
  }
}

enum SortOption: CaseIterable {
  case dateCreated, title, priority, category

  var displayName: String {
    switch self {
    case .dateCreated: return "Date Created"
    case .title: return "Title"
    case .priority: return "Priority"
    case .category: return "Category"
    }
  }
}

enum SortOrder {
  case ascending, descending
}

enum DateRange: CaseIterable {
  case today, yesterday, thisWeek, lastWeek, thisMonth, lastMonth

  var displayName: String {
    switch self {
    case .today: return "Today"
    case .yesterday: return "Yesterday"
    case .thisWeek: return "This Week"
    case .lastWeek: return "Last Week"
    case .thisMonth: return "This Month"
    case .lastMonth: return "Last Month"
    }
  }

  func contains(_ date: Date) -> Bool {
    let calendar = Calendar.current
    let now = Date()

    switch self {
    case .today:
      return calendar.isDate(date, inSameDayAs: now)
    case .yesterday:
      guard let yesterday = calendar.date(byAdding: .day, value: -1, to: now) else { return false }
      return calendar.isDate(date, inSameDayAs: yesterday)
    case .thisWeek:
      return calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear)
    case .lastWeek:
      guard let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: now) else {
        return false
      }
      return calendar.isDate(date, equalTo: lastWeek, toGranularity: .weekOfYear)
    case .thisMonth:
      return calendar.isDate(date, equalTo: now, toGranularity: .month)
    case .lastMonth:
      guard let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) else {
        return false
      }
      return calendar.isDate(date, equalTo: lastMonth, toGranularity: .month)
    }
  }

  static var presets: [DateRange] {
    return DateRange.allCases
  }
}

// MARK: - Extensions

extension TaskPriority {
  var sortValue: Int {
    switch self {
    case .low: return 0
    case .medium: return 1
    case .high: return 2
    }
  }
}

// MARK: - Modern Task Card

struct ModernTaskCard: View {
  let task: PolmodorTask
  let isSelected: Bool
  let showBatchActions: Bool
  let viewMode: ViewMode
  let onSelection: () -> Void

  @Environment(\.modelContext) private var modelContext
  @State private var isExpanded = false
  @State private var showAddSubtask = false

  private var accentColor: Color {
    task.category?.color ?? .blue
  }

  var body: some View {
    VStack(spacing: 0) {
      // Task Header Component
      PolmodorTaskHeader(
        task: task,
        accentColor: accentColor,
        isExpanded: $isExpanded
      )

      // Task Info Row Component
      if !isExpanded {
        PolmodorTaskInfoRow(task: task)
      }

      // Progress Section for collapsed state
      if !isExpanded && !task.subTasks.isEmpty {
        VStack(alignment: .leading, spacing: 0) {
          SubtaskProgressView(task: task)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
      }

      // Expanded View Component
      if isExpanded {
        PolmodorTaskExpandedView(
          task: task,
          accentColor: accentColor,
          isExpanded: $isExpanded,
          showAddSubtask: $showAddSubtask
        )
      }
    }
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color(.systemBackground))
        .shadow(
          color: .black.opacity(task.completed ? 0.04 : 0.08),
          radius: task.completed ? 6 : 12,
          x: 0,
          y: task.completed ? 2 : 4
        )
    )
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .stroke(
          isSelected ? .blue : (task.completed ? Color(.systemGray4) : .clear),
          lineWidth: isSelected ? 2 : 1
        )
    )
    .opacity(isSelected ? 0.7 : 1.0)
    .onTapGesture {
      if showBatchActions {
        onSelection()
      }
    }
    .overlay(alignment: .topTrailing) {
      // Selection overlay
      if showBatchActions {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
          .font(.title2)
          .foregroundColor(isSelected ? .blue : .secondary)
          .background(
            Circle()
              .fill(.white)
              .frame(width: 24, height: 24)
          )
          .padding(16)
      }
    }
    .sheet(isPresented: $showAddSubtask) {
      NavigationStack {
        SubTaskAddView(task: task)
      }
      .presentationDetents([.medium])
    }
    .onChange(of: showAddSubtask) { oldValue, newValue in
      print("🔧 ModernTaskCard showAddSubtask changed from \(oldValue) to \(newValue)")
    }
  }
}
