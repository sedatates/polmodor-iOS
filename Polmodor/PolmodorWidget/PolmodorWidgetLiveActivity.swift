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
    Image(
      systemName: sessionIcon(
        for: context.state.sessionType, isPaused: context.state.pausedAt != nil)
    )
    .font(.system(size: 16, weight: .semibold))
    .foregroundStyle(
      stateColor(for: context.state.sessionType, isPaused: context.state.pausedAt != nil)
    )
    .symbolEffect(.pulse, options: .repeating, isActive: context.state.pausedAt == nil)
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
        )
    } else {
      // Normal text göster
      Text(formatTime(context.state.remainingTime))
        .font(.system(size: 16, weight: .bold, design: .rounded))
        .monospacedDigit()
        .foregroundStyle(
          stateColor(for: context.state.sessionType, isPaused: context.state.pausedAt != nil)
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
        .font(.system(size: 14, weight: .bold, design: .rounded))
        .monospacedDigit()
        .foregroundStyle(
          stateColor(for: context.state.sessionType, isPaused: false)
        )
    } else {
      // Normal text göster
      Text(formatTime(context.state.remainingTime))
        .font(.system(size: 14, weight: .bold, design: .rounded))
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
    VStack(spacing: 4) {
      if isCompleted {
        Image(systemName: "checkmark.circle.fill")
          .font(.system(size: 24, weight: .bold))
          .foregroundStyle(.green)
          .symbolEffect(.bounce, value: isCompleted)
      } else {
        Image(
          systemName: sessionIcon(
            for: context.state.sessionType, isPaused: context.state.pausedAt != nil)
        )
        .font(.system(size: 24, weight: .bold))
        .foregroundStyle(
          stateColor(for: context.state.sessionType, isPaused: context.state.pausedAt != nil)
            .gradient
        )
        .symbolEffect(.pulse, options: .repeating, isActive: context.state.pausedAt == nil)
      }

      Text(sessionLabel(for: context.state.sessionType))
        .font(.system(size: 10, weight: .medium))
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
  }
}

struct ExpandedTrailingView: View {
  let context: ActivityViewContext<PolmodorLiveActivityAttributes>

  var body: some View {
    VStack(spacing: 4) {
      // Timer running ve paused değil ise .timer style kullan
      if context.state.startedAt != nil && context.state.pausedAt == nil {
        // Timer style kullan
        Text(timerDate(from: context.state), style: .timer)
          .font(.system(size: 20, weight: .bold, design: .rounded))
          .monospacedDigit()
          .foregroundStyle(
            stateColor(for: context.state.sessionType, isPaused: false)
          )
      } else {
        // Normal text göster
        Text(formatTime(context.state.remainingTime))
          .font(.system(size: 20, weight: .bold, design: .rounded))
          .monospacedDigit()
          .foregroundStyle(
            stateColor(for: context.state.sessionType, isPaused: context.state.pausedAt != nil)
          )
          .contentTransition(.numericText())
      }

      if context.state.pausedAt != nil {
        Text("Paused")
          .font(.system(size: 10, weight: .medium))
          .foregroundStyle(.orange)
      } else {
        Text("Running")
          .font(.system(size: 10, weight: .medium))
          .foregroundStyle(stateColor(for: context.state.sessionType, isPaused: false))
      }
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
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(.primary)
        .lineLimit(2)
        .multilineTextAlignment(.center)
        .minimumScaleFactor(0.8)
    }
    .buttonStyle(.plain)
  }
}

struct ExpandedBottomView: View {
  let context: ActivityViewContext<PolmodorLiveActivityAttributes>

  var body: some View {
    Button {
      Task { try? await OpenAppIntent().perform() }
    } label: {
      HStack(spacing: 8) {
        Image(systemName: "app.fill")
          .font(.system(size: 16, weight: .medium))
        Text("Open App")
          .font(.system(size: 14, weight: .medium))
      }
      .foregroundStyle(.secondary)
    }
    .buttonStyle(.plain)
  }
}

// MARK: - Dynamic Island Live Activity View
struct DynamicIslandLiveActivityView: View {
  let context: ActivityViewContext<PolmodorLiveActivityAttributes>

  var body: some View {
    VStack(spacing: 12) {
      HStack {
        Image(
          systemName: sessionIcon(
            for: context.state.sessionType, isPaused: context.state.pausedAt != nil)
        )
        .font(.system(size: 20, weight: .semibold))
        .foregroundStyle(
          stateColor(for: context.state.sessionType, isPaused: context.state.pausedAt != nil))

        VStack(alignment: .leading, spacing: 2) {
          Text(context.state.taskTitle.isEmpty ? "Polmodor Timer" : context.state.taskTitle)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.primary)
            .lineLimit(1)

          Text(sessionLabel(for: context.state.sessionType))
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(
              stateColor(for: context.state.sessionType, isPaused: context.state.pausedAt != nil))
        }

        Spacer()

        // Timer running ve paused değil ise .timer style kullan
        if context.state.startedAt != nil && context.state.pausedAt == nil {
          // Timer style kullan
          Text(timerDate(from: context.state), style: .timer)
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(
              stateColor(for: context.state.sessionType, isPaused: false)
            )
        } else {
          // Normal text göster
          Text(formatTime(context.state.remainingTime))
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(
              stateColor(for: context.state.sessionType, isPaused: context.state.pausedAt != nil)
            )
            .contentTransition(.numericText())
        }
      }

      Button {
        Task { try? await OpenAppIntent().perform() }
      } label: {
        HStack(spacing: 6) {
          Image(systemName: "app.fill")
            .font(.system(size: 14))
          Text("Open App")
            .font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(.secondary)
      }
      .buttonStyle(.plain)
    }
    .padding(16)
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
      return startedAt.addingTimeInterval(TimeInterval(state.duration))
    } else {
      return Date().addingTimeInterval(TimeInterval(state.remainingTime))
    }
  }

  func formatTime(_ seconds: Int) -> String {
    let minutes = seconds / 60
    let remainingSeconds = seconds % 60
    return String(format: "%02d:%02d", minutes, remainingSeconds)
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
