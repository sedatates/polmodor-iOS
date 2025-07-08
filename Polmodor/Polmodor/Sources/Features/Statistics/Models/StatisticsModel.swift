import Foundation
import SwiftData

@Model
final class StatisticsModel {
    var id: UUID
    var date: Date
    var completedPomodoros: Int
    var totalFocusTime: TimeInterval // in seconds
    var completedTasks: Int
    var category: String?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        completedPomodoros: Int = 0,
        totalFocusTime: TimeInterval = 0,
        completedTasks: Int = 0,
        category: String? = nil
    ) {
        self.id = id
        self.date = date
        self.completedPomodoros = completedPomodoros
        self.totalFocusTime = totalFocusTime
        self.completedTasks = completedTasks
        self.category = category
    }
}

// MARK: - Statistics Data Structure

struct StatisticsData {
    let totalPomodoros: Int
    let totalFocusTime: TimeInterval
    let totalTasks: Int
    let averageSessionLength: TimeInterval
    let dailyStats: [DailyStatistics]
    let weeklyStats: [WeeklyStatistics]
    let categoryStats: [CategoryStatistics]

    var formattedFocusTime: String {
        let hours = Int(totalFocusTime) / 3600
        let minutes = Int(totalFocusTime) % 3600 / 60
        return "\(hours)h \(minutes)m"
    }
}

struct DailyStatistics {
    let date: Date
    let pomodoros: Int
    let focusTime: TimeInterval
    let tasks: Int

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: date)
    }
}

struct WeeklyStatistics {
    let weekStart: Date
    let pomodoros: Int
    let focusTime: TimeInterval
    let tasks: Int

    var formattedWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        let endDate = Calendar.current.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        return "\(formatter.string(from: weekStart)) - \(formatter.string(from: endDate))"
    }
}

struct CategoryStatistics {
    let name: String
    let pomodoros: Int
    let focusTime: TimeInterval
    let tasks: Int
    let color: String

    var percentage: Double = 0.0
}
