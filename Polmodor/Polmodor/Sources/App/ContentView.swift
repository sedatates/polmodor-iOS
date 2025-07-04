import Combine
import SwiftData
import SwiftUI

struct ContentView: View {
  @EnvironmentObject var timerViewModel: TimerViewModel
  @Query private var settingsModels: [SettingsModel]
  @State private var subscriptionManager = SubscriptionManager.shared

  var body: some View {
    NavigationStack {
      TimerView()
        .environmentObject(timerViewModel)
    }
    .preferredColorScheme(
      settingsModels.first?.isDarkModeEnabled == true ? .dark : .light
    )
    // Modern RevenueCat Paywall Integration - Base layer
    .presentPolmodorPaywallIfNeeded()
    .onAppear {
      // Check subscription status when app appears
      print("📱 ContentView appeared, checking subscription status")
      subscriptionManager.checkSubscriptionStatus()
    }
  }
}

#Preview {
  ContentView()
    .environmentObject(TimerViewModel())
    .modelContainer(ModelContainerSetup.setupModelContainer())
}
