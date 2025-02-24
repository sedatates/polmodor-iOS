import SwiftData
import SwiftUI

@main
struct PolmodorApp: App {
    @StateObject private var timerViewModel = TimerViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(timerViewModel)
                .modelContainer(ModelContainerSetup.setupModelContainer())
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
