import SwiftData
import SwiftUI

@main
struct PolmodorApp: App {
    @StateObject private var timerViewModel = TimerViewModel()
    private let modelContainer = ModelContainerSetup.setupModelContainer()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .environmentObject(timerViewModel)
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
