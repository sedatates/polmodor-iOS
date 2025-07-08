//
//  ModelContainerSetup.swift
//  Polmodor
//
//  Created by sedat ateş on 24.02.2025.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Model Container Setup

enum ModelContainerSetup {
    @MainActor
    static func setupModelContainer() -> ModelContainer {
        let schema = Schema([
            PolmodorTask.self,
            PolmodorSubTask.self,
            TaskCategory.self,
            SettingsModel.self,
            StatisticsModel.self,
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )

            // Check if we need to populate with initial data
            let descriptor = FetchDescriptor<TaskCategory>()
            let categories = try container.mainContext.fetch(descriptor)

            if categories.isEmpty {
                populateInitialData(in: container)
            }

            // Check if we need to create default settings
            let settingsDescriptor = FetchDescriptor<SettingsModel>()
            let settings = try container.mainContext.fetch(settingsDescriptor)

            if settings.isEmpty {
                // Create default settings
                let defaultSettings = SettingsModel()
                container.mainContext.insert(defaultSettings)
                try container.mainContext.save()
            }

            return container
        } catch {
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }

    @MainActor
    private static func populateInitialData(in container: ModelContainer) {
        // Add default categories
        for category in TaskCategory.defaultCategories {
            container.mainContext.insert(category)
        }

        // Create sample tasks
        for task in PolmodorTask.mockTasks {
            container.mainContext.insert(task)
        }

        do {
            try container.mainContext.save()
        } catch {
            print("Failed to save initial data: \(error.localizedDescription)")
        }
    }
}
