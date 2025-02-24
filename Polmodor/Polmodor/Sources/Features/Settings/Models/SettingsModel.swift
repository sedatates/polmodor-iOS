//
//  SettingsModel.swift
//  Polmodor
//
//  Created by sedat ateş on 24.02.2025.
//

import Foundation
import SwiftData


@Model
class SettingsModel {
    var isDarkModeEnabled: Bool = false
    var isNotificationEnabled: Bool = true
    var isSoundEnabled: Bool = true
    
    var workDuration: Int = 25
    var shortBreakDuration: Int = 5
    var longBreakDuration: Int = 15
    var pomodorosUntilLongBreak: Int = 4
    var autoStartBreaks: Bool = false
    var autoStartPomodoros: Bool = false
    
    init() {}
}
