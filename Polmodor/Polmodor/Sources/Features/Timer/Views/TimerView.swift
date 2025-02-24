import SwiftUI

struct TimerView: View {
    @StateObject private var viewModel = TimerViewModel()
    @AppStorage("forceLockEnabled") private var forceLockEnabled = false
    @AppStorage("zenModeEnabled") private var zenModeEnabled = false
    @AppStorage("zenModeDelay") private var zenModeDelay = 3.0

    @State private var showUnlockAlert = false
    @State private var isLocked = false
    @State private var dragOffset: CGFloat = 0
    @State private var lastInteraction = Date()
    @State private var showControls = true
    @State private var showTabBar = true

    @Environment(\.tabBarVisibility) private var tabBarVisibility

    private let unlockThreshold: CGFloat = 200

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        viewModel.currentStateColor.opacity(0.8),
                        viewModel.currentStateColor.opacity(0.4),
                    ]), startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 30) {
                    Spacer()

                    // Timer circle
                    ZStack {
                        // Background circle
                        Circle()
                            .stroke(viewModel.currentStateColor.opacity(0.2), lineWidth: 20)

                        // Progress circle
                        Circle()
                            .trim(from: 0, to: viewModel.progress)
                            .stroke(
                                viewModel.currentStateColor,
                                style: StrokeStyle(lineWidth: 20, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))

                        // Time display
                        VStack(spacing: 8) {
                            Text(viewModel.timeString)
                                .font(.system(size: 60, weight: .bold, design: .rounded))
                                .foregroundColor(.white)

                            Text(viewModel.currentStateTitle)
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .frame(
                        width: min(geometry.size.width * 0.8, 300),
                        height: min(geometry.size.width * 0.8, 300)
                    )
                    .padding()

                    // Control buttons
                    if showControls {
                        HStack(spacing: 40) {
                            // Reset button
                            Button(action: {
                                updateInteraction()
                                viewModel.resetTimer()
                            }) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.title)
                                    .foregroundColor(.white)
                                    .frame(width: 60, height: 60)
                                    .background(Color.white.opacity(0.2))
                                    .clipShape(Circle())
                            }

                            // Play/Pause button
                            Button(action: {
                                updateInteraction()
                                viewModel.toggleTimer()
                            }) {
                                Image(systemName: viewModel.isRunning ? "pause.fill" : "play.fill")
                                    .font(.title)
                                    .foregroundColor(viewModel.currentStateColor)
                                    .frame(width: 80, height: 80)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(radius: 10)
                            }

                            // Skip button
                            Button(action: {
                                updateInteraction()
                                viewModel.skipToNext()
                            }) {
                                Image(systemName: "forward.fill")
                                    .font(.title)
                                    .foregroundColor(.white)
                                    .frame(width: 60, height: 60)
                                    .background(Color.white.opacity(0.2))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.bottom, 40)
                        .transition(.move(edge: .bottom))
                    }

                    Spacer()
                }
                .opacity(forceLockEnabled && isLocked ? 0.3 : 1.0)

                // Force Lock or Zen Mode overlay
                if forceLockEnabled && isLocked {
                    lockOverlay
                } else if zenModeEnabled && !showControls {
                    Color.black.opacity(0.001)  // Invisible but tappable
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring()) {
                                updateInteraction()
                            }
                        }
                }
            }
            .onChange(of: showControls) { newValue in
                withAnimation(.easeInOut(duration: 0.3)) {
                    if zenModeEnabled {
                        tabBarVisibility.setVisible(newValue)
                    }
                }
            }
            .onChange(of: isLocked) { newValue in
                withAnimation(.easeInOut(duration: 0.3)) {
                    if forceLockEnabled {
                        tabBarVisibility.setVisible(!newValue)
                    }
                }
            }
        }
        .alert("Break Pomodoro Session?", isPresented: $showUnlockAlert) {
            Button("Cancel", role: .cancel) {
                dragOffset = 0
                isLocked = true
            }
            Button("Break Session", role: .destructive) {
                viewModel.resetTimer()
                isLocked = false
            }
        } message: {
            Text("Breaking your Pomodoro session will reset your progress. Are you sure?")
        }
        .onAppear {
            isLocked = forceLockEnabled
            startZenModeTimer()
        }
    }

    private var lockOverlay: some View {
        ZStack {
            // Semi-transparent background matching timer color
            viewModel.currentStateColor.opacity(0.2)
                .ignoresSafeArea()

            VStack {
                Spacer()

                // Lock icon and text
                VStack(spacing: 20) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                        .shadow(radius: 5)

                    Text("Slide to unlock")
                        .font(.title3.weight(.medium))
                        .foregroundColor(.white)
                        .shadow(radius: 5)
                }

                // Slide to unlock
                ZStack {
                    // Track
                    Capsule()
                        .fill(viewModel.currentStateColor.opacity(0.3))
                        .frame(width: 280, height: 60)
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )

                    // Slider
                    HStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.white, .white.opacity(0.8)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                            .shadow(radius: 5)
                            .offset(x: dragOffset)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        let newOffset = value.translation.width
                                        dragOffset = max(0, min(newOffset, unlockThreshold))
                                    }
                                    .onEnded { value in
                                        if dragOffset > unlockThreshold * 0.8 {
                                            showUnlockAlert = true
                                        }
                                        withAnimation(.spring()) {
                                            dragOffset = 0
                                        }
                                    }
                            )

                        Spacer()
                    }
                    .padding(.horizontal, 5)
                }
                .frame(width: 280, height: 60)

                Spacer()
            }
            .padding()
        }
    }

    private func updateInteraction() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showControls = true
        }
        lastInteraction = Date()
    }

    private func startZenModeTimer() {
        Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                guard zenModeEnabled && !forceLockEnabled else {
                    if !forceLockEnabled {
                        showControls = true
                    }
                    return
                }

                let timeSinceLastInteraction = Date().timeIntervalSince(lastInteraction)
                withAnimation(.easeInOut(duration: 0.3)) {
                    showControls = timeSinceLastInteraction < zenModeDelay
                }
            }
    }
}

#Preview {
    TimerView()
        .environment(\.tabBarVisibility, TabBarVisibility())
}
