import Foundation
import SwiftUI

enum PomodoroState: String {
  case work = "Focus Time"
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

  var title: String {
    return self.rawValue
  }

  var description: String {
    self.rawValue
  }

  var duration: TimeInterval {
    let settingsManager = SettingsManager.shared

    switch self {
    case .work:
      return TimeInterval(settingsManager.workDurationMinutes) * 60
    case .shortBreak:
      return TimeInterval(settingsManager.shortBreakDurationMinutes) * 60
    case .longBreak:
      return TimeInterval(settingsManager.longBreakDurationMinutes) * 60
    }
  }

  var color: Color {
    switch self {
    case .work:
      return .red
    case .shortBreak:
      return .green
    case .longBreak:
      return .blue
    }
  }
}
