import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        if !hasCompletedOnboarding {
            OnboardingView()
        } else {
            TabView {
                TimerView()
                    .tabItem {
                        Label("Timer", systemImage: "timer")
                    }
                
                TaskListView()
                    .tabItem {
                        Label("Tasks", systemImage: "checklist")
                    }
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(TimerViewModel())
        .environmentObject(TaskViewModel())
} 