import SwiftUI

private struct IsTimerActiveLockKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

private struct ForceLockKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var isTimerActiveLock: Bool {
        get { self[IsTimerActiveLockKey.self] }
        set { self[IsTimerActiveLockKey.self] = newValue }
    }

    var forceLockEnabled: Bool {
        get { self[ForceLockKey.self] }
        set { self[ForceLockKey.self] = newValue }
    }
}

struct ContentView: View {
    @EnvironmentObject var timerViewModel: TimerViewModel
    @EnvironmentObject var taskViewModel: TaskViewModel
    @State private var selectedTab: Tab = .timer
    @Namespace private var namespace
    @AppStorage("forceLockEnabled") private var forceLockEnabled = false
    @Environment(\.isTimerActiveLock) private var isTimerActiveLock
    @StateObject private var tabBarVisibility = TabBarVisibility()
    @AppStorage("zenModeEnabled") private var zenModeEnabled = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                TimerView()
                    .environmentObject(timerViewModel)
                    .environment(\.tabBarVisibility, tabBarVisibility)
                    .environment(\.forceLockEnabled, forceLockEnabled)
                    .environment(\.isTimerActiveLock, isTimerActiveLock)
                    .tag(Tab.timer)

                NavigationStack {
                    TaskListView()
                        .environmentObject(taskViewModel)
                }
                .tag(Tab.tasks)

                NavigationStack {
                    SettingsView()
                }
                .tag(Tab.settings)
            }
            .safeAreaInset(edge: .bottom) {
                if tabBarVisibility.isVisible || selectedTab != .timer {
                    ModernTabBar(selectedTab: $selectedTab)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                        .allowsHitTesting(
                            !isTimerActiveLock || !forceLockEnabled || selectedTab != .timer
                        )
                        .opacity(
                            isTimerActiveLock && forceLockEnabled && selectedTab == .timer ? 0.5 : 1
                        )
                        .transition(.move(edge: .bottom))
                }
            }
            .onChange(of: selectedTab) { oldValue, newValue in
                if newValue != .timer {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        tabBarVisibility.setVisible(true)
                    }
                }
            }
        }
        .environment(\.forceLockEnabled, forceLockEnabled)
    }
}

struct ModernTabBar: View {
    @Binding var selectedTab: ContentView.Tab
    @Namespace private var animation
    @Environment(\.isTimerActiveLock) private var isTimerActiveLock
    @Environment(\.forceLockEnabled) private var forceLockEnabled

    var body: some View {
        HStack {
            ForEach([ContentView.Tab.timer, .tasks, .settings], id: \.self) { tab in
                TabButton(tab: tab, selectedTab: $selectedTab, namespace: animation)
            }
        }
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.05), radius: 15, x: 0, y: 5)
        }
        .overlay {
            if isTimerActiveLock && forceLockEnabled {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .allowsHitTesting(false)
            }
        }
    }
}

struct TabButton: View {
    let tab: ContentView.Tab
    @Binding var selectedTab: ContentView.Tab
    var namespace: Namespace.ID

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: selectedTab == tab ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 24, weight: selectedTab == tab ? .semibold : .regular))
                    .foregroundStyle(selectedTab == tab ? tab.color : .gray.opacity(0.5))
                    .symbolEffect(.bounce, value: selectedTab == tab)

                Text(tab.title)
                    .font(.system(size: 12, weight: selectedTab == tab ? .medium : .regular))
                    .foregroundStyle(selectedTab == tab ? tab.color : .gray.opacity(0.5))
            }
            .frame(height: 55)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Tab Enum
extension ContentView {
    enum Tab: Hashable {
        case timer, tasks, settings

        var icon: String {
            switch self {
            case .timer: return "clock"
            case .tasks: return "list.bullet"
            case .settings: return "gearshape"
            }
        }

        var selectedIcon: String {
            switch self {
            case .timer: return "clock.fill"
            case .tasks: return "list.bullet.indent"
            case .settings: return "gearshape.fill"
            }
        }

        var title: String {
            switch self {
            case .timer: return "Timer"
            case .tasks: return "Tasks"
            case .settings: return "Settings"
            }
        }

        var color: Color {
            switch self {
            case .timer: return .blue
            case .tasks: return .blue
            case .settings: return .blue
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(TimerViewModel())
        .environmentObject(TaskViewModel())
        .environment(\.forceLockEnabled, false)
        .environment(\.isTimerActiveLock, false)
}
