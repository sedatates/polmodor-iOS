import SwiftData
import SwiftUI

@main
struct PolmodorApp: App {
    @StateObject private var timerViewModel = TimerViewModel()
    private let modelContainer = ModelContainerSetup.setupModelContainer()

    // ThemeManager instance - environment üzerinden erişilebilir
    @StateObject private var themeManager: ThemeManager = ThemeManager.shared

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
        }
    }

    // Tema değişikliğini uygula - platform bağımsız
    private func updateColorScheme(_ colorScheme: ColorScheme) {
        // SwiftUI bu değişiklikleri otomatik olarak işler
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
