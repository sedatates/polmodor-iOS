//
//  SettingsModel.swift
//  Polmodor
//
//  Created by sedat ateş on 24.02.2025.
//

import Foundation
import SwiftData

@Model
final class SettingsModel : ObservableObject {
    // MARK: - Timer Settings
    var workDuration: Int = 25
    var shortBreakDuration: Int = 5
    var longBreakDuration: Int = 15
    var pomodorosUntilLongBreak: Int = 4

    // MARK: - Automation Settings
    var autoStartBreaks: Bool = false
    var autoStartPomodoros: Bool = false

    // MARK: - Notification Settings
    var isNotificationEnabled: Bool = true
    var isSoundEnabled: Bool = true

    // MARK: - Appearance Settings
    var isDarkModeEnabled: Bool = false

    // MARK: - Initializer
    init(
        workDuration: Int = 25,
        shortBreakDuration: Int = 5,
        longBreakDuration: Int = 15,
        pomodorosUntilLongBreak: Int = 4,
        autoStartBreaks: Bool = false,
        autoStartPomodoros: Bool = false,
        isNotificationEnabled: Bool = true,
        isSoundEnabled: Bool = true,
        isDarkModeEnabled: Bool = false
    ) {
        self.workDuration = workDuration
        self.shortBreakDuration = shortBreakDuration
        self.longBreakDuration = longBreakDuration
        self.pomodorosUntilLongBreak = pomodorosUntilLongBreak
        self.autoStartBreaks = autoStartBreaks
        self.autoStartPomodoros = autoStartPomodoros
        self.isNotificationEnabled = isNotificationEnabled
        self.isSoundEnabled = isSoundEnabled
        self.isDarkModeEnabled = isDarkModeEnabled
    }
}

// MARK: - Convenience Methods
extension SettingsModel {
    /// Reset all settings to their default values
    func resetToDefaults() {
        workDuration = 25
        shortBreakDuration = 5
        longBreakDuration = 15
        pomodorosUntilLongBreak = 4
        autoStartBreaks = false
        autoStartPomodoros = false
        isNotificationEnabled = true
        isSoundEnabled = true
        isDarkModeEnabled = false
    }

    /// Validate settings to ensure they're within acceptable ranges
    func validate() {
        // Ensure timer durations are within acceptable ranges
        workDuration = max(15, min(workDuration, 60))
        shortBreakDuration = max(3, min(shortBreakDuration, 15))
        longBreakDuration = max(10, min(longBreakDuration, 30))
        pomodorosUntilLongBreak = max(2, min(pomodorosUntilLongBreak, 10))
    }
}
