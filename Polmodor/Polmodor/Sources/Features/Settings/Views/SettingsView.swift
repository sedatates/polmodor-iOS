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
    @AppStorage("zenModeEnabled") private var zenModeEnabled = false
    @AppStorage("zenModeDelay") private var zenModeDelay = 3.0  // seconds

    var body: some View {
        List {
            Group {
                Section("Timer Durations") {
                    Stepper(
                        "Work: \(workDuration) minutes",
                        value: $workDuration,
                        in: 15...60,
                        step: 5
                    )
                    .padding(.vertical, 4)

                    Stepper(
                        "Short Break: \(shortBreakDuration) minutes",
                        value: $shortBreakDuration,
                        in: 3...15
                    )
                    .padding(.vertical, 4)

                    Stepper(
                        "Long Break: \(longBreakDuration) minutes",
                        value: $longBreakDuration,
                        in: 10...30,
                        step: 5
                    )
                    .padding(.vertical, 4)

                    Stepper(
                        "Pomodoros until Long Break: \(pomodorosUntilLongBreak)",
                        value: $pomodorosUntilLongBreak,
                        in: 2...6
                    )
                    .padding(.vertical, 4)
                }

                Section {
                    VStack(spacing: 16) {
                        // Zen Mode Feature
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "moon.stars")
                                    .font(.title2)
                                    .foregroundColor(.purple)
                                Text("Zen Mode")
                                    .font(.headline)
                                Spacer()
                                Toggle("", isOn: $zenModeEnabled)
                                    .tint(.purple)
                            }

                            if zenModeEnabled {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(
                                        "Controls will fade away after inactivity to help you stay focused."
                                    )
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .padding(.leading, 30)

                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text("Fade Delay: \(Int(zenModeDelay))s")
                                                .font(.subheadline.weight(.medium))
                                            Spacer()
                                        }
                                        .padding(.leading, 30)

                                        Slider(value: $zenModeDelay, in: 5...10, step: 1)
                                            .tint(.purple)
                                            .padding(.leading, 30)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                        )
                    }
                    .padding(.vertical, 8)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                } header: {
                    Text("Focus Features")
                }

                Section("Automation") {
                    Toggle("Auto-start Breaks", isOn: $autoStartBreaks)
                        .padding(.vertical, 2)
                    Toggle("Auto-start Pomodoros", isOn: $autoStartPomodoros)
                        .padding(.vertical, 2)
                }

                Section("Notifications") {
                    Toggle("Show Notifications", isOn: $showNotifications)
                        .padding(.vertical, 2)
                    Toggle("Play Sound", isOn: $playSound)
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
                        workDuration = 25
                        shortBreakDuration = 5
                        longBreakDuration = 15
                        pomodorosUntilLongBreak = 4
                        autoStartBreaks = false
                        autoStartPomodoros = false
                        showNotifications = true
                        playSound = true
                        zenModeEnabled = false
                        zenModeDelay = 3.0
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
    }
}
