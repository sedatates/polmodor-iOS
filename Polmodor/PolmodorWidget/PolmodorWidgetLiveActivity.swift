//
//  PolmodorWidgetLiveActivity.swift
//  PolmodorWidget
//
//  Created by sedat ateş on 2.03.2025.
//

import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Live Activity Widget
struct PolmodorWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PolmodorLiveActivityAttributes.self) { context in
            // Lock screen/banner UI goes here
            LockScreenLiveActivityView(context: context)
                .activityBackgroundTint(.black.opacity(0.05))
                .activitySystemActionForegroundColor(.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here
                DynamicIslandExpandedRegion(.leading) {
                    ExpandedLeadingView(context: context)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    ExpandedTrailingView(context: context)
                }

                DynamicIslandExpandedRegion(.center) {
                    ExpandedCenterView(context: context)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    ExpandedBottomView(context: context)
                }
            } compactLeading: {
                CompactLeadingView(context: context)
            } compactTrailing: {
                CompactTrailingView(context: context)
            } minimal: {
                MinimalView(context: context)
            }
            .widgetURL(nil)
        }
    }
}

// MARK: - Dynamic Island Views

// MARK: Expanded Leading View
struct ExpandedLeadingView: View {
    let context: ActivityViewContext<PolmodorLiveActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Session type indicator with icon
            HStack(spacing: 4) {
                Image(systemName: sessionIcon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(stateColor)

                Text(sessionTitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            // Task title
            if !context.state.taskTitle.isEmpty {
                Text(context.state.taskTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                    .foregroundStyle(.primary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 4)
    }

    private var sessionIcon: String {
        if context.state.pausedAt != nil {
            return "pause.circle.fill"
        }

        return context.state.isBreak
            ? (context.state.breakType == "long" ? "cup.and.saucer.fill" : "leaf.fill")
            : "brain.head.profile"
    }

    private var sessionTitle: String {
        if context.state.pausedAt != nil {
            return "Paused"
        }

        if context.state.isBreak {
            return context.state.breakType == "long" ? "Long Break" : "Short Break"
        }

        return "Focus"
    }

    private var stateColor: Color {
        if context.state.pausedAt != nil {
            return .orange
        }

        if context.state.isBreak {
            return context.state.breakType == "long" ? .blue : .green
        }

        return .red
    }
}

// MARK: Expanded Trailing View
struct ExpandedTrailingView: View {
    let context: ActivityViewContext<PolmodorLiveActivityAttributes>

    var body: some View {
        VStack(alignment: .trailing) {
            // Progress percentage
            Text("\(Int(progress * 100))%")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.trailing, 4)
    }

    private var progress: Double {
        let totalDuration = Double(context.state.duration)
        let elapsedTime = Double(context.state.duration - context.state.remainingTime)
        return max(0.0, min(1.0, elapsedTime / totalDuration))
    }
}

// MARK: Expanded Center View
struct ExpandedCenterView: View {
    let context: ActivityViewContext<PolmodorLiveActivityAttributes>

    var body: some View {
        HStack {
            // Timer display using Date with .timer style
            if let startedAt = context.state.startedAt {
                Text(
                    Date(timeIntervalSinceNow: Double(context.state.remainingTime))
                        .addingTimeInterval(-Date().timeIntervalSince(startedAt)),
                    style: .timer
                )
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(stateColor)
                .frame(maxWidth: .infinity)
            } else {
                // Fallback if startedAt is nil
                Text(timeString)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(stateColor)
                    .frame(maxWidth: .infinity)
                    .contentTransition(.numericText())
            }
        }
    }

    // Keep the original timeString as fallback
    private var timeString: String {
        let minutes = context.state.remainingTime / 60
        let seconds = context.state.remainingTime % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var stateColor: Color {
        if context.state.pausedAt != nil {
            return .orange
        }

        if context.state.isBreak {
            return context.state.breakType == "long" ? .blue : .green
        }

        return .red
    }
}

// MARK: Expanded Bottom View
struct ExpandedBottomView: View {
    let context: ActivityViewContext<PolmodorLiveActivityAttributes>

    var body: some View {
        VStack(spacing: 8) {
            // Progress bar
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: stateColor))
                .frame(height: 4)

            // Control buttons
            HStack {
                // Cancel button
                Button {
                    // Handled by system
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(
                            Capsule()
                                .fill(.red.opacity(0.9))
                        )
                }
                .buttonStyle(.plain)

                Spacer()

                // Play/Pause button
                Button {
                    // Handled by system
                } label: {
                    Label(
                        context.state.pausedAt != nil ? "Resume" : "Pause",
                        systemImage: context.state.pausedAt != nil ? "play.fill" : "pause.fill"
                    )
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(
                        Capsule()
                            .fill(stateColor.opacity(0.9))
                    )
                }
                .buttonStyle(.plain)

                Spacer()

                // Skip button
                Button {
                    // Handled by system
                } label: {
                    Label("Skip", systemImage: "forward.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(
                            Capsule()
                                .fill(Color.secondary.opacity(0.8))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 4)
    }

    private var progress: Double {
        let totalDuration = Double(context.state.duration)
        let elapsedTime = Double(context.state.duration - context.state.remainingTime)
        return max(0.0, min(1.0, elapsedTime / totalDuration))
    }

    private var stateColor: Color {
        if context.state.pausedAt != nil {
            return .orange
        }

        if context.state.isBreak {
            return context.state.breakType == "long" ? .blue : .green
        }

        return .red
    }
}

// MARK: Compact Leading View
struct CompactLeadingView: View {
    let context: ActivityViewContext<PolmodorLiveActivityAttributes>

    var body: some View {
        ZStack {
            Circle()
                .fill(stateColor.opacity(0.2))
                .frame(width: 28, height: 28)

            Image(systemName: sessionIcon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(stateColor)
        }
    }

    private var sessionIcon: String {
        if context.state.pausedAt != nil {
            return "pause.fill"
        }

        return context.state.isBreak
            ? (context.state.breakType == "long" ? "cup.and.saucer.fill" : "leaf.fill")
            : "brain.head.profile"
    }

    private var stateColor: Color {
        if context.state.pausedAt != nil {
            return .orange
        }

        if context.state.isBreak {
            return context.state.breakType == "long" ? .blue : .green
        }

        return .red
    }
}

// MARK: Compact Trailing View
struct CompactTrailingView: View {
    let context: ActivityViewContext<PolmodorLiveActivityAttributes>

    var body: some View {
        if let startedAt = context.state.startedAt {
            Text(
                Date(timeIntervalSinceNow: Double(context.state.remainingTime))
                    .addingTimeInterval(-Date().timeIntervalSince(startedAt)),
                style: .timer
            )
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(stateColor)
        } else {
            Text(timeString)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(stateColor)
                .contentTransition(.numericText())
        }
    }

    // Keep the original timeString as fallback
    private var timeString: String {
        let minutes = context.state.remainingTime / 60
        let seconds = context.state.remainingTime % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var stateColor: Color {
        if context.state.pausedAt != nil {
            return .orange
        }

        if context.state.isBreak {
            return context.state.breakType == "long" ? .blue : .green
        }

        return .red
    }
}

// MARK: Minimal View
struct MinimalView: View {
    let context: ActivityViewContext<PolmodorLiveActivityAttributes>

    var body: some View {
        ZStack {
            Circle()
                .fill(stateColor.opacity(0.2))

            if context.state.pausedAt != nil {
                Image(systemName: "pause.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(stateColor)
            } else {
                // Show minutes remaining
                Text("\(context.state.remainingTime / 60)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(stateColor)
                    .contentTransition(.numericText())
            }
        }
    }

    private var stateColor: Color {
        if context.state.pausedAt != nil {
            return .orange
        }

        if context.state.isBreak {
            return context.state.breakType == "long" ? .blue : .green
        }

        return .red
    }
}

// MARK: - Lock Screen Live Activity View
struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<PolmodorLiveActivityAttributes>

    var body: some View {
        HStack {
            // Left section: Task info
            VStack(alignment: .leading, spacing: 4) {
                // Session type indicator
                HStack(spacing: 4) {
                    Image(systemName: sessionIcon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(stateColor)

                    Text(sessionTitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                // Task title
                if !context.state.taskTitle.isEmpty {
                    Text(context.state.taskTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .lineLimit(1)
                        .foregroundStyle(.primary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            // Right section: Timer and controls
            VStack(alignment: .trailing, spacing: 6) {
                // Timer display
                if let startedAt = context.state.startedAt {
                    Text(
                        Date(timeIntervalSinceNow: Double(context.state.remainingTime))
                            .addingTimeInterval(-Date().timeIntervalSince(startedAt)),
                        style: .timer
                    )
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(stateColor)
                } else {
                    Text(timeString)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(stateColor)
                        .contentTransition(.numericText())
                }

                // Progress bar
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: stateColor))
                    .frame(width: 100, height: 3)

                // Control buttons
                HStack(spacing: 8) {
                    // Play/Pause button
                    Button {
                        // Handled by system
                    } label: {
                        Image(
                            systemName: context.state.pausedAt != nil ? "play.fill" : "pause.fill"
                        )
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(stateColor)
                        )
                    }
                    .buttonStyle(.plain)

                    // Skip button
                    Button {
                        // Handled by system
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(Color.secondary.opacity(0.8))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }

    private var sessionIcon: String {
        if context.state.pausedAt != nil {
            return "pause.fill"
        }

        return context.state.isBreak
            ? (context.state.breakType == "long" ? "cup.and.saucer.fill" : "leaf.fill")
            : "brain.head.profile"
    }

    private var sessionTitle: String {
        if context.state.pausedAt != nil {
            return "Paused"
        }

        if context.state.isBreak {
            return context.state.breakType == "long" ? "Long Break" : "Short Break"
        }

        return "Focus Session"
    }

    private var timeString: String {
        let minutes = context.state.remainingTime / 60
        let seconds = context.state.remainingTime % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var progress: Double {
        let totalDuration = Double(context.state.duration)
        let elapsedTime = Double(context.state.duration - context.state.remainingTime)
        return max(0.0, min(1.0, elapsedTime / totalDuration))
    }

    private var stateColor: Color {
        if context.state.pausedAt != nil {
            return .orange
        }

        if context.state.isBreak {
            return context.state.breakType == "long" ? .blue : .green
        }

        return .red
    }
}

// MARK: - Preview Content
extension PolmodorLiveActivityAttributes {
    fileprivate static var preview: PolmodorLiveActivityAttributes {
        PolmodorLiveActivityAttributes(name: "Polmodor Timer")
    }
}

extension PolmodorLiveActivityAttributes.ContentState {
    fileprivate static var work: PolmodorLiveActivityAttributes.ContentState {
        PolmodorLiveActivityAttributes.ContentState(
            taskTitle: "Complete Project Documentation",
            remainingTime: 1500,
            isBreak: false,
            breakType: "none",
            startedAt: Date(),
            pausedAt: nil,
            duration: 1500
        )
    }

    fileprivate static var shortBreak: PolmodorLiveActivityAttributes.ContentState {
        PolmodorLiveActivityAttributes.ContentState(
            taskTitle: "Short Break",
            remainingTime: 300,
            isBreak: true,
            breakType: "short",
            startedAt: Date(),
            pausedAt: nil,
            duration: 300
        )
    }

    fileprivate static var longBreak: PolmodorLiveActivityAttributes.ContentState {
        PolmodorLiveActivityAttributes.ContentState(
            taskTitle: "Long Break",
            remainingTime: 900,
            isBreak: true,
            breakType: "long",
            startedAt: Date(),
            pausedAt: nil,
            duration: 900
        )
    }

    fileprivate static var paused: PolmodorLiveActivityAttributes.ContentState {
        PolmodorLiveActivityAttributes.ContentState(
            taskTitle: "Paused Session",
            remainingTime: 1200,
            isBreak: false,
            breakType: "none",
            startedAt: Date().addingTimeInterval(-300),  // Started 5 minutes ago
            pausedAt: Date(),
            duration: 1500
        )
    }
}

#Preview("Notification", as: .content, using: PolmodorLiveActivityAttributes.preview) {
    PolmodorWidgetLiveActivity()
} contentStates: {
    PolmodorLiveActivityAttributes.ContentState.work
    PolmodorLiveActivityAttributes.ContentState.shortBreak
    PolmodorLiveActivityAttributes.ContentState.longBreak
    PolmodorLiveActivityAttributes.ContentState.paused
}
