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
            _progress = progress
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
            parentTaskName _: String? = nil,
            completedPomodoros _: Int = 0,
            totalPomodoros _: Int = 0,
            isLocked: Bool = false
        ) {
            self.taskTitle = taskTitle
            self.remainingTime = remainingTime

            // Convert old format to new SessionType
            if isBreak {
                sessionType = breakType == "long" ? .longBreak : .shortBreak
            } else {
                sessionType = .work
            }

            self.startedAt = startedAt
            self.pausedAt = pausedAt
            self.duration = duration
            self.isLocked = isLocked
            _progress = nil
        }
    }

    /// Name of the Live Activity
    public var name: String

    public init(name: String) {
        self.name = name
    }
}
