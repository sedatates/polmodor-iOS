import Combine
import SwiftData
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var timerViewModel: TimerViewModel
    @Query private var settingsModels: [SettingsModel]
    
    var body: some View {
        NavigationStack {
            TimerView()
                .environmentObject(timerViewModel)
        }
        .preferredColorScheme(
            settingsModels.first?.isDarkModeEnabled == true ? .dark : .light
        )
    }
}

#Preview {
    ContentView()
        .environmentObject(TimerViewModel())
        .modelContainer(ModelContainerSetup.setupModelContainer())
}
