import SwiftUI

struct ContentView: View {
    @AppStorage(
        "hasCompletedOnboarding"
    ) private var hasCompletedOnboarding = false
    
    var body: some View {
        if !hasCompletedOnboarding {
            OnboardingView()
        } else {
            TabView {
                
                Tab(
                    "Timer",
                    systemImage:"timer"
                ){
                    TimerView()
                }
                Tab(
                    "Tasks",
                    systemImage:"checklist"
                ){
                    TaskListView()
                }
                Tab(
                    "Settings",
                    systemImage:"gear"
                ){
                    SettingsView()
                }
                
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(
            TimerViewModel()
        )
        .environmentObject(
            TaskViewModel()
        )
}
