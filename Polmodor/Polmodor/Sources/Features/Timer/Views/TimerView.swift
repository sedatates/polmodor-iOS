import SwiftUI

@available(iOS 14.0, macOS 11.0, *)
struct TimerView: View {
    @StateObject private var viewModel = TimerViewModel()
	  @StateObject private var taskViewModel = TaskViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @State private var showingTaskForm = false

    var body: some View {
        TimerCircleView(
            progress: viewModel.progress,
            timeRemaining: viewModel.timeRemainingFormatted,
            state: viewModel.state,
            isRunning: viewModel.isRunning,
            onStart: viewModel.startTimer,
            onPause: viewModel.pauseTimer,
            onReset: viewModel.resetTimer,
            onAddTask: { showingTaskForm = true }
        )
				.sheet(isPresented: $showingTaskForm) {
					TaskFormView(onSave: taskViewModel.addTask)
				}
        .onChange(of: scenePhase) { _ in
            if scenePhase == .active {
                viewModel.handleForegroundTransition()
            } else if scenePhase == .background {
                viewModel.handleBackgroundTransition()
            }
        }
        .ignoresSafeArea()
    }
}

@available(iOS 14.0, macOS 11.0, *)
struct TimerControlsView: View {
    let isRunning: Bool
    let onStart: () -> Void
    let onPause: () -> Void
    let onReset: () -> Void
    let onSkip: () -> Void

    var body: some View {
        HStack(spacing: 20) {
            Button(action: onReset) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title2)
            }
            .buttonStyle(.bordered)

            Button(action: isRunning ? onPause : onStart) {
                Image(systemName: isRunning ? "pause.fill" : "play.fill")
                    .font(.title)
                    .frame(width: 60, height: 60)
            }
            .buttonStyle(.bordered)

            Button(action: onSkip) {
                Image(systemName: "forward.fill")
                    .font(.title2)
            }
            .buttonStyle(.bordered)
        }
    }
}

