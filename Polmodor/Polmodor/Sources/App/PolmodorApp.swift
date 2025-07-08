import SwiftData
import SwiftUI

@main
struct PolmodorApp: App {
    private let modelContainer = ModelContainerSetup.setupModelContainer()
    @StateObject private var timerViewModel = TimerViewModel()

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    init() {
        NotificationManager.shared.requestAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
                    .modelContainer(modelContainer)
                    .environmentObject(timerViewModel)
            } else {
                OnboardingView()
            }
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
