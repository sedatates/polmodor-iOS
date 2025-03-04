//
//  PolmodorLiveActivityAttributes.swift
//  Polmodor
//
//  Created by sedat ateş on 2.03.2025.
//

import ActivityKit
import Foundation
import SwiftUI

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

    /// Parent task name (if available)
    public var parentTaskName: String?

    /// Number of completed pomodoros in the current session
    public var completedPomodoros: Int

    /// Total pomodoros planned for the task
    public var totalPomodoros: Int

    /// Whether the timer is locked (to prevent accidental interruptions)
    public var isLocked: Bool

    public init(
      taskTitle: String,
      remainingTime: Int,
      isBreak: Bool,
      breakType: String,
      startedAt: Date?,
      pausedAt: Date?,
      duration: Int,
      parentTaskName: String? = nil,
      completedPomodoros: Int = 0,
      totalPomodoros: Int = 0,
      isLocked: Bool = false
    ) {
      self.taskTitle = taskTitle
      self.remainingTime = remainingTime
      self.isBreak = isBreak
      self.breakType = breakType
      self.startedAt = startedAt
      self.pausedAt = pausedAt
      self.duration = duration
      self.parentTaskName = parentTaskName
      self.completedPomodoros = completedPomodoros
      self.totalPomodoros = totalPomodoros
      self.isLocked = isLocked
    }
  }

  /// Name of the Live Activity
  public var name: String

  public init(name: String) {
    self.name = name
  }
}
