import SwiftUI

struct SettingsView: View {
    @AppStorage("workDuration") private var workDuration = 25
    @AppStorage("shortBreakDuration") private var shortBreakDuration = 5
    @AppStorage("longBreakDuration") private var longBreakDuration = 15
    @AppStorage("pomodorosUntilLongBreak") private var pomodorosUntilLongBreak = 4
    @AppStorage("autoStartBreaks") private var autoStartBreaks = false
    @AppStorage("autoStartPomodoros") private var autoStartPomodoros = false
    @AppStorage("showNotifications") private var showNotifications = true
    @AppStorage("playSound") private var playSound = true
    @AppStorage("forceLockEnabled") private var forceLockEnabled = false
    @AppStorage("zenModeEnabled") private var zenModeEnabled = false
    @AppStorage("zenModeDelay") private var zenModeDelay = 3.0  // seconds

    var body: some View {
        NavigationView {
            Form {
                Section("Timer Durations") {
                    Stepper(
                        "Work: \(workDuration) minutes", value: $workDuration, in: 15...60, step: 5)
                    Stepper(
                        "Short Break: \(shortBreakDuration) minutes", value: $shortBreakDuration,
                        in: 3...15)
                    Stepper(
                        "Long Break: \(longBreakDuration) minutes", value: $longBreakDuration,
                        in: 10...30, step: 5)
                    Stepper(
                        "Pomodoros until Long Break: \(pomodorosUntilLongBreak)",
                        value: $pomodorosUntilLongBreak, in: 2...6)
                }

                Section("Focus Features") {
                    Toggle("Force Lock", isOn: $forceLockEnabled)
                        .tint(.red)

                    if forceLockEnabled {
                        Text(
                            "When enabled, timer controls will be locked. You'll need to confirm to break your session."
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    Toggle("Zen Mode", isOn: $zenModeEnabled)
                        .tint(.purple)

                    if zenModeEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(
                                "Controls will fade away after \(String(format: "%.0f", zenModeDelay)) seconds of inactivity."
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)

                            Slider(value: $zenModeDelay, in: 2...10, step: 1) {
                                Text("Fade Delay")
                            } minimumValueLabel: {
                                Text("2s")
                                    .font(.caption)
                            } maximumValueLabel: {
                                Text("10s")
                                    .font(.caption)
                            }
                        }
                    }
                }

                Section("Automation") {
                    Toggle("Auto-start Breaks", isOn: $autoStartBreaks)
                    Toggle("Auto-start Pomodoros", isOn: $autoStartPomodoros)
                }

                Section("Notifications") {
                    Toggle("Show Notifications", isOn: $showNotifications)
                    Toggle("Play Sound", isOn: $playSound)
                }

                Section {
                    Link(destination: URL(string: "app-settings://")!) {
                        Label("Notification Settings", systemImage: "bell.badge")
                    }

                    Link(
                        destination: URL(string: "https://github.com/yourusername/polmodor/issues")!
                    ) {
                        Label("Report an Issue", systemImage: "exclamationmark.bubble")
                    }
                }

                Section {
                    NavigationLink(
                        destination: AboutView(),
                        label: {
                            Label("About Polmodor", systemImage: "info.circle")
                        })
                }

                Section {
                    Button("Reset to Defaults") {
                        workDuration = 25
                        shortBreakDuration = 5
                        longBreakDuration = 15
                        pomodorosUntilLongBreak = 4
                        autoStartBreaks = false
                        autoStartPomodoros = false
                        showNotifications = true
                        playSound = true
                        forceLockEnabled = false
                        zenModeEnabled = false
                        zenModeDelay = 3.0
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationSplitViewStyle(BalancedNavigationSplitViewStyle())
        }
    }
}

struct AboutView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    Image("AppIcon")
                        .renderingMode(.original)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)

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
                    "Polmodor is a Pomodoro Timer app designed to help you stay focused and productive. It uses the Pomodoro Technique™, a time management method developed by Francesco Cirillo."
                )
            }

            Section {
                Link(
                    destination: URL(
                        string: "https://github.com/yourusername/polmodor/blob/main/PRIVACY.md")!
                ) {
                    Label("Privacy Policy", systemImage: "hand.raised")
                }

                Link(
                    destination: URL(
                        string: "https://github.com/yourusername/polmodor/blob/main/LICENSE")!
                ) {
                    Label("License", systemImage: "doc.text")
                }
            }

            Section {
                Text("© \(Image(systemName: "copyright")) Sedat Ates")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        SettingsView()
    }
}
