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
      DynamicIslandLiveActivityView(context: context)
        .activityBackgroundTint(Color.clear)
        .contentMargins(.all, 0)
    } dynamicIsland: { context in
      DynamicIsland {
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
      .keylineTint(
        stateColor(for: context.state.sessionType, isPaused: context.state.pausedAt != nil))
    }
  }

  private func stateColor(
    for sessionType: PolmodorLiveActivityAttributes.ContentState.SessionType, isPaused: Bool
  ) -> Color {
    if isPaused { return .orange }
    switch sessionType {
    case .work: return .red
    case .shortBreak: return .green
    case .longBreak: return .blue
    }
  }
}

// MARK: - Compact Views

struct CompactLeadingView: View {
  let context: ActivityViewContext<PolmodorLiveActivityAttributes>

  var body: some View {
    ZStack {
      // Background with gradient
      RoundedRectangle(cornerRadius: 12)
        .fill(
          stateColor(for: context.state.sessionType, isPaused: context.state.pausedAt != nil)
            .gradient
            .opacity(0.2)
        )
        .frame(width: 28, height: 28)

      Image(
        systemName: sessionIcon(
          for: context.state.sessionType, isPaused: context.state.pausedAt != nil
        )
      )
      .font(.system(size: 16, weight: .semibold))
      .foregroundStyle(
        stateColor(for: context.state.sessionType, isPaused: context.state.pausedAt != nil)
          .gradient
      )
      .symbolEffect(.pulse, options: .repeating.speed(0.8), isActive: context.state.pausedAt == nil)
    }
    .animation(.smooth(duration: 0.5), value: context.state.pausedAt)
  }
}

struct CompactTrailingView: View {
  let context: ActivityViewContext<PolmodorLiveActivityAttributes>

  var body: some View {
    // Timer running ve paused değil ise .timer style kullan
    if context.state.startedAt != nil && context.state.pausedAt == nil {
      // Timer style kullan
      Text(timerDate(from: context.state), style: .timer)
        .font(.system(size: 16, weight: .bold, design: .rounded))
        .monospacedDigit()
        .foregroundStyle(
          stateColor(for: context.state.sessionType, isPaused: false)
            .gradient
        )
    } else {
      // Normal text göster
      Text(formatTime(context.state.remainingTime))
        .font(.system(size: 16, weight: .bold, design: .rounded))
        .monospacedDigit()
        .foregroundStyle(
          stateColor(for: context.state.sessionType, isPaused: context.state.pausedAt != nil)
            .gradient
        )
        .contentTransition(.numericText())
    }
  }
}

// MARK: - Minimal View

struct MinimalView: View {
  let context: ActivityViewContext<PolmodorLiveActivityAttributes>

  var body: some View {
    // Timer running ve paused değil ise .timer style kullan
    if context.state.startedAt != nil && context.state.pausedAt == nil {
      // Timer style kullan
      Text(timerDate(from: context.state), style: .timer)
        .font(.system(size: 12, weight: .bold, design: .rounded))
        .monospacedDigit()
        .foregroundStyle(
          stateColor(for: context.state.sessionType, isPaused: false)
        )
    } else {
      // Normal text göster - sadece dakika
      Text(formatTimeMinutesOnly(context.state.remainingTime))
        .font(.system(size: 12, weight: .bold, design: .rounded))
        .monospacedDigit()
        .foregroundStyle(
          stateColor(for: context.state.sessionType, isPaused: context.state.pausedAt != nil)
        )
        .contentTransition(.numericText())
    }
  }
}

// MARK: - Expanded Views

struct ExpandedLeadingView: View {
  let context: ActivityViewContext<PolmodorLiveActivityAttributes>

  private var isCompleted: Bool { context.state.remainingTime <= 0 }

