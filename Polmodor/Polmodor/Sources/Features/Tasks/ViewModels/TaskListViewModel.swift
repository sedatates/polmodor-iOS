import Combine
import Foundation
import SwiftData
import SwiftUI
import UIKit

@MainActor
final class TaskListViewModel: ObservableObject {
  // MARK: - Published Properties

  // Page Management
  @Published var currentPage: TaskPage = .active

  // Search & Filter
  @Published var searchText = ""
  @Published var selectedStatuses = Set<TaskStatus>()
  @Published var selectedCategories = Set<UUID>()
  @Published var selectedPriorities = Set<TaskPriority>()
  @Published var dateRange: DateRange?

  // UI State
  @Published var showAddTask = false
  @Published var showFilterSheet = false
  @Published var showBatchActions = false
  @Published var showSubscriptionPrompt = false
  @Published var selectedTasks = Set<UUID>()
  @Published var viewMode: ViewMode = .list
  @Published var sortOption: SortOption = .dateCreated
  @Published var sortOrder: SortOrder = .descending

  // Data
  private var allTasks: [PolmodorTask] = []
  private var allCategories: [TaskCategory] = []
  private var modelContext: ModelContext?

  private var cancellables = Set<AnyCancellable>()

  // MARK: - Computed Properties

  var categories: [TaskCategory] {
    // Remove duplicates by name and ID
    var uniqueCategories: [TaskCategory] = []
    var seenIds = Set<UUID>()
    var seenNames = Set<String>()

    for category in allCategories {
      if !seenIds.contains(category.id) && !seenNames.contains(category.name) {
        uniqueCategories.append(category)
        seenIds.insert(category.id)
        seenNames.insert(category.name)
      }
    }
    return uniqueCategories.sorted { $0.name < $1.name }
  }

  var activeTasks: [PolmodorTask] {
    allTasks.filter { !$0.completed }
  }

  var completedTasks: [PolmodorTask] {
    allTasks.filter { $0.completed }
  }

  var tasks: [PolmodorTask] {
    allTasks
  }

  var hasActiveFilters: Bool {
    !selectedStatuses.isEmpty || !selectedCategories.isEmpty || !selectedPriorities.isEmpty
      || dateRange != nil
  }

  var canGoBack: Bool {
    // For now, we'll show the back button when TaskListView is presented
    // This will be true when navigated from TimerView or other views
    // In a tab-based root view, this might be false but we'll keep it simple
    return true
  }

  // MARK: - Initialization

  init() {
    setupBindings()
  }

  func configure(
    modelContext: ModelContext, allTasks: [PolmodorTask], allCategories: [TaskCategory]
  ) {
    self.modelContext = modelContext
    self.allTasks = allTasks
    self.allCategories = allCategories
  }

  private func setupBindings() {
    // Clear selection when changing pages
    $currentPage
      .sink { [weak self] _ in
        self?.selectedTasks.removeAll()
        self?.showBatchActions = false
      }
      .store(in: &cancellables)
  }

  // MARK: - Task Filtering & Sorting

  func filteredTasks(for page: TaskPage) -> [PolmodorTask] {
    let baseTasks = page == .active ? activeTasks : completedTasks

    return baseTasks.filter { task in
      // Search filter
      let matchesSearch =
        searchText.isEmpty
        || task.title.localizedCaseInsensitiveContains(searchText)
        || task.taskDescription.localizedCaseInsensitiveContains(searchText)

      // Status filter
      let matchesStatus = selectedStatuses.isEmpty || selectedStatuses.contains(task.status)

      // Category filter
      let matchesCategory =
        selectedCategories.isEmpty
        || (task.category != nil && selectedCategories.contains(task.category!.id))

      // Priority filter
      let matchesPriority = selectedPriorities.isEmpty || selectedPriorities.contains(task.priority)

      // Date range filter
      let matchesDate = dateRange?.contains(task.createdAt) ?? true

      return matchesSearch && matchesStatus && matchesCategory && matchesPriority && matchesDate
    }
    .sorted(by: sortComparator)
  }

