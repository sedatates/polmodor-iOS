import Combine
import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsModels: [SettingsModel]

    // ThemeManager referansı
    @Environment(\.themeManager) private var themeManager

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

    var body: some View {
        List {
            Group {
                Section("Timer Durations") {
                    Stepper(
                        "Work: \(settings.workDuration) minutes",
                        value: Binding(
                            get: { settings.workDuration },
                            set: { newValue in
                                settings.workDuration = newValue
                                try? modelContext.save()
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
                            }
                        ),
                        in: 4...10,
                        step: 1
                    )
                    .padding(.vertical, 4)
                }

                Section("Automation") {
                    Toggle(
                        "Auto-start Breaks",
                        isOn: Binding(
                            get: { settings.autoStartBreaks },
                            set: { newValue in
                                settings.autoStartBreaks = newValue
                                try? modelContext.save()
                            }
                        )
                    )
                    .padding(.vertical, 2)

                    Toggle(
                        "Auto-start Pomodoros",
                        isOn: Binding(
                            get: { settings.autoStartPomodoros },
                            set: { newValue in
                                settings.autoStartPomodoros = newValue
                                try? modelContext.save()
                            }
                        )
                    )
                    .padding(.vertical, 2)
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
                                themeManager.setDarkMode(newValue)
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
                    .padding(.vertical, 2)
                }

                Section {
                    Button("Reset to Defaults") {
                        settings.resetToDefaults()
                        themeManager.setDarkMode(settings.isDarkModeEnabled)
                        try? modelContext.save()
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
        .onAppear {
            // Tema yöneticisini güncelle
            themeManager.setDarkMode(settings.isDarkModeEnabled)
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
