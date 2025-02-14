//
//  widgetLiveActivity.swift
//  widget
//
//  Created by sedat ateş on 14.02.2025.
//

import ActivityKit
import SwiftUI
import WidgetKit

struct widgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var timeRemaining: TimeInterval
        var isRunning: Bool
    }

    var name: String
}

struct widgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: widgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            HStack {
                Spacer()
                VStack {
                    Text(context.state.isRunning ? "Focus Time!" : "Paused")
                        .font(.headline)

                    Text(formatTime(context.state.timeRemaining))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }
                Spacer()
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.timeRemaining)")
                }
            } compactLeading: {
                Text(formatTime(context.state.timeRemaining))
            } compactTrailing: {
                Image(systemName: context.state.isRunning ? "timer" : "timer.circle")
            } minimal: {
                Text(formatTime(context.state.timeRemaining))
            }
        }
    }

    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#if DEBUG
    @available(iOSApplicationExtension 16.2, *)
    struct widgetLiveActivity_Previews: PreviewProvider {
        static let attributes = widgetAttributes(name: "Focus")
        static let contentState = widgetAttributes.ContentState(
            timeRemaining: 300,
            isRunning: true
        )

        static var previews: some View {
            if #available(iOS 16.2, *) {
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
    }
#endif
