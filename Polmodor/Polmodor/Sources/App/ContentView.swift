import Combine
import SwiftData
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var timerViewModel: TimerViewModel
    @AppStorage("selectedTab") private var selectedTab: Int = 0
    
    private var currentTab: Tab {
        switch selectedTab {
        case 0: return .timer
        case 1: return .tasks
        case 2: return .settings
        default: return .timer
        }
    }
    
    private func updateSelectedTabStorage(_ tab: Tab) {
        switch tab {
        case .timer: selectedTab = 0
        case .tasks: selectedTab = 1
        case .settings: selectedTab = 2
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            TabView(
                selection: Binding(
                    get: { currentTab },
                    set: { updateSelectedTabStorage($0) }
                )
            ) {
                TimerView()
                    .environmentObject(timerViewModel)
                    .tag(Tab.timer)
                
                NavigationStack {
                    TaskListView()
                }
                .toolbarBackground(.hidden, for: .tabBar)
                .tag(Tab.tasks)
                
                NavigationStack {
                    SettingsView()
                }
                .toolbarBackground(.hidden, for: .tabBar)
                .tag(Tab.settings)
            }
            .toolbarBackground(.hidden, for: .tabBar)
            
            
            .safeAreaInset(edge: .bottom) {
                ModernTabBar(
                    selectedTab: Binding(
                        get: { currentTab },
                        set: { updateSelectedTabStorage($0) }
                    )
                )
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .withAppTheme()
    }
}

struct ModernTabBar: View {
    @Binding var selectedTab: ContentView.Tab
    @Namespace private var animation
    @Environment(\.colorScheme) private var colorScheme
    private let themeManager = ThemeManager.shared
    
    var body: some View {
        HStack {
            ForEach([ContentView.Tab.timer, .tasks, .settings], id: \.self) { tab in
                TabButton(tab: tab, selectedTab: $selectedTab, namespace: animation)
            }
        }
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                
                .fill(themeManager.isDarkMode ? .ultraThinMaterial : .ultraThick)
                .fill(themeManager.isDarkMode ? Color.black.opacity(0.2) : .white)
                .shadow(
                    color: themeManager.isDarkMode ? .black.opacity(0.15) : .black.opacity(0.05),
                    radius: 15, x: 0, y: 5)
                .opacity(selectedTab == .timer ? 0.2 : 1)
        }
    }
}

struct TabButton: View {
    let tab: ContentView.Tab
    @Binding var selectedTab: ContentView.Tab
    var namespace: Namespace.ID
    @Environment(\.colorScheme) private var colorScheme
    private let themeManager = ThemeManager.shared
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: selectedTab == tab ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 24, weight: selectedTab == tab ? .semibold : .regular))
                    .foregroundStyle(
                        selectedTab == tab
                        ? tab.color
                        : themeManager.isDarkMode ? .gray.opacity(0.7) : .gray.opacity(0.9)
                    )
                    .symbolEffect(.bounce, value: selectedTab == tab)
                
                Text(tab.title)
                    .font(.system(size: 12, weight: selectedTab == tab ? .medium : .regular))
                    .foregroundStyle(
                        selectedTab == tab
                        ? tab.color
                        : themeManager.isDarkMode ? .gray.opacity(0.7) : .gray.opacity(0.5))
                
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
            case .timer: return Color(hex: "FF5722")
            case .tasks: return Color(hex: "4CAF50")
            case .settings: return Color(hex: "FFC107")
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(TimerViewModel())
        .modelContainer(ModelContainerSetup.setupModelContainer())
}
