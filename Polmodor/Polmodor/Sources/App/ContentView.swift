import SwiftUI

struct ContentView: View {
    @EnvironmentObject var timerViewModel: TimerViewModel
    @EnvironmentObject var taskViewModel: TaskViewModel
    @State private var selectedTab: Tab = .timer
    @Namespace private var namespace

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main Content
            TabView(selection: $selectedTab) {
                TimerView()
                    .environmentObject(timerViewModel)
                    .tag(Tab.timer)

                TaskListView()
                    .environmentObject(taskViewModel)
                    .tag(Tab.tasks)

                SettingsView()
                    .tag(Tab.settings)
            }
            .ignoresSafeArea(edges: .bottom)

            // Custom Tab Bar
            HStack(spacing: 0) {
                ForEach([Tab.timer, .tasks, .settings], id: \.self) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        tabView(tab)
                    }
                }
            }
            .padding(8)
            .background(.ultraThinMaterial)
            .cornerRadius(24)
            .shadow(radius: 4, y: 2)
            .padding(.horizontal, 16)
            .padding(.bottom)

        }
    }

    @ViewBuilder
    private func tabView(_ tab: Tab) -> some View {
        VStack(spacing: 4) {
            Image(systemName: tab.icon)
                .font(.system(size: 20))
            Text(tab.title)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(selectedTab == tab ? .white : .gray)
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Tab Enum
extension ContentView {
    enum Tab: Hashable {
        case timer, tasks, settings

        var icon: String {
            switch self {
            case .timer: return "timer"
            case .tasks: return "checklist"
            case .settings: return "gear"
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
            case .timer: return Color.init(hex: "FFD700")
            case .tasks: return Color.init(hex: "FF6347")
            case .settings: return Color.init(hex: "4169E1")
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(TimerViewModel())
        .environmentObject(TaskViewModel())
}
