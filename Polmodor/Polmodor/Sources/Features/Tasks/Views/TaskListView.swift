import SwiftUI

struct TaskListView: View {
    @StateObject private var viewModel = TaskViewModel()
    @State private var showingAddTask = false
    @State private var showingTaskDetail: PolmodorTask?
    
    var body: some View {
        List {
            TaskFilterView(selectedFilter: $viewModel.selectedFilter)
            
            ForEach(viewModel.filteredTasks) { task in
                TaskRowView(task: task)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showingTaskDetail = task
                    }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    viewModel.deleteTask(viewModel.filteredTasks[index])
                }
            }
            .onMove { source, destination in
                viewModel.moveTask(from: source, to: destination)
            }
        }
        .navigationTitle("Tasks")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddTask = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
        .sheet(isPresented: $showingAddTask) {
            NavigationView {
                TaskFormView { task in
                    viewModel.addTask(task)
                }
            }
        }
        .sheet(item: $showingTaskDetail) { task in
            NavigationView {
                TaskDetailView(task: task) { updatedTask in
                    viewModel.updateTask(updatedTask)
                }
            }
        }
    }
}

struct TaskFilterView: View {
    @Binding var selectedFilter: PolmodorTask.TaskStatus?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                FilterChip(
                    title: "All",
                    isSelected: selectedFilter == nil,
                    action: { selectedFilter = nil }
                )
                
                ForEach(PolmodorTask.TaskStatus.allCases, id: \.self) { status in
                    FilterChip(
                        title: status.rawValue,
                        isSelected: selectedFilter == status,
                        action: { selectedFilter = status }
                    )
                }
            }
            .padding(.horizontal)
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.1))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
    }
}

struct TaskRowView: View {
    let task: PolmodorTask
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: task.status.systemImage)
                    .foregroundColor(task.status == .completed ? .green : .secondary)
                
                Text(task.title)
                    .font(.headline)
                
                Spacer()
                
                Text("\(task.completedPomodoros)/\(task.pomodoroCount)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if !task.description.isEmpty {
                Text(task.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            ProgressView(value: task.progress)
                .tint(task.status == .completed ? .green : .accentColor)
        }
    }
}

#Preview {
    NavigationView {
        TaskListView()
    }
} 