  private func sortComparator(lhs: PolmodorTask, rhs: PolmodorTask) -> Bool {
    let ascending = sortOrder == .ascending

    switch sortOption {
    case .dateCreated:
      return ascending ? lhs.createdAt < rhs.createdAt : lhs.createdAt > rhs.createdAt
    case .title:
      return ascending ? lhs.title < rhs.title : lhs.title > rhs.title
    case .priority:
      let lhsValue = lhs.priority.sortValue
      let rhsValue = rhs.priority.sortValue
      return ascending ? lhsValue < rhsValue : lhsValue > rhsValue
    case .category:
      let lhsName = lhs.category?.name ?? ""
      let rhsName = rhs.category?.name ?? ""
      return ascending ? lhsName < rhsName : lhsName > rhsName
    }
  }

  // MARK: - UI Actions

  func toggleViewMode() {
    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
      viewMode = viewMode == .list ? .grid : .list
    }
  }

  func updateSort(option: SortOption) {
    if sortOption == option {
      sortOrder = sortOrder == .ascending ? .descending : .ascending
    } else {
      sortOption = option
      sortOrder = .descending
    }
  }

  func toggleBatchActions() {
    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
      if selectedTasks.isEmpty {
        showBatchActions = true
      } else {
        selectedTasks.removeAll()
        showBatchActions = false
      }
    }
  }

  func toggleTaskSelection(_ taskId: UUID) {
    if selectedTasks.contains(taskId) {
      selectedTasks.remove(taskId)
    } else {
      selectedTasks.insert(taskId)
    }
  }

  func changePage(to page: TaskPage) {
    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
      currentPage = page
    }
  }

  // MARK: - Filter Management

  func toggleStatusFilter(_ status: TaskStatus) {
    if selectedStatuses.contains(status) {
      selectedStatuses.remove(status)
    } else {
      selectedStatuses.insert(status)
    }
  }

  func toggleCategoryFilter(_ categoryId: UUID) {
    if selectedCategories.contains(categoryId) {
      selectedCategories.remove(categoryId)
    } else {
      selectedCategories.insert(categoryId)
    }
  }

  func togglePriorityFilter(_ priority: TaskPriority) {
    if selectedPriorities.contains(priority) {
      selectedPriorities.remove(priority)
    } else {
      selectedPriorities.insert(priority)
    }
  }

  func setDateRange(_ range: DateRange?) {
    dateRange = dateRange == range ? nil : range
  }

  func clearAllFilters() {
    selectedStatuses.removeAll()
    selectedCategories.removeAll()
    selectedPriorities.removeAll()
    dateRange = nil
  }

  // MARK: - Batch Operations

  func batchCompleteToggle() {
    guard let modelContext = modelContext else { return }

    let tasksToUpdate = allTasks.filter { selectedTasks.contains($0.id) }

    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
      for task in tasksToUpdate {
        if currentPage == .active {
          // Complete task
          task.completed = true
          task.completedAt = Date()
          task.status = .completed
        } else {
          // Uncomplete task
          task.completed = false
          task.completedAt = nil
          task.status = .todo
        }
      }
      selectedTasks.removeAll()
      showBatchActions = false

      // Haptic feedback
      let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
      impactFeedback.impactOccurred()
    }
  }

  func batchDelete() {
    guard let modelContext = modelContext else { return }

    let tasksToDelete = allTasks.filter { selectedTasks.contains($0.id) }

    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
      for task in tasksToDelete {
        modelContext.delete(task)
      }
      selectedTasks.removeAll()
      showBatchActions = false
    }
  }

  // MARK: - Task Count Helpers

  func taskCount(for page: TaskPage) -> Int {
    filteredTasks(for: page).count
  }

  func taskCountText(for page: TaskPage) -> String {
    let count = taskCount(for: page)
    return "\(count) task\(count == 1 ? "" : "s")"
  }
}
