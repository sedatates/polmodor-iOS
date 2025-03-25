//
//  AppIntent.swift
//  PolmodorWidget
//
//  Created by sedat ateş on 2.03.2025.
//

import AppIntents
import WidgetKit

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription { "This is an example widget." }

    // An example configurable parameter.
    @Parameter(title: "Favorite Emoji", default: "😃")
    var favoriteEmoji: String
}

// MARK: - Live Activity App Intents
struct StartNextSessionIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Next Session"
    static var description: LocalizedStringResource = "Start the next Pomodoro session"

    @MainActor
    func perform() async throws -> some IntentResult {
        // Notify the app to start the next session
        NotificationCenter.default.post(
            name: Notification.Name("StartNextPomodorSession"), object: nil)
        return .result()
    }
}

struct PauseResumeTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Pause/Resume Timer"
    static var description: LocalizedStringResource = "Pause or resume the current timer"

    @MainActor
    func perform() async throws -> some IntentResult {
        // Notify the app to toggle the timer
        NotificationCenter.default.post(name: Notification.Name("TogglePomodorTimer"), object: nil)
        return .result()
    }
}

struct SkipTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Skip Timer"
    static var description: LocalizedStringResource = "Skip to the next timer session"

    @MainActor
    func perform() async throws -> some IntentResult {
        // Notify the app to skip to the next session
        NotificationCenter.default.post(name: Notification.Name("SkipPomodorTimer"), object: nil)
        return .result()
    }
}

struct LockUnlockTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Lock/Unlock Timer"
    static var description: LocalizedStringResource =
        "Lock or unlock the timer to prevent accidental modifications"

    @MainActor
    func perform() async throws -> some IntentResult {
        // Notify the app to toggle lock state
        NotificationCenter.default.post(
            name: Notification.Name("ToggleLockPomodorTimer"), object: nil)
        return .result()
    }
}
