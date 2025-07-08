//
//  PolmodorWidget.swift
//  PolmodorWidget
//
//  Created by sedat ateş on 2.03.2025.
//

import SwiftData
import SwiftUI
import WidgetKit

// MARK: - Helper Extensions

// Enum to match the app's Polmodoro state
enum PomodoroState: String {
    case work = "Focus Time"
    case shortBreak = "Short Break"
    case longBreak = "Long Break"

    var title: String {
        return rawValue
    }
}

// Helper method for hex colors is now in the shared file as Color.hex

// MARK: - Widget Entry

struct PolmodorEntry: TimelineEntry {
    let date: Date
    let pomodoroState: PomodoroState
    let timeRemaining: TimeInterval
    let progress: Double
    let taskTitle: String
    let isRunning: Bool
}

// MARK: - Widget Provider

struct Provider: TimelineProvider {
    typealias Entry = PolmodorEntry

    func placeholder(in _: Context) -> PolmodorEntry {
        PolmodorEntry(
            date: Date(),
            pomodoroState: .work,
            timeRemaining: 1500,
            progress: 0.3,
            taskTitle: "Complete project documentation",
            isRunning: true
        )
    }

    func getSnapshot(in _: Context, completion: @escaping (PolmodorEntry) -> Void) {
        // Create a snapshot entry for the widget gallery
        let entry = PolmodorEntry(
            date: Date(),
            pomodoroState: .work,
            timeRemaining: 1500,
            progress: 0.3,
            taskTitle: "Complete project documentation",
            isRunning: true
        )
        completion(entry)
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<PolmodorEntry>) -> Void) {
        // Get the current timer state from UserDefaults
        let timerState = fetchTimerState()

        // If the timer is not running, just return a single entry
        if !timerState.isRunning {
            let entry = PolmodorEntry(
                date: Date(),
                pomodoroState: timerState.pomodoroState,
                timeRemaining: timerState.timeRemaining,
                progress: calculateProgress(
                    timeRemaining: timerState.timeRemaining, state: timerState.pomodoroState
                ),
                taskTitle: timerState.taskTitle,
                isRunning: false
            )
            completion(Timeline(entries: [entry], policy: .never))
            return
        }

        // Create a timeline that updates every minute while the timer is running
        var entries: [PolmodorEntry] = []
        let currentDate = Date()

        // Calculate how many minutes until timer completes
        let minutesRemaining = Int(ceil(timerState.timeRemaining / 60))

        // Add current entry
        entries.append(
            PolmodorEntry(
                date: currentDate,
                pomodoroState: timerState.pomodoroState,
                timeRemaining: timerState.timeRemaining,
                progress: calculateProgress(
                    timeRemaining: timerState.timeRemaining, state: timerState.pomodoroState
                ),
                taskTitle: timerState.taskTitle,
                isRunning: timerState.isRunning
            )
        )

        // Add future entries (one per minute)
        for minuteOffset in 1 ... minutesRemaining {
            let entryDate = Calendar.current.date(
                byAdding: .minute, value: minuteOffset, to: currentDate
            )!
            let remainingTime = max(0, timerState.timeRemaining - Double(minuteOffset * 60))
            let progress = calculateProgress(
                timeRemaining: remainingTime, state: timerState.pomodoroState
            )

            let entry = PolmodorEntry(
                date: entryDate,
                pomodoroState: timerState.pomodoroState,
                timeRemaining: remainingTime,
                progress: progress,
                taskTitle: timerState.taskTitle,
                isRunning: remainingTime > 0
            )
            entries.append(entry)
        }

        // Add an entry for when the timer completes
        if minutesRemaining > 0 {
            let completionDate = Calendar.current.date(
                byAdding: .second, value: Int(timerState.timeRemaining), to: currentDate
            )!
            let completionEntry = PolmodorEntry(
                date: completionDate,
                pomodoroState: timerState.pomodoroState,
                timeRemaining: 0,
                progress: 1.0,
                taskTitle: timerState.taskTitle,
                isRunning: false
            )
            entries.append(completionEntry)
        }

        completion(Timeline(entries: entries, policy: .atEnd))
    }

    // Helper method to fetch timer state from UserDefaults
    private func fetchTimerState() -> (
        pomodoroState: PomodoroState, timeRemaining: TimeInterval, taskTitle: String,
        isRunning: Bool
    ) {
        let defaults = UserDefaults.standard

        // Get timer state with fallbacks to defaults
        let stateRawValue =
            defaults.string(forKey: "TimerStateManager.pomodoroState")
                ?? PomodoroState.work.rawValue
        let state = PomodoroState(rawValue: stateRawValue) ?? .work
        let timeRemaining = defaults.double(forKey: "TimerStateManager.timeRemaining")
        let isRunning = defaults.bool(forKey: "TimerStateManager.isRunning")

        // Get task title if there's an active subtask
        var taskTitle = "Polmodor Timer"
        if let subtaskIDString = defaults.string(forKey: "TimerStateManager.activeSubtaskID"),
           UUID(uuidString: subtaskIDString) != nil
        {
            taskTitle =
                defaults.string(forKey: "TimerStateManager.activeTaskTitle") ?? "Polmodor Timer"
        }

        return (state, timeRemaining, taskTitle, isRunning)
    }

    // Calculate the progress based on time remaining and total duration
    private func calculateProgress(timeRemaining: TimeInterval, state: PomodoroState) -> Double {
        let totalDuration: TimeInterval
        switch state {
        case .work:
            totalDuration = TimeInterval(
                UserDefaults.standard.integer(forKey: "SettingsManager.workDuration") * 60)
        case .shortBreak:
            totalDuration = TimeInterval(
                UserDefaults.standard.integer(forKey: "SettingsManager.shortBreakDuration") * 60)
        case .longBreak:
            totalDuration = TimeInterval(
                UserDefaults.standard.integer(forKey: "SettingsManager.longBreakDuration") * 60)
        }

        // Default values if settings aren't available
        let defaultDuration: TimeInterval
        switch state {
        case .work: defaultDuration = 25 * 60
        case .shortBreak: defaultDuration = 5 * 60
        case .longBreak: defaultDuration = 15 * 60
        }

        let duration = totalDuration > 0 ? totalDuration : defaultDuration
        return 1 - (timeRemaining / duration)
    }
}

