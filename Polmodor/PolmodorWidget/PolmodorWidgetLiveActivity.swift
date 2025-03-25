//
//  PolmodorWidgetLiveActivity.swift
//  PolmodorWidget
//
//  Created by sedat ateş on 2.03.2025.
//

import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Live Activity Entry Point
struct PolmodorWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PolmodorLiveActivityAttributes.self) { context in
            // The dynamic island live activity
            DynamicIslandLiveActivityView(context: context)
                .activityBackgroundTint(Color.clear)
                .contentMargins(.all, 0)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.center) {
                    expandedView(context: context)
                }
            } compactLeading: {
                // Compact leading
                Image(
                    systemName: sessionIcon(
                        for: context.state.sessionType, isPaused: context.state.pausedAt != nil)
                )
                .font(.system(size: 14))
                .foregroundStyle(
                    stateColor(
                        for: context.state.sessionType,
                        isPaused: context.state.pausedAt != nil
                    ))
            } compactTrailing: {
                // Compact trailing
                Text(
                    "\(context.state.remainingTime / 60):\(String(format: "%02d", context.state.remainingTime % 60))"
                )
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(
                    stateColor(
                        for: context.state.sessionType,
                        isPaused: context.state.pausedAt != nil
                    )
                )
                .contentTransition(.numericText())
                
            } minimal: {
                // Minimal UI
                Text(
                    "\(context.state.remainingTime / 60):\(String(format: "%02d", context.state.remainingTime % 60))"
                )
                .monospacedDigit()
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(
                    stateColor(
                        for: context.state.sessionType,
                        isPaused: context.state.pausedAt != nil
                    )
                )
                .contentTransition(.numericText())
                .style(.timer)
            }
            .keylineTint(
                stateColor(
                    for: context.state.sessionType,
                    isPaused: context.state.pausedAt != nil
                ))
        }
    }

    // Helper functions for the DynamicIsland configuration
    private func stateColor(
        for sessionType: PolmodorLiveActivityAttributes.ContentState.SessionType, isPaused: Bool
    ) -> Color {
        if isPaused {
            return .orange
        }

        switch sessionType {
        case .work:
            return .red
        case .shortBreak:
            return .green
        case .longBreak:
            return .blue
        }
    }

    private func sessionIcon(
        for sessionType: PolmodorLiveActivityAttributes.ContentState.SessionType, isPaused: Bool
    ) -> String {
        if isPaused {
            return "pause.circle.fill"
        }

        switch sessionType {
        case .work:
            return "timer.circle.fill"
        case .shortBreak:
            return "leaf.fill"
        case .longBreak:
            return "cup.and.saucer.fill"
        }
    }

    // Expanded view inside the DynamicIsland
    @ViewBuilder
    private func expandedView(context: ActivityViewContext<PolmodorLiveActivityAttributes>)
        -> some View
    {
        // We'll use our full DynamicIslandLiveActivityView here
        DynamicIslandLiveActivityView(context: context)
    }
}

// MARK: - Dynamic Island Live Activity View
struct DynamicIslandLiveActivityView: View {
    let context: ActivityViewContext<PolmodorLiveActivityAttributes>
    @Environment(\.dynamicIslandExpandedDisplaySize) private var expandedDisplaySize

    private var isPaused: Bool {
        context.state.pausedAt != nil
    }

    private var stateColor: Color {
        if isPaused {
            return .orange
        }

        switch context.state.sessionType {
        case .work:
            return .red
        case .shortBreak:
            return .green
        case .longBreak:
            return .blue
        }
    }

    private var sessionLabel: String {
        switch context.state.sessionType {
        case .work:
            return "Focus"
        case .shortBreak:
            return "Short Break"
        case .longBreak:
            return "Long Break"
        }
    }

    private var sessionIcon: String {
        switch context.state.sessionType {
        case .work:
            return "timer.circle.fill"
        case .shortBreak:
            return "leaf.fill"
        case .longBreak:
            return "cup.and.saucer.fill"
        }
    }

    var body: some View {
        switch context.dynamicIslandExpandedDisplayState {
        case .expanded:
            // Expanded view (tapped Dynamic Island)
            expandedView
        case .minimal:
            // Minimized view (compact pill or circular)
            minimalView
        default:
            // Default compact view
            compactView
        }
    }

