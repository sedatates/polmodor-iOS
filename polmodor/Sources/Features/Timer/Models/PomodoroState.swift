import Foundation
import SwiftUI

enum PomodoroState: String, CaseIterable, Equatable {
    case work
    case shortBreak
    case longBreak

    var duration: TimeInterval {
        switch self {
        case .work:
            return 60  // 25 minutes
        case .shortBreak:
            return 5 * 60  // 5 minutes
        case .longBreak:
            return 15 * 60  // 15 minutes
        }
    }

    var title: String {
        switch self {
        case .work:
            return "Work"
        case .shortBreak:
            return "Short Break"
        case .longBreak:
            return "Long Break"
        }
    }

    var colors: (start: String, middle: String, end: String) {
        switch self {
        case .work:
            return ("#FF6B6B", "#FA5252", "#F03E3E")
        case .shortBreak:
            return ("#4DABF7", "#339AF0", "#228BE6")
        case .longBreak:
            return ("#51CF66", "#40C057", "#2F9E44")
        }
    }
}

struct TimerColors {
    let start: Color
    let middle: Color
    let end: Color
}