// MARK: - Widget Entry View

struct PolmodorWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) private var widgetFamily

    var body: some View {
        ZStack {
            backgroundGradient

            VStack(spacing: widgetFamily == .systemSmall ? 4 : 8) {
                // Header with state and status icon
                HStack(spacing: 8) {
                    // State icon with colored background
                    ZStack {
                        Circle()
                            .fill(stateColor.opacity(0.15))
                            .frame(width: iconSize * 1.8, height: iconSize * 1.8)

                        Image(systemName: iconName)
                            .font(.system(size: iconSize, weight: .semibold))
                            .foregroundColor(stateColor)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        // Status text (e.g., "Focus Time")
                        Text(entry.pomodoroState.title)
                            .font(.system(size: titleSize, weight: .medium))
                            .foregroundColor(.secondary)
                            .lineLimit(1)

                        // Task title if there's enough space
                        if widgetFamily != .systemSmall || entry.taskTitle == "Polmodor Timer" {
                            Text(entry.taskTitle)
                                .font(.system(size: subtitleSize, weight: .semibold))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    // Running indicator
                    if entry.isRunning {
                        Image(systemName: "play.circle.fill")
                            .foregroundColor(stateColor)
                            .font(.system(size: iconSize))
                    }
                }

                Spacer()

                // Timer display
                HStack {
                    Spacer()

                    VStack(spacing: 4) {
                        Text(timeString)
                            .font(.system(size: timerSize, weight: .bold, design: .rounded))
                            .foregroundColor(stateColor)
                            .monospacedDigit()

                        if widgetFamily != .systemSmall {
                            // Show progress percentage on larger widgets
                            Text("\(Int(entry.progress * 100))% Complete")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()
                }

                Spacer()

                // Progress bar
                ProgressBarView(progress: entry.progress, color: stateColor)
                    .frame(height: widgetFamily == .systemSmall ? 6 : 8)
            }
            .padding(widgetFamily == .systemSmall ? 10 : 12)
        }
    }

    // MARK: - Custom Progress Bar

    struct ProgressBarView: View {
        let progress: Double
        let color: Color

        var body: some View {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: geometry.size.height)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * progress, height: geometry.size.height)
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var iconName: String {
        switch entry.pomodoroState {
        case .work: return "brain.head.profile"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak: return "figure.walk"
        }
    }

    private var stateColor: Color {
        switch entry.pomodoroState {
        case .work: return .red
        case .shortBreak: return .blue
        case .longBreak: return .green
        }
    }

    private var backgroundGradient: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.white)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    private var timeString: String {
        let minutes = Int(entry.timeRemaining) / 60
        let seconds = Int(entry.timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // Size adaptations based on widget family
    private var iconSize: CGFloat {
        switch widgetFamily {
        case .systemSmall: return 14
        case .systemMedium: return 16
        default: return 18
        }
    }

    private var titleSize: CGFloat {
        switch widgetFamily {
        case .systemSmall: return 12
        case .systemMedium: return 14
        default: return 16
        }
    }

    private var subtitleSize: CGFloat {
        switch widgetFamily {
        case .systemSmall: return 13
        case .systemMedium: return 15
        default: return 17
        }
    }

    private var timerSize: CGFloat {
        switch widgetFamily {
        case .systemSmall: return 24
        case .systemMedium: return 32
        default: return 38
        }
    }
}

// MARK: - Widget Definition

struct PolmodorWidget: Widget {
    let kind: String = "PolmodorWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: Provider()
        ) { entry in
            PolmodorWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .supportedFamilies([.systemSmall, .systemMedium])
        .configurationDisplayName("Polmodor Timer")
        .description("Keep track of your Polmodor timer and current task.")
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    PolmodorWidget()
} timeline: {
    PolmodorEntry(
        date: .now,
        pomodoroState: .work,
        timeRemaining: 1200,
        progress: 0.2,
        taskTitle: "Work on Project",
        isRunning: true
    )

    PolmodorEntry(
        date: .now,
        pomodoroState: .shortBreak,
        timeRemaining: 240,
        progress: 0.2,
        taskTitle: "Short Break",
        isRunning: true
    )

    PolmodorEntry(
        date: .now,
        pomodoroState: .longBreak,
        timeRemaining: 540,
        progress: 0.1,
        taskTitle: "Long Break",
        isRunning: false
    )
}

#Preview(as: .systemMedium) {
    PolmodorWidget()
} timeline: {
    PolmodorEntry(
        date: .now,
        pomodoroState: .work,
        timeRemaining: 1200,
        progress: 0.2,
        taskTitle: "Document API Implementation",
        isRunning: true
    )
}
