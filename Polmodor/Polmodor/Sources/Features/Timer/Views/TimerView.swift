import Combine
import Foundation
import SwiftData
import SwiftUI
// Import our custom components
import UserNotifications

#if os(iOS)
    import UIKit
#endif

private final class Storage: ObservableObject {
    var cancellables = Set<AnyCancellable>()
}

// MARK: - Main Timer View
struct TimerView: View {
    @EnvironmentObject var viewModel: TimerViewModel
    @Environment(\.modelContext) private var modelContext

    // MARK: - State
    @State private var showUnlockAlert = false
    @State private var isLocked = false
    @State private var dragAmount = CGSize.zero
    @State private var isUnlocked = false
    @GestureState private var isDragging = false
    private let haptic = UIImpactFeedbackGenerator(style: .medium)

    @StateObject private var storage = Storage()

    @State private var activeSubtask: PolmodorSubTask?
    @State private var parentTask: PolmodorTask?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                BackgroundGradientView(stateColor: viewModel.currentStateColor)

                VStack(spacing: 30) {
                    // Active task display
                    activeTaskView

                    Spacer()

                    TimerCircleView(
                        progress: viewModel.progress,
                        timeString: viewModel.timeString,
                        stateTitle: viewModel.currentStateTitle,
                        stateColor: viewModel.currentStateColor,
                        geometry: geometry
                    )

                    TimerControlsView(
                        viewModel: viewModel,
                        isLocked: isLocked,
                        showUnlockAlert: $showUnlockAlert
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))

                    Spacer()
                }
            }
            .onChange(of: isLocked) { oldValue, newValue in
                handleLockStateChange(newValue)
            }
            .onChange(of: viewModel.isRunning) { oldValue, newValue in
                handleTimerStateChange(newValue)
            }
            .onChange(of: viewModel.activeSubtaskID) { oldValue, newValue in
                loadActiveSubtask()
            }
            .withFloatingTabBarPadding()
        }
        .alert("Unlock Timer Controls?", isPresented: $showUnlockAlert) {
            UnlockAlertButtons(
                viewModel: viewModel,
                isLocked: $isLocked,
                onUnlock: handleUnlock
            )
        } message: {
            Text("Are you sure you want to interrupt your focus session?")
        }
        .onAppear {
            setupInitialState()
            viewModel.configure(with: modelContext)
            loadActiveSubtask()
        }
    }

    // MARK: - Active Task View
    private var activeTaskView: some View {
        CurrentTaskView()
            .padding(.top, 16)
    }

    // MARK: - Private Methods
    private func setupInitialState() {
        isLocked = viewModel.isRunning
    }

    private func handleUnlock() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isLocked = false
        }
    }

    private func handleLock() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isLocked = true
        }
    }

    private func handleLockStateChange(_ newValue: Bool) {
        if newValue {
            handleLock()
        } else {
            handleUnlock()
        }
    }

    private func handleTimerStateChange(_ isRunning: Bool) {
        if isRunning {
            handleLock()
        }
    }

    // Load the subtask and its parent task from the model context
    private func loadActiveSubtask() {
        guard let subtaskID = viewModel.activeSubtaskID else {
            withAnimation(.spring(response: 0.3)) {
                activeSubtask = nil
                parentTask = nil
            }
            return
        }

        do {
            // Fetch the subtask
            let subtaskDescriptor = FetchDescriptor<PolmodorSubTask>(
                predicate: #Predicate { subtask in
                    subtask.id == subtaskID
                }
            )

            let results = try modelContext.fetch(subtaskDescriptor)
            guard let subtask = results.first else {
                withAnimation(.spring(response: 0.3)) {
                    activeSubtask = nil
                    parentTask = nil
                }
                return
            }

            // Find the parent task
            let taskDescriptor = FetchDescriptor<PolmodorTask>(
                predicate: #Predicate { task in
                    task.subTasks.contains(where: { $0.id == subtaskID })
                }
            )

            let taskResults = try modelContext.fetch(taskDescriptor)
            let foundParentTask = taskResults.first

            // Update state with animations
            withAnimation(.spring(response: 0.3)) {
                self.activeSubtask = subtask
                self.parentTask = foundParentTask
            }
        } catch {
            print("Error fetching active subtask: \(error)")
            withAnimation(.spring(response: 0.3)) {
                activeSubtask = nil
                parentTask = nil
            }
        }
    }
}

// MARK: - Background Gradient View
struct BackgroundGradientView: View {
    let stateColor: Color

    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                stateColor.opacity(0.8),
                stateColor.opacity(0.4),
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

// MARK: - Timer Circle View
struct TimerCircleView: View {
    let progress: Double
    let timeString: String
    let stateTitle: String
    let stateColor: Color
    let geometry: GeometryProxy

    var body: some View {
        ZStack {
            Circle()
                .stroke(stateColor.opacity(0.2), lineWidth: 20)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    stateColor,
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 8) {
                Text(timeString)
                    .font(.custom("Bungee-Regular", size: 60))
                    .foregroundColor(.white)

                Text(stateTitle)
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .frame(
            width: min(geometry.size.width * 0.8, 300),
            height: min(geometry.size.width * 0.8, 300)
        )
        .padding()
    }
}

// MARK: - Timer Controls View
struct TimerControlsView: View {
    @ObservedObject var viewModel: TimerViewModel
    let isLocked: Bool
    @Binding var showUnlockAlert: Bool

    var body: some View {
        HStack(spacing: 24) {
            ControlButton(
                action: { viewModel.resetTimer() },
                systemImage: "arrow.counterclockwise",
                disabled: false
            )

            PlayPauseButton(
                viewModel: viewModel,
                showUnlockAlert: $showUnlockAlert
            )

            ControlButton(
                action: { viewModel.skipToNext() },
                systemImage: "forward.fill",
                disabled: false
            )
        }
        .padding(.bottom, 40)
        .transition(.move(edge: .bottom))
    }
}

// MARK: - Control Button
struct ControlButton: View {
    let action: () -> Void
    let systemImage: String
    let disabled: Bool

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.2))
                )
        }
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1)
    }
}

// MARK: - Play Pause Button
struct PlayPauseButton: View {
    @ObservedObject var viewModel: TimerViewModel
    @Binding var showUnlockAlert: Bool

    var body: some View {
        Button(action: { viewModel.toggleTimer() }) {
            Image(systemName: viewModel.isRunning ? "pause.fill" : "play.fill")
                .font(.title)
                .foregroundColor(viewModel.currentStateColor)
                .frame(width: 72, height: 72)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                )
                .shadow(radius: 10)
        }
    }
}

// MARK: - Unlock Alert Buttons
struct UnlockAlertButtons: View {
    @ObservedObject var viewModel: TimerViewModel
    @Binding var isLocked: Bool
    let onUnlock: () -> Void

    var body: some View {
        Group {
            Button("Cancel", role: .cancel) {}
            Button("Unlock", role: .destructive) {
                viewModel.pauseTimer()
                withAnimation(.spring()) {
                    isLocked = false
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    TimerView()
        .environmentObject(TimerViewModel())
}
