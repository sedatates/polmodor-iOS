//
//  widgetControl.swift
//  widget
//
//  Created by sedat ateş on 14.02.2025.
//

import AppIntents
import SwiftUI
import WidgetKit

struct ToggleIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Timer"
    static var description = IntentDescription("Toggle the timer on/off.")

    func perform() async throws -> some IntentResult {
        // Implement the toggle functionality here
        return .result()
    }
}

struct ControlEntry: TimelineEntry {
    let date: Date
    let isTimerRunning: Bool
}

struct ControlTimelineProvider: TimelineProvider {
    typealias Entry = ControlEntry

    func placeholder(in context: Context) -> ControlEntry {
        ControlEntry(date: Date(), isTimerRunning: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (ControlEntry) -> Void) {
        let entry = ControlEntry(date: Date(), isTimerRunning: false)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ControlEntry>) -> Void) {
        var entries: [ControlEntry] = []
        let currentDate = Date()
        let entry = ControlEntry(date: currentDate, isTimerRunning: false)
        entries.append(entry)
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct widgetControlEntryView: View {
    let entry: ControlEntry

    var body: some View {
        VStack {
            Image(systemName: entry.isTimerRunning ? "pause.circle.fill" : "play.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(entry.isTimerRunning ? .red : .green)

            Text(entry.isTimerRunning ? "Pause" : "Start")
                .font(.caption)
        }
        .padding()
    }
}

struct widgetControl: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "widgetControl", provider: ControlTimelineProvider()) { entry in
            widgetControlEntryView(entry: entry)
        }
        .configurationDisplayName("Timer Control")
        .description("Control your Pomodoro timer.")
        .supportedFamilies([.accessoryCircular])
    }
}

#if DEBUG
    @available(iOSApplicationExtension 17.0, *)
    #Preview(as: .accessoryCircular) {
        widgetControl()
    } timeline: {
        ControlEntry(date: .now, isTimerRunning: false)
        ControlEntry(date: .now, isTimerRunning: true)
    }
#endif
