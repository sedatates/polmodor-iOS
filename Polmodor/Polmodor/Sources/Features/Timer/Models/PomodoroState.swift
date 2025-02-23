import Foundation
import SwiftUI

public enum PomodoroState: String, CaseIterable {
    case work = "Work"
    case shortBreak = "Short Break"
    case longBreak = "Long Break"

    public struct Colors {
        public let start: Color
        public let middle: Color
        public let end: Color
    }
    
    public var colors: Colors {
        switch self {
        case .work:
            return Colors(
                start: .init("#FF6B6B"),
                middle: .init("#FA5252"),
                end: .init("#F03E3E")
            )
        case .shortBreak:
            return Colors(
                start: .init("#4DABF7"),
                middle: .init("#339AF0"),
                end: .init("#228BE6")
            )
        case .longBreak:
            return Colors(
                start: .init("#51CF66"),
                middle: .init("#40C057"),
                end: .init("#2F9E44")
            )
        }
    }
    
    
    
    public var description: String {
        self.rawValue
    }

    public var title: String {
        self.rawValue
    }
    
    
    

//    public var colors: Colors {
//        switch self {
//        case .work:
//            return Colors(
//                start: .init("#FF6B6B"),
//                middle: .init("#FA5252"),
//                end: .init("#F03E3E")
//            )
//        case .shortBreak:
//            return Colors(
//                start: .init("#4DABF7"),
//                middle: .init("#339AF0"),
//                end: .init("#228BE6")
//            )
//        case .longBreak:
//            return Colors(
//                start: .init("#51CF66"),
//                middle: .init("#40C057"),
//                end: .init("#2F9E44")
//            )
//        }
//    }

    public var duration: TimeInterval {
        switch self {
        case .work:
            return TimeInterval(UserDefaults.standard.integer(forKey: "workDuration")) * 60
        case .shortBreak:
            return TimeInterval(UserDefaults.standard.integer(forKey: "shortBreakDuration")) * 60
        case .longBreak:
            return TimeInterval(UserDefaults.standard.integer(forKey: "longBreakDuration")) * 60
        }
    }
}
