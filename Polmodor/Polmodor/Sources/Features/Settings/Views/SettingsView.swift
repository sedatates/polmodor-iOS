import Combine
import SwiftData
import SwiftUI

struct SettingsView: View {
  @Environment(\.modelContext) private var modelContext
  @Query private var settingsModels: [SettingsModel]
  @State private var subscriptionManager = SubscriptionManager.shared
  @State private var paywallManager = PaywallManager.shared
  @State private var showPaywallForUpgrade = false

  // Aktif ayarlar
  private var settings: SettingsModel {
    // Eğer hiç ayar yoksa, yeni bir tane oluştur
    if let firstSettings = settingsModels.first {
      return firstSettings
    } else {
      let newSettings = SettingsModel()
      modelContext.insert(newSettings)
      return newSettings
    }
  }

  private var dateFormatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter
  }

  var body: some View {
    List {
      Group {
        // Premium Status Section
        Section("Premium Status") {
          HStack {
            Image(systemName: subscriptionManager.isPremium ? "crown.fill" : "crown")
              .foregroundColor(subscriptionManager.isPremium ? .yellow : .gray)
              .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
              Text(subscriptionManager.getPremiumStatusText())
                .font(.headline)
                .foregroundColor(subscriptionManager.isPremium ? .green : .primary)

              if subscriptionManager.isPremium {
                if let expirationDate = subscriptionManager.getSubscriptionExpirationDate() {
                  Text("Expires: \(expirationDate, formatter: dateFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                } else {
                  Text("Lifetime subscription")
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
              } else {
                Text("Upgrade to unlock all features")
                  .font(.caption)
                  .foregroundColor(.secondary)
              }
            }

            Spacer()

            if !subscriptionManager.isPremium {
              Button("Upgrade") {
                showPaywallForUpgrade = true
              }
              .buttonStyle(.borderedProminent)
              .controlSize(.small)
            }
          }
          .padding(.vertical, 8)
        }

        Section("Timer Durations") {
          Stepper(
            "Work: \(settings.workDuration) minutes",
            value: Binding(
              get: { settings.workDuration },
              set: { newValue in
                settings.workDuration = newValue
                try? modelContext.save()
                NotificationCenter.default.post(
                  name: NSNotification.Name("SettingsChanged"), object: nil)
              }
            ),
            in: 15...60,
            step: 5
          )
          .padding(.vertical, 4)

          Stepper(
            "Short Break: \(settings.shortBreakDuration) minutes",
            value: Binding(
              get: { settings.shortBreakDuration },
              set: { newValue in
                settings.shortBreakDuration = newValue
                try? modelContext.save()
                NotificationCenter.default.post(
                  name: NSNotification.Name("SettingsChanged"), object: nil)
              }
            ),
            in: 5...15,
            step: 5
          )
          .padding(.vertical, 4)

          Stepper(
            "Long Break: \(settings.longBreakDuration) minutes",
            value: Binding(
              get: { settings.longBreakDuration },
              set: { newValue in
                settings.longBreakDuration = newValue
                try? modelContext.save()
                NotificationCenter.default.post(
                  name: NSNotification.Name("SettingsChanged"), object: nil)
              }
            ),
            in: 10...30,
            step: 5
          )
          .padding(.vertical, 4)

          Stepper(
            "Pomodoros Until Long Break: \(settings.pomodorosUntilLongBreak)",
            value: Binding(
              get: { settings.pomodorosUntilLongBreak },
              set: { newValue in
                settings.pomodorosUntilLongBreak = newValue
                try? modelContext.save()
                NotificationCenter.default.post(name: NSNotification.Name("SettingsChanged"), object: nil)
              }
            ),
            in: 4...10,
            step: 1
          )
          .padding(.vertical, 4)
        }

        Section("Notifications") {
          Toggle(
            "Show Notifications",
            isOn: Binding(
              get: { settings.isNotificationEnabled },
              set: { newValue in
                settings.isNotificationEnabled = newValue
                try? modelContext.save()
              }
            )
          )
          .padding(.vertical, 2)

          Toggle(
            "Play Sound",
            isOn: Binding(
              get: { settings.isSoundEnabled },
              set: { newValue in
                settings.isSoundEnabled = newValue
                try? modelContext.save()
              }
            )
          )
          .padding(.vertical, 2)
        }

        Section("Appearance") {
          Toggle(
            "Dark Mode",
            isOn: Binding(
              get: { settings.isDarkModeEnabled },
              set: { newValue in
                settings.isDarkModeEnabled = newValue
                try? modelContext.save()
              }
            )
          )
          .padding(.vertical, 2)
        }

        Section {
          Link(destination: URL(string: "app-settings://")!) {
            Label("Notification Settings", systemImage: "bell.badge")
          }
          .padding(.vertical, 2)

          Link(
            destination: URL(string: "https://github.com/yourusername/polmodor/issues")!
          ) {
            Label("Report an Issue", systemImage: "exclamationmark.bubble")
          }
          .padding(.vertical, 2)
        }

        Section {
          NavigationLink(
            destination: AboutView(),
            label: {
              Label("About Polmodor", systemImage: "info.circle")
            }
          )
        }

        Section {
          Button("Reset to Defaults") {
            settings.resetToDefaults()
            try? modelContext.save()
          }
          .padding(.vertical, 2)
        }
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle("Settings")
    .navigationBarTitleDisplayMode(.large)
    // Modern RevenueCat Paywall Integration
    .presentPolmodorPaywallWhen(showPaywallForUpgrade)
    .onChange(of: subscriptionManager.isPremium) { _, isPremium in
      if isPremium {
        showPaywallForUpgrade = false
      }
    }
  }
}

struct AboutView: View {
  var body: some View {
    List {
      Section {
        VStack(spacing: 16) {
          Image("polmodorIcon")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: 100)

          Text("Polmodor")
            .font(.title.bold())

          Text("Version 1.0.0 (1)")
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical)
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
      }

      Section("About") {
        Text(
          "Polmodor is a Pomodoro Timer app designed to help you stay focused and productive. It's simple, elegant, and easy to use."
        )
        .padding(.vertical, 8)
      }

      Section {
        Link(
          destination: URL(
            string: "https://github.com/yourusername/polmodor/blob/main/PRIVACY.md")!
        ) {
          Label("Privacy Policy", systemImage: "hand.raised")
        }
        .padding(.vertical, 2)

        Link(
          destination: URL(
            string: "https://github.com/yourusername/polmodor/blob/main/LICENSE")!
        ) {
          Label("License", systemImage: "doc.text")
        }
        .padding(.vertical, 2)
      }

      Section {
        Text("© \(Image(systemName: "heart.text.square")) Sedat Ates")
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, alignment: .center)
          .padding(.vertical, 4)
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle("About")
    .safeAreaInset(edge: .bottom) {
      Color.clear.frame(height: 100)
    }
  }
}

#Preview {
  NavigationStack {
    SettingsView()
      .modelContainer(for: SettingsModel.self)

  }
}
