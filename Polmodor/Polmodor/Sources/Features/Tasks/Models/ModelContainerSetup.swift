//
//  ModelContainerSetup.swift
//  Polmodor
//
//  Created by sedat ateş on 24.02.2025.
//

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

// MARK: - SwiftData Preview Container Helper
@MainActor
struct PreviewContainer {
    static var container: ModelContainer = {
        let schema = Schema([
            PolmodorTask.self,
            PolmodorSubTask.self,
            TaskCategory.self,
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )

            // Add sample data for preview
            for category in TaskCategory.defaultCategories {
                container.mainContext.insert(category)
            }

            for task in PolmodorTask.mockTasks {
                container.mainContext.insert(task)
            }

            return container
        } catch {
            fatalError("Failed to create preview container: \(error.localizedDescription)")
        }
    }()
}