    // Expanded view - when the dynamic island is tapped
    private var expandedView: some View {
        VStack(spacing: 12) {
            // Task title and session info
            VStack(spacing: 4) {
                if !context.state.taskTitle.isEmpty {
                    Text(context.state.taskTitle)
                        .font(.headline)
                        .lineLimit(1)
                }

                HStack(spacing: 4) {
                    Image(systemName: sessionIcon)
                        .font(.system(size: 12))

                    Text(sessionLabel)
                        .font(.subheadline)
                }
                .foregroundStyle(stateColor)
            }

            // Timer
            Text(
                "\(context.state.remainingTime / 60):\(String(format: "%02d", context.state.remainingTime % 60))"
            )
            .font(.system(size: 34, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(stateColor.gradient)
            .contentTransition(.numericText())
            .animation(.snappy, value: context.state.remainingTime)
            .style(.timer)  // Timer style for animation

            // Control buttons
            HStack(spacing: 24) {
                // Skip button
                Button {
                    Task { try? await SkipTimerIntent().perform() }
                } label: {
                    Image(systemName: "forward.end.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.secondary)
                }

                // Play/Pause button - slightly larger
                Button {
                    Task { try? await PauseResumeTimerIntent().perform() }
                } label: {
                    Image(systemName: isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(stateColor)
                }

                // Lock/Unlock button
                Button {
                    Task { try? await LockUnlockTimerIntent().perform() }
                } label: {
                    Image(systemName: context.state.isLocked ? "lock.fill" : "lock.open.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 4)
        }
        .padding(16)
    }

    // Compact view - standard dynamic island state
    private var compactView: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: sessionIcon)
                .font(.system(size: 16))
                .foregroundStyle(stateColor)

            Text(
                "\(context.state.remainingTime / 60):\(String(format: "%02d", context.state.remainingTime % 60))"
            )
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(stateColor)
            .contentTransition(.numericText())
            .animation(.snappy, value: context.state.remainingTime)
            .style(.timer)  // Timer style for animation
        }
        .padding(.horizontal, 8)
    }

    // Minimal view - smallest possible dynamic island display
    private var minimalView: some View {
        // For minimal, just show the time with proper color
        Text(
            "\(context.state.remainingTime / 60):\(String(format: "%02d", context.state.remainingTime % 60))"
        )
        .font(.system(size: 14, weight: .semibold, design: .rounded))
        .monospacedDigit()
        .foregroundStyle(stateColor)
        .contentTransition(.numericText())
        .animation(.snappy, value: context.state.remainingTime)
        .style(.timer)
    }
}

// MARK: - Dynamic Island Views
struct ExpandedLeadingView: View {
    let context: ActivityViewContext<PolmodorLiveActivityAttributes>

    private var isPaused: Bool {
        context.state.pausedAt != nil
    }

    private var isCompleted: Bool {
        context.state.remainingTime <= 0
    }

    private func sessionTitle(
        for sessionType: PolmodorLiveActivityAttributes.ContentState.SessionType, isPaused: Bool
    ) -> String {
        switch sessionType {
        case .work:
            return "Focus"
        case .shortBreak:
            return "Short Break"
        case .longBreak:
            return "Long Break"
        }
    }

    var body: some View {
        // Session status icon with color based on state
        Image(
            systemName: sessionIcon(
                for: context.state.sessionType, isPaused: context.state.pausedAt != nil)
        )
        .font(.system(size: 18, weight: .semibold))
        .foregroundStyle(
            stateColor(for: context.state.sessionType, isPaused: context.state.pausedAt != nil)
                .gradient
        )
        .symbolEffect(.pulse, options: .repeating, isActive: !isPaused && !isCompleted)
    }
}

struct ExpandedTrailingView: View {
    let context: ActivityViewContext<PolmodorLiveActivityAttributes>

    var body: some View {
        // Show clean remaining time in trailing area
        Text(
            "\(context.state.remainingTime / 60):\(String(format: "%02d", context.state.remainingTime % 60))"
        )
        .font(.system(size: 16, weight: .semibold, design: .rounded))
        .monospacedDigit()
        .foregroundStyle(
            stateColor(for: context.state.sessionType, isPaused: context.state.pausedAt != nil)
                .gradient
        )
        .contentTransition(.numericText())
    }
}

struct ExpandedCenterView: View {
    let context: ActivityViewContext<PolmodorLiveActivityAttributes>

    private var isPaused: Bool {
        context.state.pausedAt != nil
    }

    private var isCompleted: Bool {
        context.state.remainingTime <= 0
    }

    var body: some View {
        // Task title area
        VStack(spacing: 2) {
            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.green)
            } else {
                Image(
                    systemName: sessionIcon(
                        for: context.state.sessionType, isPaused: context.state.pausedAt != nil)
                )
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(
                    stateColor(
                        for: context.state.sessionType, isPaused: context.state.pausedAt != nil
                    ).gradient
                )
                .symbolEffect(.pulse, options: .repeating, isActive: !isPaused)
            }

            Text(context.state.taskTitle)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}

// Helper methods for all Dynamic Island components
extension View {
    func stateColor(
        for sessionType: PolmodorLiveActivityAttributes.ContentState.SessionType, isPaused: Bool
    ) -> Color {
        if isPaused {
            return .orange
        }

        switch sessionType {
        case .work:
            return .red
        case .shortBreak:
            return .green
        case .longBreak:
            return .blue
        }
    }

    func sessionIcon(
        for sessionType: PolmodorLiveActivityAttributes.ContentState.SessionType, isPaused: Bool
    ) -> String {
        if isPaused {
            return "pause.circle.fill"
        }

        switch sessionType {
        case .work:
            return "timer.circle.fill"
        case .shortBreak:
            return "leaf.fill"
        case .longBreak:
            return "cup.and.saucer.fill"
        }
    }
}

// MARK: - Previews
struct PolmodorWidgetLiveActivity_Previews: PreviewProvider {
    static let attributes = PolmodorLiveActivityAttributes(name: "Polmodor")
    static let contentState = PolmodorLiveActivityAttributes.ContentState(
        taskTitle: "Complete project report",
        remainingTime: 1500,
        sessionType: .work,
        startedAt: Date(),
        pausedAt: nil,
        duration: 1500,
        isLocked: false
    )

    static var previews: some View {
        attributes
            .previewContext(contentState, viewKind: .dynamicIsland(.compact))
            .previewDisplayName("Island Compact")
        attributes
            .previewContext(contentState, viewKind: .dynamicIsland(.expanded))
            .previewDisplayName("Island Expanded")
        attributes
            .previewContext(contentState, viewKind: .dynamicIsland(.minimal))
            .previewDisplayName("Minimal")
        attributes
            .previewContext(contentState, viewKind: .content)
            .previewDisplayName("Notification")
    }
}

// MARK: - TimerCircle
// This component is kept for backward compatibility but no longer used in the new design
struct TimerCircle: View {
    var progress: Double
    var color: Color

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 5)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Progress circle
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .rotationEffect(.degrees(-90))
                .animation(.linear, value: progress)
        }
    }
}
