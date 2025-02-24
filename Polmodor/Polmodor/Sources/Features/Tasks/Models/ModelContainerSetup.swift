//
//  ModelContainerSetup.swift
//  Polmodor
//
//  Created by sedat ateş on 24.02.2025.
//

import SwiftData
import SwiftUI

// MARK: - Model Container Setup
struct ModelContainerSetup {
    @MainActor static func setupModelContainer() -> ModelContainer {
        // Define the schema
        let schema = Schema([
            PolmodorTask.self,
            PolmodorSubTask.self,
            TaskCategory.self
        ])
        
        // Configuration
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // Check if we need to populate with initial data
            let descriptor = FetchDescriptor<TaskCategory>()
            let categories = try container.mainContext.fetch(descriptor)
            
            if categories.isEmpty {
                // Add default categories
                for category in TaskCategory.defaultCategories {
                    container.mainContext.insert(category)
                }
                
                // Create sample tasks
                for task in PolmodorTask.mockTasks {
                    container.mainContext.insert(task)
                }
                
                try container.mainContext.save()
            }
            
            return container
        } catch {
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }
}

// MARK: - SwiftData Preview Container Helper
struct PreviewContainer {
    static var container: ModelContainer = {
        // Define schema
        let schema = Schema([
            PolmodorTask.self,
            PolmodorSubTask.self,
            TaskCategory.self
        ])
        
        // Use in-memory store for previews
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            
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
