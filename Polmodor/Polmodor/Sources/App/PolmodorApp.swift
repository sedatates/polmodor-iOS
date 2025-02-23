import SwiftUI

@main
struct PolmodorApp: App {
    @StateObject private var timerViewModel = TimerViewModel()
    @StateObject private var taskViewModel = TaskViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(timerViewModel)
                .environmentObject(taskViewModel)
        }
    }
}

class AppState: ObservableObject {
    @Published var selectedTab: Tab = .timer
    
    enum Tab {
        case timer
        case tasks
        case settings
    }
}
