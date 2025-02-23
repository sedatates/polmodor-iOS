import SwiftUI

struct TimerView: View {
    @StateObject private var viewModel = TimerViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        GeometryReader { geometry in
            ZStack {
               

                // Timer Circle
                TimerCircleView(
                    progress: viewModel.progress,
                    timeRemaining: viewModel.timeRemainingFormatted,
                    state: viewModel.state,
                    isRunning: viewModel.isRunning,
                    onStart: viewModel.startTimer,
                    onPause: viewModel.pauseTimer,
                    onReset: viewModel.resetTimer,
                    onAddTask: {}
                )
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                viewModel.handleForegroundTransition()
            } else if newPhase == .background {
                viewModel.handleBackgroundTransition()
            }
        }
    }
}

#if DEBUG
    struct TimerView_Previews: PreviewProvider {
        static var previews: some View {
            TimerView()
        }
    }
#endif

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
