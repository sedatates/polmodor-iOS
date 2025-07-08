import SwiftData
import SwiftUI

@main
struct PolmodorApp: App {
  private let modelContainer = ModelContainerSetup.setupModelContainer()
  @StateObject private var timerViewModel = TimerViewModel()

  @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
  @State private var showSplashScreen = true

  init() {
    NotificationManager.shared.requestAuthorization()
  }

  var body: some Scene {
    WindowGroup {
      ZStack {
        if showSplashScreen {
          SplashScreenView {
            withAnimation(.easeInOut(duration: 0.5)) {
              showSplashScreen = false
            }
          }
          .transition(.opacity)
        } else {
          if hasCompletedOnboarding {
            ContentView()
              .modelContainer(modelContainer)
              .environmentObject(timerViewModel)
              .onAppear {
                SettingsManager.shared.configure(with: modelContainer.mainContext)
              }
              .transition(.opacity)
          } else {
            OnboardingView()
              .transition(.opacity)
          }
        }
      }
      .animation(.easeInOut(duration: 0.5), value: showSplashScreen)
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
