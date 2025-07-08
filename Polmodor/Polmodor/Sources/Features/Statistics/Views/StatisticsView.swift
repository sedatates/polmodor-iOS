import Charts
import SwiftData
import SwiftUI

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = StatisticsViewModel()
    @State private var selectedMetric: StatisticMetric = .pomodoros
    @State private var subscriptionManager = SubscriptionManager.shared
    @State private var paywallManager = PaywallManager.shared
    @State private var showPaywallForPremiumFeatures = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                headerSection
                timeframeSelector

                if viewModel.isLoading {
                    loadingView
                } else if let data = viewModel.statisticsData {
                    overviewCards(data: data)

                    if subscriptionManager.canAccessAdvancedStatistics() {
                        chartSection(data: data)
                        categorySection(data: data)
                        weeklySection(data: data)
                    } else {
                        premiumUpsellView
                    }
                } else {
                    emptyStateView
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.large)
        .background(
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.systemGray6).opacity(0.3),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .refreshable {
            viewModel.refreshStatistics()
        }
        .onAppear {
            viewModel.configure(with: modelContext)
        }
        .onChange(of: viewModel.selectedTimeframe) { _, _ in
            viewModel.loadStatistics()
        }
        // Modern RevenueCat Paywall Integration
        .presentPolmodorPaywallWhen(showPaywallForPremiumFeatures)
        .onChange(of: subscriptionManager.isPremium) { _, isPremium in
            if isPremium {
                showPaywallForPremiumFeatures = false
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Productivity Insights")
                        .font(.title.weight(.bold))
                        .foregroundColor(.primary)

                    Text("Track your focus and progress over time")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .padding(12)
                    .background(
                        Circle()
                            .fill(.blue.opacity(0.1))
                    )
            }
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 8)
    }

    private var timeframeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(StatisticsTimeframe.allCases, id: \.rawValue) { timeframe in
                    TimeframeChip(
                        title: timeframe.displayName,
                        isSelected: viewModel.selectedTimeframe == timeframe
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.selectedTimeframe = timeframe
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.horizontal, -16)
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
            Text("Loading statistics...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Data Available", systemImage: "chart.bar")
        } description: {
            Text("Complete some tasks and Pomodoro sessions to see your statistics")
        }
        .padding(.top, 40)
    }

    private var premiumUpsellView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.yellow.opacity(0.8), .orange.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)

                    Image(systemName: "crown.fill")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(spacing: 8) {
                    Text("Advanced Statistics")
                        .font(.title.bold())
                        .foregroundColor(.primary)

                    Text("Unlock powerful insights to supercharge your productivity")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
            }

            VStack(spacing: 16) {
                FeatureRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Interactive Charts",
                    description: "Daily & weekly activity visualization",
                    color: .blue
                )

                FeatureRow(
                    icon: "chart.pie.fill",
                    title: "Category Analytics",
                    description: "Time distribution across categories",
                    color: .green
                )

                FeatureRow(
                    icon: "calendar.badge.clock",
                    title: "Productivity Trends",
                    description: "Track your focus patterns over time",
                    color: .orange
                )

                FeatureRow(
                    icon: "target",
                    title: "Goal Tracking",
                    description: "Set and monitor daily focus targets",
                    color: .purple
                )
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )

            Button(action: {
                showPaywallForPremiumFeatures = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.headline.weight(.semibold))

                    Text("Upgrade to Pro")
                        .font(.headline.weight(.semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.blue, .purple, .pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 8)
        )
        .padding(.horizontal)
    }

    private func overviewCards(data: StatisticsData) -> some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 16
        ) {
            StatCard(
                title: "Total Pomodoros",
                value: "\(data.totalPomodoros)",
                icon: "timer.circle.fill",
                color: .red
            )

            StatCard(
                title: "Focus Time",
                value: data.formattedFocusTime,
                icon: "clock.fill",
                color: .blue
            )

            StatCard(
                title: "Completed Tasks",
                value: "\(data.totalTasks)",
                icon: "checkmark.circle.fill",
                color: .green
            )

            StatCard(
                title: "Avg Session",
                value: formatTime(data.averageSessionLength),
                icon: "gauge.high",
                color: .orange
            )
        }
    }

    private func chartSection(data: StatisticsData) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Activity")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.primary)

                    Text("Your productivity patterns")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                metricSelector
            }

            if #available(iOS 16.0, *) {
                chartView(data: data)
            } else {
                simpleChartView(data: data)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 15, x: 0, y: 8)
        )
    }

    private var metricSelector: some View {
        Menu {
            ForEach(StatisticMetric.allCases, id: \.rawValue) { metric in
                Button(metric.displayName) {
                    selectedMetric = metric
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(selectedMetric.displayName)
                    .font(.caption.weight(.medium))
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .foregroundColor(.secondary)
        }
    }

    @available(iOS 16.0, *)
    private func chartView(data: StatisticsData) -> some View {
        Chart(data.dailyStats, id: \.date) { stat in
            BarMark(
                x: .value("Date", stat.formattedDate),
                y: .value(selectedMetric.displayName, metricValue(from: stat))
            )
            .foregroundStyle(selectedMetric.color.gradient)
            .cornerRadius(4)
        }
        .frame(height: 200)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: max(1, data.dailyStats.count / 5))) { _ in
                AxisValueLabel()
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func simpleChartView(data: StatisticsData) -> some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(data.dailyStats.prefix(7), id: \.date) { stat in
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(selectedMetric.color)
                        .frame(width: 20, height: CGFloat(metricValue(from: stat)) * 4)

                    Text(stat.formattedDate.suffix(2))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(height: 120)
    }

    private func categorySection(data: StatisticsData) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Category Breakdown")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.primary)

                Text("Time distribution across categories")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 12) {
                ForEach(data.categoryStats.prefix(5), id: \.name) { category in
                    CategoryRow(category: category)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 15, x: 0, y: 8)
        )
    }

    private func weeklySection(data: StatisticsData) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Weekly Progress")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.primary)

                Text("Your consistency over time")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 12) {
                ForEach(data.weeklyStats, id: \.weekStart) { week in
                    WeeklyRow(week: week)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 15, x: 0, y: 8)
        )
    }

    private func metricValue(from stat: DailyStatistics) -> Double {
        switch selectedMetric {
        case .pomodoros:
            return Double(stat.pomodoros)
        case .focusTime:
            return stat.focusTime / 3600 // Convert to hours
        case .tasks:
            return Double(stat.tasks)
        }
    }

    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(color)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.6))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(value)
                    .font(.title.weight(.bold))
                    .foregroundColor(.primary)

                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: color.opacity(0.1), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.1), lineWidth: 1)
        )
    }
}

struct TimeframeChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.blue : Color(.systemGray6))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
    }
}

struct CategoryRow: View {
    let category: CategoryStatistics

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: category.color))
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 2) {
                Text(category.name)
                    .font(.subheadline.weight(.medium))

                Text("\(category.pomodoros) pomodoros • \(formatTime(category.focusTime))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(Int(category.percentage))%")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
        }
    }

    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct WeeklyRow: View {
    let week: WeeklyStatistics

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(week.formattedWeek)
                    .font(.subheadline.weight(.medium))

                Text("\(week.pomodoros) pomodoros • \(week.tasks) tasks")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(formatTime(week.focusTime))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.blue)
        }
        .padding(.vertical, 4)
    }

    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

enum StatisticMetric: String, CaseIterable {
    case pomodoros = "Pomodoros"
    case focusTime = "Focus Time"
    case tasks = "Tasks"

    var displayName: String {
        return rawValue
    }

    var color: Color {
        switch self {
        case .pomodoros:
            return .red
        case .focusTime:
            return .blue
        case .tasks:
            return .green
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(.green)
        }
    }
}

#Preview {
    NavigationStack {
        StatisticsView()
            .modelContainer(ModelContainerSetup.setupModelContainer())
    }
}
