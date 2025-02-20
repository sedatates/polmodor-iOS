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
    
    var body: some View {
        Form {
            Section("Timer Durations") {
                Stepper("Work: \(workDuration) minutes", value: $workDuration, in: 15...60, step: 5)
                Stepper("Short Break: \(shortBreakDuration) minutes", value: $shortBreakDuration, in: 3...15)
                Stepper("Long Break: \(longBreakDuration) minutes", value: $longBreakDuration, in: 10...30, step: 5)
                Stepper("Pomodoros until Long Break: \(pomodorosUntilLongBreak)", value: $pomodorosUntilLongBreak, in: 2...6)
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
                Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
                    Label("Notification Settings", systemImage: "bell.badge")
                }
                
                Link(destination: URL(string: "https://github.com/yourusername/polmodor/issues")!) {
                    Label("Report an Issue", systemImage: "exclamationmark.bubble")
                }
            }
            
            Section {
                NavigationLink {
                    AboutView()
                } label: {
                    Label("About", systemImage: "info.circle")
                }
            }
        }
        .navigationTitle("Settings")
    }
}

struct AboutView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    Image("AppIcon")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .cornerRadius(22)
                    
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
                Text("Polmodor is a Pomodoro Timer app designed to help you stay focused and productive. It uses the Pomodoro Technique™, a time management method developed by Francesco Cirillo.")
            }
            
            Section {
                Link(destination: URL(string: "https://github.com/yourusername/polmodor/blob/main/PRIVACY.md")!) {
                    Label("Privacy Policy", systemImage: "hand.raised")
                }
                
                Link(destination: URL(string: "https://github.com/yourusername/polmodor/blob/main/LICENSE")!) {
                    Label("License", systemImage: "doc.text")
                }
            }
            
            Section {
                Text("© 2024 Your Name. All rights reserved.")
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