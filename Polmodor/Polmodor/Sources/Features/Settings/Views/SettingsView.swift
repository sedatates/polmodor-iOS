import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsModels: [SettingsModel]

    private var settings: SettingsModel {
        // Ensure we always have a settings model
        if let firstSettings = settingsModels.first {
            return firstSettings
        } else {
            let newSettings = SettingsModel()
            modelContext.insert(newSettings)
            return newSettings
        }
    }

    // Bindings for the settings properties
    private var workDuration: Binding<Int> {
        Binding(
            get: { self.settings.workDuration },
            set: { self.settings.workDuration = $0 }
        )
    }

    private var shortBreakDuration: Binding<Int> {
        Binding(
            get: { self.settings.shortBreakDuration },
            set: { self.settings.shortBreakDuration = $0 }
        )
    }

    private var longBreakDuration: Binding<Int> {
        Binding(
            get: { self.settings.longBreakDuration },
            set: { self.settings.longBreakDuration = $0 }
        )
    }

    private var pomodorosUntilLongBreak: Binding<Int> {
        Binding(
            get: { self.settings.pomodorosUntilLongBreak },
            set: { self.settings.pomodorosUntilLongBreak = $0 }
        )
    }

    private var autoStartBreaks: Binding<Bool> {
        Binding(
            get: { self.settings.autoStartBreaks },
            set: { self.settings.autoStartBreaks = $0 }
        )
    }

    private var autoStartPomodoros: Binding<Bool> {
        Binding(
            get: { self.settings.autoStartPomodoros },
            set: { self.settings.autoStartPomodoros = $0 }
        )
    }

    private var isNotificationEnabled: Binding<Bool> {
        Binding(
            get: { self.settings.isNotificationEnabled },
            set: { self.settings.isNotificationEnabled = $0 }
        )
    }

    private var isSoundEnabled: Binding<Bool> {
        Binding(
            get: { self.settings.isSoundEnabled },
            set: { self.settings.isSoundEnabled = $0 }
        )
    }

    private var isDarkModeEnabled: Binding<Bool> {
        Binding(
            get: { self.settings.isDarkModeEnabled },
            set: { self.settings.isDarkModeEnabled = $0 }
        )
    }

    var body: some View {
        List {
            Group {
                Section("Timer Durations") {
                    Stepper(
                        "Work: \(settings.workDuration) minutes",
                        value: workDuration,
                        in: 15...60,
                        step: 5
                    )
                    .padding(.vertical, 4)

                    Stepper(
                        "Short Break: \(settings.shortBreakDuration) minutes",
                        value: shortBreakDuration,
                        in: 5...15,
                        step: 5
                    )
                    .padding(.vertical, 4)

                    Stepper(
                        "Long Break: \(settings.longBreakDuration) minutes",
                        value: longBreakDuration,
                        in: 10...30,
                        step: 5
                    )
                    .padding(.vertical, 4)

                    Stepper(
                        "Pomodoros Until Long Break: \(settings.pomodorosUntilLongBreak)",
                        value: pomodorosUntilLongBreak,
                        in: 4...10,
                        step: 1
                    )
                    .padding(.vertical, 4)
                }

                Section("Automation") {
                    Toggle("Auto-start Breaks", isOn: autoStartBreaks)
                        .padding(.vertical, 2)
                    Toggle("Auto-start Pomodoros", isOn: autoStartPomodoros)
                        .padding(.vertical, 2)
                }

                Section("Notifications") {
                    Toggle("Show Notifications", isOn: isNotificationEnabled)
                        .padding(.vertical, 2)
                    Toggle("Play Sound", isOn: isSoundEnabled)
                        .padding(.vertical, 2)
                }

                Section("Appearance") {
                    Toggle("Dark Mode", isOn: isDarkModeEnabled)
                        .padding(.vertical, 2)
                        .onChange(of: settings.isDarkModeEnabled) { _, newValue in
                            // Apply theme change
                            setAppearance(darkMode: newValue)
                        }
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
                    .padding(.vertical, 2)
                }

                Section {
                    Button("Reset to Defaults") {
                        resetToDefaults()
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 100)
        }
    }

    private func resetToDefaults() {
        settings.workDuration = 25
        settings.shortBreakDuration = 5
        settings.longBreakDuration = 15
        settings.pomodorosUntilLongBreak = 4
        settings.autoStartBreaks = false
        settings.autoStartPomodoros = false
        settings.isNotificationEnabled = true
        settings.isSoundEnabled = true
        settings.isDarkModeEnabled = false

        // Apply theme change if needed
        setAppearance(darkMode: false)
    }

    private func setAppearance(darkMode: Bool) {
        #if os(iOS)
            // Apply appearance change
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                let window = windowScene.windows.first
            {
                window.overrideUserInterfaceStyle = darkMode ? .dark : .light
            }
        #endif
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
