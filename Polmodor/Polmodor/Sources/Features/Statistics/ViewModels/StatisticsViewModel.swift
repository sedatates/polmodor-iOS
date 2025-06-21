import Foundation
import SwiftData
import SwiftUI

@MainActor
final class StatisticsViewModel: ObservableObject {
    @Published var statisticsData: StatisticsData?
    @Published var selectedTimeframe: StatisticsTimeframe = .thisWeek
    @Published var isLoading = false
    
    private var modelContext: ModelContext?
    
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
        loadStatistics()
    }
    
    func loadStatistics() {
        guard let context = modelContext else { return }
        
        isLoading = true
        
        Task {
            do {
                let tasks = try context.fetch(FetchDescriptor<PolmodorTask>())
                let statistics = try context.fetch(FetchDescriptor<StatisticsModel>())
                
                let data = calculateStatistics(from: tasks, statistics: statistics)
                
                await MainActor.run {
                    self.statisticsData = data
                    self.isLoading = false
                }
            } catch {
                print("Error loading statistics: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    func refreshStatistics() {
        loadStatistics()
    }
    
    private func calculateStatistics(from tasks: [PolmodorTask], statistics: [StatisticsModel]) -> StatisticsData {
        let calendar = Calendar.current
        let now = Date()
        
        // Filter data based on selected timeframe
        let filteredTasks = tasks.filter { task in
            filterByTimeframe(date: task.createdAt, timeframe: selectedTimeframe)
        }
        
        let filteredStats = statistics.filter { stat in
            filterByTimeframe(date: stat.date, timeframe: selectedTimeframe)
        }
        
        // Calculate totals
        let totalPomodoros = filteredTasks.reduce(0) { $0 + $1.completedPomodoros }
        let totalFocusTime = filteredTasks.reduce(0) { $0 + $1.timeSpent }
        let totalTasks = filteredTasks.filter { $0.completed }.count
        let averageSessionLength = totalPomodoros > 0 ? totalFocusTime / Double(totalPomodoros) : 0
        
        // Calculate daily statistics
        let dailyStats = calculateDailyStatistics(from: filteredTasks, timeframe: selectedTimeframe)
        
        // Calculate weekly statistics
        let weeklyStats = calculateWeeklyStatistics(from: filteredTasks)
        
        // Calculate category statistics
        let categoryStats = calculateCategoryStatistics(from: filteredTasks)
        
        return StatisticsData(
            totalPomodoros: totalPomodoros,
            totalFocusTime: totalFocusTime,
            totalTasks: totalTasks,
            averageSessionLength: averageSessionLength,
            dailyStats: dailyStats,
            weeklyStats: weeklyStats,
            categoryStats: categoryStats
        )
    }
    
    private func filterByTimeframe(date: Date, timeframe: StatisticsTimeframe) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        
        switch timeframe {
        case .thisWeek:
            return calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear)
        case .thisMonth:
            return calendar.isDate(date, equalTo: now, toGranularity: .month)
        case .last7Days:
            return date >= calendar.date(byAdding: .day, value: -7, to: now)!
        case .last30Days:
            return date >= calendar.date(byAdding: .day, value: -30, to: now)!
        case .allTime:
            return true
        }
    }
    
    private func calculateDailyStatistics(from tasks: [PolmodorTask], timeframe: StatisticsTimeframe) -> [DailyStatistics] {
        let calendar = Calendar.current
        let now = Date()
        
        let daysToShow: Int
        switch timeframe {
        case .thisWeek, .last7Days:
            daysToShow = 7
        case .thisMonth, .last30Days:
            daysToShow = 30
        case .allTime:
            daysToShow = 90 // Show last 90 days for all time
        }
        
        var dailyStats: [DailyStatistics] = []
        
        for i in 0..<daysToShow {
            let date = calendar.date(byAdding: .day, value: -i, to: now)!
            let dayTasks = tasks.filter { calendar.isDate($0.createdAt, inSameDayAs: date) }
            
            let pomodoros = dayTasks.reduce(0) { $0 + $1.completedPomodoros }
            let focusTime = dayTasks.reduce(0) { $0 + $1.timeSpent }
            let completedTasks = dayTasks.filter { $0.completed }.count
            
            dailyStats.append(DailyStatistics(
                date: date,
                pomodoros: pomodoros,
                focusTime: focusTime,
                tasks: completedTasks
            ))
        }
        
        return dailyStats.reversed()
    }
    
    private func calculateWeeklyStatistics(from tasks: [PolmodorTask]) -> [WeeklyStatistics] {
        let calendar = Calendar.current
        let now = Date()
        
        var weeklyStats: [WeeklyStatistics] = []
        
        for i in 0..<4 { // Last 4 weeks
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -i, to: now)!
            let weekStartOfWeek = calendar.dateInterval(of: .weekOfYear, for: weekStart)?.start ?? weekStart
            
            let weekTasks = tasks.filter { task in
                if let weekInterval = calendar.dateInterval(of: .weekOfYear, for: weekStartOfWeek) {
                    return weekInterval.contains(task.createdAt)
                }
                return false
            }
            
            let pomodoros = weekTasks.reduce(0) { $0 + $1.completedPomodoros }
            let focusTime = weekTasks.reduce(0) { $0 + $1.timeSpent }
            let completedTasks = weekTasks.filter { $0.completed }.count
            
            weeklyStats.append(WeeklyStatistics(
                weekStart: weekStartOfWeek,
                pomodoros: pomodoros,
                focusTime: focusTime,
                tasks: completedTasks
            ))
        }
        
        return weeklyStats.reversed()
    }
    
    private func calculateCategoryStatistics(from tasks: [PolmodorTask]) -> [CategoryStatistics] {
        let grouped = Dictionary(grouping: tasks) { $0.category?.name ?? "Uncategorized" }
        let totalPomodoros = tasks.reduce(0) { $0 + $1.completedPomodoros }
        
        var categoryStats = grouped.map { (categoryName, categoryTasks) -> CategoryStatistics in
            let pomodoros = categoryTasks.reduce(0) { $0 + $1.completedPomodoros }
            let focusTime = categoryTasks.reduce(0) { $0 + $1.timeSpent }
            let completedTasks = categoryTasks.filter { $0.completed }.count
            let color = categoryTasks.first?.category?.color.toHex() ?? "#4CAF50"
            
            var stat = CategoryStatistics(
                name: categoryName,
                pomodoros: pomodoros,
                focusTime: focusTime,
                tasks: completedTasks,
                color: color
            )
            
            stat.percentage = totalPomodoros > 0 ? Double(pomodoros) / Double(totalPomodoros) * 100 : 0
            return stat
        }
        
        return categoryStats.sorted { $0.pomodoros > $1.pomodoros }
    }
}

enum StatisticsTimeframe: String, CaseIterable {
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case last7Days = "Last 7 Days"
    case last30Days = "Last 30 Days"
    case allTime = "All Time"
    
    var displayName: String {
        return self.rawValue
    }
} 