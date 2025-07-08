import SwiftData
import SwiftUI

struct TimerView: View {
  @EnvironmentObject private var timerViewModel: TimerViewModel
  @Environment(\.modelContext) private var modelContext
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.scenePhase) private var scenePhase

  @Query(sort: [
    SortDescriptor(\PolmodorTask.createdAt, order: .reverse)
  ]) private var tasks: [PolmodorTask]

  @State private var showingTaskSelector = false
  @State private var showingTaskForm = false

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
    GeometryReader { _ in
      ScrollView {
        ZStack(alignment: .top) {
          headerSection
            .padding(.horizontal, 32)

          TimerBackgroundShape()
            .fill(timerViewModel.currentStateColor.opacity(colorScheme == .dark ? 0.25 : 0.15))
            .frame(
              width: UIScreen.screenWidth,
              height: UIScreen.screenWidth * 2
            )
            .offset(y: -UIScreen.screenWidth / 1.5)
            .allowsHitTesting(false)

          VStack(spacing: 20) {
            timerSection
            Group {
              controlsSection

              Spacer()

              activeTaskSection

              Spacer()

              quickActionsSection

              Spacer(minLength: 100)
            }
            .padding(.horizontal, 16)
          }
        }
      }
      .scrollIndicators(.hidden)
    }
    .onAppear {
      timerViewModel.configure(with: modelContext)
    }
    .onChange(of: scenePhase) { _, newPhase in
      switch newPhase {
      case .background: break
      // Timer state saves automatically
      case .active:
        timerViewModel.updateFromLiveActivity()
      default:
        break
      }
    }
    .onDisappear {
      // Timer state saves automatically
    }

    .sheet(isPresented: $showingTaskForm) {
      NavigationView {
        TaskFormView { _ in
          showingTaskForm = false
        }
      }
    }
    .sheet(isPresented: $showingTaskSelector) {
      TaskSelectorView(tasks: tasks, selectedSubtaskID: $timerViewModel.activeSubtaskID)
    }
  }

  private var headerSection: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        pomodoroIndicator
      }

      Spacer()

      NavigationLink(destination: SettingsView()) {
        Image(systemName: "gearshape.fill")
          .font(.title2)
          .foregroundColor(.secondary)
      }
    }
  }

  private var pomodoroIndicator: some View {
    HStack(spacing: 8) {
      Circle()
        .fill(getNextState().color)
        .frame(width: 8, height: 8)
        .shadow(color: getNextState().color.opacity(0.4), radius: 2, x: 0, y: 1)
        .scaleEffect(timerViewModel.isRunning ? 1.2 : 1.0)
        .animation(
          .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
          value: timerViewModel.isRunning)

      Text("Next: \(getNextState().title)")
        .font(.caption2.weight(.medium))
        .foregroundColor(getNextState().color)
        .opacity(0.8)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 6)
    .background(
      Capsule()
        .fill(.ultraThickMaterial)
    )
  }

  private func getNextState() -> PomodoroState {
    switch timerViewModel.state {
    case .work:
      let currentPomodoros = timerViewModel.completedPomodoros + 1
      return currentPomodoros % SettingsManager.shared.pomodorosUntilLongBreakCount == 0
        ? .longBreak : .shortBreak
    case .shortBreak, .longBreak:
      return .work
    }
  }

  private var statusText: String {
    if timerViewModel.isRunning {
      return "Focus Timer Active"
    } else if timerViewModel.timeRemaining == 0 {
      return "Session Completed"
    } else if timerViewModel.timeRemaining < timerViewModel.state.duration {
      return "Timer Paused"
    } else {
      return "Ready to Focus"
    }
  }

  private var timerSection: some View {
    TimerCircleView(
      timeRemaining: timerViewModel.timeRemaining,
      isRunning: timerViewModel.isRunning,
      pomodoroState: timerViewModel.state,
      completedPomodoros: timerViewModel.completedPomodoros
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
        timerViewModel.reset()
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
    .disabled(!timerViewModel.canReset)
    .opacity(timerViewModel.canReset ? 1.0 : 0.5)
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

        NavigationLink(destination: TaskListView()) {
          QuickActionContent(
            icon: "list.bullet.clipboard",
            title: "All Tasks",
            color: .green
          )
        }

        NavigationLink(destination: StatisticsView()) {
          QuickActionContent(
            icon: "chart.bar.fill",
            title: "Statistics",
            color: .orange
          )
        }
      }
    }
    .padding(.horizontal, 8)
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
      QuickActionContent(icon: icon, title: title, color: color)
    }
  }
}

struct QuickActionContent: View {
  let icon: String
  let title: String
  let color: Color

  var body: some View {
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

struct TaskSelectorView: View {
  let tasks: [PolmodorTask]
  @Environment(\.dismiss) private var dismiss
  @Binding var selectedSubtaskID: UUID?

  // Filter completed tasks and subtasks
  private var availableTasks: [PolmodorTask] {
    tasks.filter {
      !$0.completed
        && !$0.subTasks.filter { !$0.completed && $0.pomodoroCompleted < $0.pomodoroTotal }.isEmpty
    }
  }

  var body: some View {
    NavigationView {
      List {
        if availableTasks.isEmpty {
          Section {
            VStack(spacing: 16) {
              Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)

              Text("All Tasks Completed!")
                .font(.title3.weight(.semibold))
                .foregroundColor(.primary)

              Text("Great job! You've completed all your tasks.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
          }
        } else {
          ForEach(availableTasks) { task in
            let availableSubtasks = task.subTasks.filter {
              !$0.completed && $0.pomodoroCompleted < $0.pomodoroTotal
            }

            if !availableSubtasks.isEmpty {
              Section(task.title) {
                ForEach(availableSubtasks) { subtask in
                  Button {
                    selectedSubtaskID = subtask.id
                    dismiss()
                  } label: {
                    HStack {
                      VStack(alignment: .leading, spacing: 4) {
                        Text(subtask.title)
                          .foregroundColor(.primary)

                        Text("\(subtask.pomodoroCompleted)/\(subtask.pomodoroTotal) Pomodoros")
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

struct TimerBackgroundShape: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()

    let width = rect.width
    let height = rect.height
    let concaveDepth: CGFloat = UIScreen.screenWidth / 2

    // Start from top-left corner
    path.move(to: CGPoint(x: 0, y: 0))

    // Top edge (rectangular)
    path.addLine(to: CGPoint(x: width, y: 0))

    // Right edge
    path.addLine(to: CGPoint(x: width, y: height - concaveDepth))

    // Concave bottom curve
    path.addQuadCurve(
      to: CGPoint(x: 0, y: height - concaveDepth),
      control: CGPoint(x: width / 2, y: height - UIScreen.screenWidth / 4)
    )

    // Left edge back to start
    path.addLine(to: CGPoint(x: 0, y: 0))

    return path
  }
}

#Preview {
  TimerView()
    .modelContainer(ModelContainerSetup.setupModelContainer())
}