  var body: some View {
    VStack(spacing: 6) {
      ZStack {
        // Background with animated gradient
        RoundedRectangle(cornerRadius: 12)
          .fill(
            isCompleted
              ? Color.green.gradient.opacity(0.15)
              : stateColor(for: context.state.sessionType, isPaused: context.state.pausedAt != nil)
                .gradient
                .opacity(0.15)
          )
          .frame(width: 40, height: 40)

        if isCompleted {
          Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(Color.green.gradient)
            .symbolEffect(.bounce, value: isCompleted)
        } else {
          Image(
            systemName: sessionIcon(
              for: context.state.sessionType, isPaused: context.state.pausedAt != nil
            )
          )
          .font(.system(size: 20, weight: .bold))
          .foregroundStyle(
            stateColor(for: context.state.sessionType, isPaused: context.state.pausedAt != nil)
              .gradient
          )
          .symbolEffect(
            .pulse, options: .repeating.speed(0.8), isActive: context.state.pausedAt == nil)
        }
      }
      .animation(.smooth(duration: 0.6), value: isCompleted)
      .animation(.smooth(duration: 0.4), value: context.state.pausedAt)

      Text(sessionLabel(for: context.state.sessionType))
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
  }
}

struct ExpandedTrailingView: View {
  let context: ActivityViewContext<PolmodorLiveActivityAttributes>

  var body: some View {
    VStack(spacing: 2) {
      // Timer running ve paused değil ise .timer style kullan
      if context.state.startedAt != nil && context.state.pausedAt == nil {
        // Timer style kullan
        Text(timerDate(from: context.state), style: .timer)
          .font(.system(size: 20, weight: .bold, design: .rounded))
          .monospacedDigit()
          .foregroundStyle(
            stateColor(for: context.state.sessionType, isPaused: false)
              .gradient
          )
      } else {
        // Normal text göster
        Text(formatTime(context.state.remainingTime))
          .font(.system(size: 20, weight: .bold, design: .rounded))
          .monospacedDigit()
          .foregroundStyle(
            stateColor(for: context.state.sessionType, isPaused: context.state.pausedAt != nil)
              .gradient
          )
          .contentTransition(.numericText())
      }

      // Status indicator
      HStack(spacing: 3) {
        Circle()
          .fill(
            context.state.pausedAt != nil
              ? .orange : stateColor(for: context.state.sessionType, isPaused: false)
          )
          .frame(width: 4, height: 4)
          .scaleEffect(context.state.pausedAt == nil ? 1.0 : 0.8)
          .animation(
            .smooth(duration: 0.3).repeatForever(autoreverses: true),
            value: context.state.pausedAt == nil)

        Text(context.state.pausedAt != nil ? "Paused" : "Running")
          .font(.system(size: 9, weight: .medium))
          .foregroundStyle(.secondary)
          .contentTransition(.opacity)
      }
      .animation(.smooth(duration: 0.3), value: context.state.pausedAt)
    }
  }
}

struct ExpandedCenterView: View {
  let context: ActivityViewContext<PolmodorLiveActivityAttributes>

  var body: some View {
    Button {
      Task { try? await OpenAppIntent().perform() }
    } label: {
      Text(context.state.taskTitle.isEmpty ? "Polmodor Timer" : context.state.taskTitle)
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(.primary)
        .lineLimit(2)
        .multilineTextAlignment(.center)
        .minimumScaleFactor(0.8)
    }
    .buttonStyle(.plain)
    .contentShape(Rectangle())
  }
}

struct ExpandedBottomView: View {
  let context: ActivityViewContext<PolmodorLiveActivityAttributes>

  var body: some View {
    if !context.state.taskTitle.isEmpty {
      Text(context.state.taskTitle)
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .truncationMode(.middle)
    } else {
      Text("No active task")
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(.tertiary)
    }
  }
}

// MARK: - Dynamic Island Live Activity View

struct DynamicIslandLiveActivityView: View {
  let context: ActivityViewContext<PolmodorLiveActivityAttributes>

