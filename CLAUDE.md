# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Development Commands

### Building the App

```bash
# Open project in Xcode
open Polmodor/Polmodor.xcodeproj

# Build from command line (if needed)
xcodebuild -project Polmodor/Polmodor.xcodeproj -scheme Polmodor -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

### Running the App

- Use Xcode to run on simulator or device
- Supports iOS 18.0+ only
- Widget extension runs alongside main app

## Architecture Overview

### Core Architecture Pattern

- **MVVM**: Uses `@StateObject`, `@ObservableObject`, `@EnvironmentObject` for state management
- **SwiftData**: Primary persistence layer (no Core Data)
- **Feature-based modules**: Each feature has its own Models/ViewModels/Views structure

### Key Architectural Components

#### App Layer (`Sources/App/`)

- `PolmodorApp.swift`: Main entry point with onboarding flow and ModelContainer setup
- `ContentView.swift`: Root view with custom tab navigation

#### Core Layer (`Sources/Core/`)

- **Services**: `NotificationManager`, `SoundManager` for system integrations
- **Utilities**: `TimerStateManager`, `SettingsManager`, `ModelContainerSetup`
- **Models**: `PolmodorLiveActivityAttributes` for Live Activities
- **Protocols**: Service abstractions for dependency injection

#### Features (`Sources/Features/`)

- **Timer**: Complete Pomodoro timer with Live Activities and Widget support
- **Tasks**: Hierarchical task management (tasks → subtasks → pomodoros)
- **Settings**: Timer configuration and app preferences
- **Onboarding**: First-time user experience

### Data Model Architecture (SwiftData)

#### Core Models

```swift
@Model class PolmodorTask {
    @Relationship(deleteRule: .cascade) var subTasks: [PolmodorSubTask]
    // Main task entity
}

@Model class PolmodorSubTask {
    @Relationship(inverse: \PolmodorTask.subTasks) var task: PolmodorTask?
    // Subtask with pomodoro tracking
}

@Model class SettingsModel {
    // App-wide configuration
}
```

#### Key Relationships

- Tasks have cascade-delete relationship with subtasks
- Settings are singleton managed by `SettingsManager`
- Timer state persists across app lifecycle

### State Management Patterns

#### Timer State Flow

1. `TimerViewModel` manages all timer logic
2. `TimerStateManager` handles persistence
3. Live Activities sync with timer state
4. Widget receives updates through App Groups

#### Task Management Flow

1. `TaskListViewModel` manages task collection
2. Individual `TaskViewModel` handles task operations
3. SwiftData automatic persistence with ModelContext
4. Environment object injection for shared state

### Widget & Live Activities Integration

#### Architecture

- `PolmodorWidget` target for Home Screen widgets
- `PolmodorWidgetLiveActivity` for Dynamic Island integration
- `AppIntent` for widget interactions
- Shared data models between app and widget

#### Communication Pattern

- App Groups for data sharing
- UserDefaults for simple state
- ModelContainer sharing between targets

## Development Guidelines

### SwiftData Usage

- Always use `@Model` macro for persistent entities
- Use `@Relationship` for entity relationships
- Access through `@Environment(\.modelContext)` in views
- Handle optional ModelContext gracefully

### State Management

- Use `@StateObject` for view model ownership
- Use `@ObservableObject` for view model observation
- Use `@EnvironmentObject` for shared state
- Keep state as close to usage as possible

### View Architecture

- Feature-based view organization
- Component views in `Components/` subdirectories
- Shared UI components in `UI/Components/`
- Custom navigation through `CustomNavigationLink`

### Import Guidelines

- Avoid complex import patterns like `@preconcurrency import`
- Don't use `#if canImport(UIKit)` patterns
- SwiftUI views don't need explicit imports for other views
- Keep imports minimal and standard

### Code Quality Standards

- Check for existing implementations before creating duplicates
- Use comprehensive comments in English or Turkish
- Follow SwiftUI naming conventions
- Implement proper error handling for SwiftData operations

### Live Activities Best Practices

- Always handle Live Activity failures gracefully
- Check availability before starting activities
- Use proper content state management
- Handle background app refresh limitations

## Project-Specific Patterns

### Timer Implementation

- Uses `Timer.publish()` for countdown
- Persists state through `TimerStateManager`
- Integrates with `NotificationManager` for background alerts
- Supports auto-start between sessions

### Task Management

- Hierarchical structure: Task → SubTask → Pomodoro counts
- Active task selection for timer integration
- Progress tracking with visual indicators
- Filter and search capabilities

### Settings Architecture

- Singleton `SettingsManager` with UserDefaults backing
- Environment object injection
- Live updates across app
- Widget configuration support

## Current Development Context

- Project is on `widget` branch
- Active development on widget functionality and subtask management
- MVP completed with Live Activities integration
- Focus on UI/UX improvements and task management features
