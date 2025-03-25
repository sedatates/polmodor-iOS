//
//  PolmodorWidgetSharedModels.swift
//  PolmodorWidget
//
//  Created by sedat ateş on 2.03.2025.
//

import ActivityKit
import Foundation
import SwiftUI
import WidgetKit

// MARK: - Live Activity Attributes

/// Attributes for the Polmodor Live Activity
public struct PolmodorLiveActivityAttributes: ActivityAttributes {
  /// Dynamic state of the Live Activity that can be updated
  public struct ContentState: Codable, Hashable {
    /// Title of the current task
    public var taskTitle: String

    /// Remaining time in seconds
    public var remainingTime: Int

    /// Current timer state (work, shortBreak, longBreak)
    public var sessionType: SessionType

    /// Time when the timer was started
    public var startedAt: Date?

    /// Time when the timer was paused (nil if running)
    public var pausedAt: Date?

    /// Total duration of the current session in seconds
    public var duration: Int

    /// Whether the timer is locked (to prevent accidental interruptions)
    public var isLocked: Bool

    /// Session progress - calculated from remaining time and duration
    /// Only included when needed for display purposes
    private var _progress: Double?

    /// Computed properties for consistent widget rendering
    public var progress: Double {
      _progress ?? max(0.0, min(1.0, Double(duration - remainingTime) / Double(duration)))
    }

    /// Whether the current session is a break
    public var isBreak: Bool {
      sessionType == .shortBreak || sessionType == .longBreak
    }

    /// Break type string representation (for backward compatibility)
    public var breakType: String {
      switch sessionType {
      case .shortBreak: return "short"
      case .longBreak: return "long"
      default: return "none"
      }
    }

    /// Session type enum for cleaner state management
    public enum SessionType: String, Codable, Hashable {
      case work
      case shortBreak
      case longBreak
    }

    public init(
      taskTitle: String,
      remainingTime: Int,
      sessionType: SessionType,
      startedAt: Date?,
      pausedAt: Date?,
      duration: Int,
      isLocked: Bool = false,
      progress: Double? = nil
    ) {
      self.taskTitle = taskTitle
      self.remainingTime = remainingTime
      self.sessionType = sessionType
      self.startedAt = startedAt
      self.pausedAt = pausedAt
      self.duration = duration
      self.isLocked = isLocked
      self._progress = progress
    }

    // Legacy initializer for backward compatibility
    public init(
      taskTitle: String,
      remainingTime: Int,
      isBreak: Bool,
      breakType: String,
      startedAt: Date?,
      pausedAt: Date?,
      duration: Int,
      isLocked: Bool = false,
      progress: Double? = nil
    ) {
      self.taskTitle = taskTitle
      self.remainingTime = remainingTime

      // Convert old format to new SessionType
      if isBreak {
        self.sessionType = breakType == "long" ? .longBreak : .shortBreak
      } else {
        self.sessionType = .work
      }

      self.startedAt = startedAt
      self.pausedAt = pausedAt
      self.duration = duration
      self.isLocked = isLocked
      self._progress = progress
    }
  }

  /// Name of the Live Activity
  public var name: String

  public init(name: String) {
    self.name = name
  }
}

// MARK: - Color Helper
extension Color {
  static func hex(_ hexString: String) -> Color {
    let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int = UInt64()
    Scanner(string: hex).scanHexInt64(&int)
    let a: UInt64
    let r: UInt64
    let g: UInt64
    let b: UInt64
    switch hex.count {
    case 3:  // RGB (12-bit)
      (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6:  // RGB (24-bit)
      (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8:  // ARGB (32-bit)
      (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default:
      (a, r, g, b) = (255, 0, 0, 0)
    }
    return Color(
      .sRGB,
      red: Double(r) / 255,
      green: Double(g) / 255,
      blue: Double(b) / 255,
      opacity: Double(a) / 255
    )
  }
}
