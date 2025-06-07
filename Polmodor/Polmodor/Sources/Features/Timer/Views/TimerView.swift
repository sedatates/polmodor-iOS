import SwiftUI
import SwiftData

struct TimerView: View {
    @StateObject private var timerViewModel = TimerViewModel()
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: [
        SortDescriptor(\PolmodorTask.createdAt, order: .reverse)
    ]) private var tasks: [PolmodorTask]
    
    @State private var showingTaskSelector = false
    @State private var showingTaskForm = false
    @State private var showingSettings = false
    
    private var activeTask: PolmodorTask? {
        if let subtaskID = timerViewModel.activeSubtaskID {
            return tasks.first { task in
                task.subTasks.contains { $0.id == subtaskID }
            }
        }
        return nil
    }
    
    private var activeSubtask: PolmodorSubTask? {
        if let subtaskID = timerViewModel.activeSubtaskID {
            return tasks.flatMap(\.subTasks).first { $0.id == subtaskID }
        }
        return nil
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 30) {
                    headerSection
                    
                    timerSection
                    
                    controlsSection
                    
                    activeTaskSection
                    
                    quickActionsSection
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .onAppear {
            timerViewModel.configure(with: modelContext)
        }
        .sheet(isPresented: $showingTaskSelector) {
            TaskSelectorView(
                selectedSubtaskID: $timerViewModel.activeSubtaskID,
                tasks: tasks
            )
        }
        .sheet(isPresented: $showingTaskForm) {
            NavigationView {
                TaskFormView { newTask in
                    showingTaskForm = false
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            NavigationView {
                SettingsView()
            }
        }
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Polmodor Timer")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.primary)
                
                Text(statusText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var statusText: String {
        if timerViewModel.isRunning {
            return "Focus Timer Active"
        } else if timerViewModel.timeRemaining < timerViewModel.state.duration {
            return "Timer Paused"
        } else {
            return "Ready to Focus"
        }
    }
    
    private var timerSection: some View {
        TimerCircleView(
            progress: timerViewModel.progress,
            timeRemaining: timerViewModel.timeRemaining,
            totalTime: timerViewModel.state.duration,
            isRunning: timerViewModel.isRunning,
            pomodoroState: timerViewModel.state
        )
        .accessibility(label: Text(timerViewModel.accessibilityLabel))
        .accessibility(value: Text(timerViewModel.accessibilityValue))
        .accessibility(hint: Text(timerViewModel.accessibilityHint))
    }
    
    private var controlsSection: some View {
        HStack(spacing: 20) {
            resetButton
            
            Spacer()
            
            playPauseButton
            
            Spacer()
            
            skipButton
        }
        .padding(.horizontal, 20)
    }
    
    private var playPauseButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                timerViewModel.toggleTimer()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(timerViewModel.currentStateColor)
                    .frame(width: 80, height: 80)
                    .shadow(color: timerViewModel.currentStateColor.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Image(systemName: timerViewModel.isRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.white)
                    .offset(x: timerViewModel.isRunning ? 0 : 2)
            }
        }
        .scaleEffect(timerViewModel.isRunning ? 1.0 : 0.95)
        .animation(.easeInOut(duration: 0.2), value: timerViewModel.isRunning)
        .accessibilityLabel(timerViewModel.isRunning ? "Pause Timer" : "Start Timer")
    }
    
    private var resetButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                timerViewModel.resetTimer()
            }
        } label: {
            Image(systemName: "arrow.counterclockwise")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(Color(.systemGray6))
                )
        }
        .disabled(timerViewModel.timeRemaining >= timerViewModel.state.duration && !timerViewModel.isRunning)
        .opacity(timerViewModel.timeRemaining >= timerViewModel.state.duration && !timerViewModel.isRunning ? 0.5 : 1.0)
        .accessibilityLabel("Reset Timer")
    }
    
    private var skipButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                timerViewModel.skipToNext()
            }
        } label: {
            Image(systemName: "forward.end.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(Color(.systemGray6))
                )
        }
        .accessibilityLabel("Skip to Next Session")
    }
    
    private var activeTaskSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Active Task")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button {
                    showingTaskSelector = true
                } label: {
                    Text(timerViewModel.activeSubtaskID == nil ? "Select Task" : "Change Task")
                        .font(.caption.weight(.medium))
                        .foregroundColor(timerViewModel.currentStateColor)
                }
            }
            
            if let task = activeTask, let subtask = activeSubtask {
                ActiveTaskCard(task: task, subtask: subtask)
            } else {
                EmptyTaskCard()
            }
        }
        .padding(.horizontal, 4)
    }
    
    private var quickActionsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Quick Actions")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "plus.circle.fill",
                    title: "Add Task",
                    color: .blue
                ) {
                    showingTaskForm = true
                }
                
                QuickActionButton(
                    icon: "list.bullet.clipboard",
                    title: "All Tasks",
                    color: .green
                ) {
                    showingTaskSelector = true
                }
                
                QuickActionButton(
                    icon: "chart.bar.fill",
                    title: "Statistics",
                    color: .orange
                ) {
                    // Navigate to statistics view
                }
            }
        }
        .padding(.horizontal, 4)
    }
}

struct ActiveTaskCard: View {
    let task: PolmodorTask
    let subtask: PolmodorSubTask
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Text(subtask.title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(subtask.pomodoro.completed)/\(subtask.pomodoro.total)")
                        .font(.title3.weight(.bold))
                        .foregroundColor(.primary)
                    
                    Text("Pomodoros")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            ProgressView(value: Double(subtask.pomodoro.completed), total: Double(subtask.pomodoro.total))
                .tint(task.category?.color ?? .blue)
                .scaleEffect(y: 1.5)
            
            HStack {
                Label(task.category?.name ?? "General", systemImage: "tag.fill")
                    .font(.caption.weight(.medium))
                    .foregroundColor(task.category?.color ?? .blue)
                
                Spacer()
                
                Label(task.priority.rawValue, systemImage: "exclamationmark.circle.fill")
                    .font(.caption.weight(.medium))
                    .foregroundColor(task.priority.color)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
}

struct EmptyTaskCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "timer.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.6))
            
            Text("No Active Task")
                .font(.headline.weight(.medium))
                .foregroundColor(.primary)
            
            Text("Select a task to start focusing with the Pomodoro technique")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
    }
}

struct TaskSelectorView: View {
    @Binding var selectedSubtaskID: UUID?
    let tasks: [PolmodorTask]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(tasks) { task in
                    Section(task.title) {
                        ForEach(task.subTasks) { subtask in
                            Button {
                                selectedSubtaskID = subtask.id
                                dismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(subtask.title)
                                            .foregroundColor(.primary)
                                        
                                        Text("\(subtask.pomodoro.completed)/\(subtask.pomodoro.total) Pomodoros")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedSubtaskID == subtask.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    TimerView()
        .modelContainer(ModelContainerSetup.setupModelContainer())
}