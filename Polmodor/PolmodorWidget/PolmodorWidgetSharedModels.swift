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

    /// Whether the timer represents a break session
    public var isBreak: Bool

    /// Type of break (short, long, or none)
    public var breakType: String

    /// Time when the timer was started
    public var startedAt: Date?

    /// Time when the timer was paused (nil if running)
    public var pausedAt: Date?

    /// Total duration of the current session in seconds
    public var duration: Int

    public init(
      taskTitle: String,
      remainingTime: Int,
      isBreak: Bool,
      breakType: String,
      startedAt: Date?,
      pausedAt: Date?,
      duration: Int
    ) {
      self.taskTitle = taskTitle
      self.remainingTime = remainingTime
      self.isBreak = isBreak
      self.breakType = breakType
      self.startedAt = startedAt
      self.pausedAt = pausedAt
      self.duration = duration
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
