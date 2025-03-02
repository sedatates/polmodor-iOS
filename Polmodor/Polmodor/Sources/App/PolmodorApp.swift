import SwiftData
import SwiftUI

@main
struct PolmodorApp: App {
    // Initialize timerViewModel with the ModelContainer at app launch
    @StateObject private var timerViewModel: TimerViewModel
    private let modelContainer = ModelContainerSetup.setupModelContainer()

    // ThemeManager instance - environment üzerinden erişilebilir
    @StateObject private var themeManager: ThemeManager = ThemeManager.shared

    // Initialize with proper setup
    init() {
        // Create TimerViewModel with model container for persistence
        let viewModel = TimerViewModel(modelContainer: ModelContainerSetup.setupModelContainer())
        _timerViewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .environmentObject(timerViewModel)
                .environment(\.themeManager, ThemeManager.shared)
                .preferredColorScheme(ThemeManager.shared.colorScheme)
                .onChange(of: ThemeManager.shared.isDarkMode) { oldValue, newValue in
                    // ThemeManager değiştiğinde, SwiftUI'nin kendi tema yönetimini güncelle
                    let newColorScheme: ColorScheme = newValue ? .dark : .light
                    updateColorScheme(newColorScheme)
                }
                .onDisappear {
                    // Save timer state when app goes to background
                    saveAppState()
                }
                .onReceive(
                    NotificationCenter.default.publisher(
                        for: UIApplication.willResignActiveNotification)
                ) { _ in
                    // Save timer state when app goes to background
                    saveAppState()
                }
        }
    }

    // Tema değişikliğini uygula - platform bağımsız
    private func updateColorScheme(_ colorScheme: ColorScheme) {
        // SwiftUI bu değişiklikleri otomatik olarak işler
    }

    // Save app state when going to background
    private func saveAppState() {
        // This will trigger our custom save function
        // that persists the current timer state and active subtask
        timerViewModel.saveTimerState()
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
