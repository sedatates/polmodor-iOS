import Foundation
import SwiftData
import SwiftUI

/// SettingsManager provides a singleton interface to access settings stored in SwiftData.
/// This class acts as a bridge between the SwiftData model and the rest of the app.
@Observable final class SettingsManager {
  static let shared = SettingsManager()

  // MARK: - Properties with Fallbacks
  var workDurationMinutes: Int = 25
  var shortBreakDurationMinutes: Int = 5
  var longBreakDurationMinutes: Int = 15
  var pomodorosUntilLongBreakCount: Int = 4
  var shouldAutoStartBreaks: Bool = false
  var shouldAutoStartPomodoros: Bool = false
  var isNotificationsEnabled: Bool = true
  var isSoundEnabled: Bool = true

  // MARK: - Private Properties
  private var modelContext: ModelContext?

  // MARK: - Initialization
  private init() {}

  // MARK: - Public Methods
  @MainActor
  func configure(with modelContext: ModelContext) {
    self.modelContext = modelContext
    loadSettings()
  }

  @MainActor
  func updateWorkDuration(_ duration: Int) {
    guard let context = modelContext else { return }
    updateSettingsInContext(context) { settings in
      settings.workDuration = max(15, min(duration, 60))
      self.workDurationMinutes = settings.workDuration
    }
  }

  @MainActor
  func updateShortBreakDuration(_ duration: Int) {
    guard let context = modelContext else { return }
    updateSettingsInContext(context) { settings in
      settings.shortBreakDuration = max(3, min(duration, 15))
      self.shortBreakDurationMinutes = settings.shortBreakDuration
    }
  }

  @MainActor
  func updateLongBreakDuration(_ duration: Int) {
    guard let context = modelContext else { return }
    updateSettingsInContext(context) { settings in
      settings.longBreakDuration = max(10, min(duration, 30))
      self.longBreakDurationMinutes = settings.longBreakDuration
    }
  }

  @MainActor
  func updatePomodorosUntilLongBreak(_ count: Int) {
    guard let context = modelContext else { return }
    updateSettingsInContext(context) { settings in
      settings.pomodorosUntilLongBreak = max(2, min(count, 10))
      self.pomodorosUntilLongBreakCount = settings.pomodorosUntilLongBreak
    }
  }

  @MainActor
  func updateAutoStartBreaks(_ enabled: Bool) {
    guard let context = modelContext else { return }
    updateSettingsInContext(context) { settings in
      settings.autoStartBreaks = enabled
      self.shouldAutoStartBreaks = enabled
    }
  }

  @MainActor
  func updateAutoStartPomodoros(_ enabled: Bool) {
    guard let context = modelContext else { return }
    updateSettingsInContext(context) { settings in
      settings.autoStartPomodoros = enabled
      self.shouldAutoStartPomodoros = enabled
    }
  }

  @MainActor
  func updateNotificationsEnabled(_ enabled: Bool) {
    guard let context = modelContext else { return }
    updateSettingsInContext(context) { settings in
      settings.isNotificationEnabled = enabled
      self.isNotificationsEnabled = enabled
    }
  }

  @MainActor
  func updateSoundEnabled(_ enabled: Bool) {
    guard let context = modelContext else { return }
    updateSettingsInContext(context) { settings in
      settings.isSoundEnabled = enabled
      self.isSoundEnabled = enabled
    }
  }

  // MARK: - Private Methods
  @MainActor
  private func loadSettings() {
    guard let context = modelContext else { return }

    do {
      let descriptor = FetchDescriptor<SettingsModel>()

      // Try to fetch settings
      let settingsArray = try context.fetch(descriptor)

      // Get first settings or create default
      if let settings = settingsArray.first {
        // Update the local properties
        self.workDurationMinutes = settings.workDuration
        self.shortBreakDurationMinutes = settings.shortBreakDuration
        self.longBreakDurationMinutes = settings.longBreakDuration
        self.pomodorosUntilLongBreakCount = settings.pomodorosUntilLongBreak
        self.shouldAutoStartBreaks = settings.autoStartBreaks
        self.shouldAutoStartPomodoros = settings.autoStartPomodoros
        self.isNotificationsEnabled = settings.isNotificationEnabled
        self.isSoundEnabled = settings.isSoundEnabled
      } else {
        // Create default settings
        createDefaultSettings(in: context)
      }
    } catch {
      print("Failed to load settings: \(error)")
      createDefaultSettings(in: context)
    }
  }

  @MainActor
  private func createDefaultSettings(in context: ModelContext) {
    // Create a default settings model with our local values
    let defaultSettings = SettingsModel(
      workDuration: self.workDurationMinutes,
      shortBreakDuration: self.shortBreakDurationMinutes,
      longBreakDuration: self.longBreakDurationMinutes,
      pomodorosUntilLongBreak: self.pomodorosUntilLongBreakCount,
      autoStartBreaks: self.shouldAutoStartBreaks,
      autoStartPomodoros: self.shouldAutoStartPomodoros,
      isNotificationEnabled: self.isNotificationsEnabled,
      isSoundEnabled: self.isSoundEnabled
    )

    // Insert and save
    context.insert(defaultSettings)
    try? context.save()
  }

  @MainActor
  private func updateSettingsInContext(_ context: ModelContext, updates: (SettingsModel) -> Void) {
    do {
      let descriptor = FetchDescriptor<SettingsModel>()
      let settingsArray = try context.fetch(descriptor)

      if let settings = settingsArray.first {
        // Update existing settings
        updates(settings)
        try context.save()
      } else {
        // Create new default settings if none exist
        let newSettings = SettingsModel(
          workDuration: self.workDurationMinutes,
          shortBreakDuration: self.shortBreakDurationMinutes,
          longBreakDuration: self.longBreakDurationMinutes,
          pomodorosUntilLongBreak: self.pomodorosUntilLongBreakCount,
          autoStartBreaks: self.shouldAutoStartBreaks,
          autoStartPomodoros: self.shouldAutoStartPomodoros,
          isNotificationEnabled: self.isNotificationsEnabled,
          isSoundEnabled: self.isSoundEnabled
        )

        // Apply the updates
        updates(newSettings)

        // Insert and save
        context.insert(newSettings)
        try context.save()
      }
    } catch {
      print("Failed to update settings: \(error)")
    }
  }
}
