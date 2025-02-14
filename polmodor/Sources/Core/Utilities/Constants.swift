import Foundation
import SwiftUI

#if os(iOS)
    import UIKit
#endif

enum Constants {
    enum Timer {
        static let minimumWorkDuration: TimeInterval = 15 * 60  // 15 minutes
        static let maximumWorkDuration: TimeInterval = 60 * 60  // 60 minutes
        static let minimumShortBreakDuration: TimeInterval = 3 * 60  // 3 minutes
        static let maximumShortBreakDuration: TimeInterval = 15 * 60  // 15 minutes
        static let minimumLongBreakDuration: TimeInterval = 10 * 60  // 10 minutes
        static let maximumLongBreakDuration: TimeInterval = 30 * 60  // 30 minutes
        static let minimumPomodorosUntilLongBreak = 2
        static let maximumPomodorosUntilLongBreak = 6
    }

    enum Task {
        static let minimumPomodoroCount = 1
        static let maximumPomodoroCount = 10
        static let maximumTitleLength = 100
        static let maximumDescriptionLength = 500
    }

    enum UI {
        static let cornerRadius: CGFloat = 12
        static let spacing: CGFloat = 16
        static let padding: CGFloat = 20
        static let buttonHeight: CGFloat = 50
        static let iconSize: CGFloat = 24
        static let minimumTapTargetSize: CGFloat = 44
    }

    enum AnimationDuration {
        static let standard: Double = 0.3
        static let quick: Double = 0.2
        static let slow: Double = 0.5
    }

    enum Storage {
        static let tasksKey = "savedTasks"
        static let settingsKey = "appSettings"
        static let onboardingKey = "hasCompletedOnboarding"
    }

    enum URLs {
        static let repository = "https://github.com/yourusername/polmodor"
        static let issues = "https://github.com/yourusername/polmodor/issues"
        static let privacy = "https://github.com/yourusername/polmodor/blob/main/PRIVACY.md"
        static let license = "https://github.com/yourusername/polmodor/blob/main/LICENSE"
    }

    #if os(iOS)
        enum Haptics {
            static let light = UIImpactFeedbackGenerator(style: .light)
            static let medium = UIImpactFeedbackGenerator(style: .medium)
            static let heavy = UIImpactFeedbackGenerator(style: .heavy)
            static let success = UINotificationFeedbackGenerator()
        }
    #endif
}