  var body: some View {
    VStack(spacing: 12) {
      HStack(spacing: 12) {
        // Icon with gradient background
        ZStack {
          RoundedRectangle(cornerRadius: 10)
            .fill(
              stateColor(for: context.state.sessionType, isPaused: context.state.pausedAt != nil)
                .gradient
                .opacity(0.12)
            )
            .frame(width: 36, height: 36)

          Image(
            systemName: sessionIcon(
              for: context.state.sessionType, isPaused: context.state.pausedAt != nil
            )
          )
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(
            stateColor(for: context.state.sessionType, isPaused: context.state.pausedAt != nil)
              .gradient
          )
          .symbolEffect(
            .pulse, options: .repeating.speed(0.8), isActive: context.state.pausedAt == nil)
        }
        .animation(.smooth(duration: 0.4), value: context.state.pausedAt)

        VStack(alignment: .leading, spacing: 2) {
          Text(context.state.taskTitle.isEmpty ? "Polmodor Timer" : context.state.taskTitle)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.primary)
            .lineLimit(1)

          HStack(spacing: 6) {
            Text(sessionLabel(for: context.state.sessionType))
              .font(.system(size: 11, weight: .medium))
              .foregroundStyle(
                stateColor(for: context.state.sessionType, isPaused: context.state.pausedAt != nil)
              )

            if context.state.pausedAt != nil {
              Text("• Paused")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.orange)
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
          }
          .animation(.smooth(duration: 0.3), value: context.state.pausedAt)
        }

        Spacer()

        // Timer running ve paused değil ise .timer style kullan
        if context.state.startedAt != nil && context.state.pausedAt == nil {
          // Timer style kullan
          Text(timerDate(from: context.state), style: .timer)
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(
              stateColor(for: context.state.sessionType, isPaused: false)
                .gradient
            )
        } else {
          // Normal text göster
          Text(formatTime(context.state.remainingTime))
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(
              stateColor(for: context.state.sessionType, isPaused: context.state.pausedAt != nil)
                .gradient
            )
            .contentTransition(.numericText())
        }
      }

      // Task name at bottom
      if !context.state.taskTitle.isEmpty {
        Text(context.state.taskTitle)
          .font(.system(size: 11, weight: .medium))
          .foregroundStyle(.secondary)
          .lineLimit(1)
          .truncationMode(.middle)
      }
    }
    .padding(14)
    .background(.ultraThinMaterial, in: .rect(cornerRadius: 20))
  }
}

// MARK: - Helper Functions

extension View {
  func stateColor(
    for sessionType: PolmodorLiveActivityAttributes.ContentState.SessionType, isPaused: Bool
  ) -> Color {
    if isPaused { return .orange }
    switch sessionType {
    case .work: return .red
    case .shortBreak: return .green
    case .longBreak: return .blue
    }
  }

  func sessionIcon(
    for sessionType: PolmodorLiveActivityAttributes.ContentState.SessionType, isPaused: Bool
  ) -> String {
    if isPaused { return "pause.circle.fill" }
    switch sessionType {
    case .work: return "timer.circle.fill"
    case .shortBreak: return "leaf.fill"
    case .longBreak: return "cup.and.saucer.fill"
    }
  }

  func sessionLabel(for sessionType: PolmodorLiveActivityAttributes.ContentState.SessionType)
    -> String
  {
    switch sessionType {
    case .work: return "Focus"
    case .shortBreak: return "Short Break"
    case .longBreak: return "Long Break"
    }
  }

  func timerDate(from state: PolmodorLiveActivityAttributes.ContentState) -> Date {
    if let startedAt = state.startedAt, state.pausedAt == nil {
      // Calculate the end time based on start time and duration
      let endTime = startedAt.addingTimeInterval(TimeInterval(state.duration))
      // Make sure end time is not in the past
      return max(endTime, Date().addingTimeInterval(1))
    } else {
      // Fallback to current time + remaining time
      return Date().addingTimeInterval(TimeInterval(max(1, state.remainingTime)))
    }
  }

  func formatTime(_ seconds: Int) -> String {
    let minutes = seconds / 60
    let remainingSeconds = seconds % 60
    return String(format: "%02d:%02d", minutes, remainingSeconds)
  }

  func formatTimeMinutesOnly(_ seconds: Int) -> String {
    let minutes = seconds / 60
    return String(format: "%02d", minutes)
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
