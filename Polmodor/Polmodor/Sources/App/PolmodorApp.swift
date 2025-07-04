import SwiftData
import SwiftUI

@main
struct PolmodorApp: App {
  // Initialize timerViewModel with the ModelContainer at app launch
  @StateObject private var timerViewModel: TimerViewModel
  private let modelContainer = ModelContainerSetup.setupModelContainer()

  // Track whether onboarding has been completed
  @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

  // Initialize with proper setup
  init() {
    // Create TimerViewModel with model container for persistence
    let viewModel = TimerViewModel(modelContainer: ModelContainerSetup.setupModelContainer())
    _timerViewModel = StateObject(wrappedValue: viewModel)

    // Request notification permissions
    NotificationManager.shared.requestAuthorization()
  }

  var body: some Scene {
    WindowGroup {
      if hasCompletedOnboarding {
        ContentView()
          .modelContainer(modelContainer)
          .environmentObject(timerViewModel)
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
          .onReceive(
            NotificationCenter.default.publisher(
              for: UIApplication.didBecomeActiveNotification)
          ) { _ in
            // Update timer state when app comes to foreground
            restoreAppState()
          }
      } else {
        OnboardingView()
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

  // Restore app state when coming to foreground
  private func restoreAppState() {
    // Update timer state from LiveActivity when app becomes active
    //timerViewModel.updateFromLiveActivity()
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
