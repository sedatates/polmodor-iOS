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
                .onAppear {
                    // Set default settings if they don't exist
                    if UserDefaults.standard.object(forKey: "workDuration") == nil {
                        UserDefaults.standard.set(25, forKey: "workDuration")
                    }
                    if UserDefaults.standard.object(forKey: "shortBreakDuration") == nil {
                        UserDefaults.standard.set(5, forKey: "shortBreakDuration")
                    }
                    if UserDefaults.standard.object(forKey: "longBreakDuration") == nil {
                        UserDefaults.standard.set(15, forKey: "longBreakDuration")
                    }
                    if UserDefaults.standard.object(forKey: "pomodorosUntilLongBreak") == nil {
                        UserDefaults.standard.set(4, forKey: "pomodorosUntilLongBreak")
                    }
                    if UserDefaults.standard.object(forKey: "autoStartBreaks") == nil {
                        UserDefaults.standard.set(false, forKey: "autoStartBreaks")
                    }
                    if UserDefaults.standard.object(forKey: "autoStartPomodoros") == nil {
                        UserDefaults.standard.set(false, forKey: "autoStartPomodoros")
                    }

                    // Configure notification permissions
                    NotificationManager.shared.requestAuthorization()
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
