# SwiftUI Timer Animation Development Guide

## Table of Contents

- [Model Configuration](#model-configuration)
- [View Hierarchy](#view-hierarchy)
- [Animation Specifications](#animation-specifications)
- [Timer Logic](#timer-logic)
- [Interaction Guidelines](#interaction-guidelines)
- [Accessibility](#accessibility)
- [Memory Management](#memory-management)
- [Testing Guidelines](#testing-guidelines)
- [Performance Guidelines](#performance-guidelines)

## Model Configuration

### PomodoroState

The state enum must conform to `CaseIterable` and `Equatable` protocols, defining the following states:

- Work: 25 minutes
- Short Break: 5 minutes
- Long Break: 15 minutes

### Color System

#### Work Mode Colors

- Start: `#FF6B6B`
- Middle: `#FA5252`
- End: `#F03E3E`

#### Short Break Colors

- Start: `#4DABF7`
- Middle: `#339AF0`
- End: `#228BE6`

#### Long Break Colors

- Start: `#51CF66`
- Middle: `#40C057`
- End: `#2F9E44`

## View Hierarchy

### Container View Requirements

- Use `ZStack` for overlay structure
- Implement `GeometryReader` for responsive design
- Support dark/light mode via `@Environment`
- Maintain 1:1 aspect ratio using `.aspectRatio(1, contentMode: .fit)`

### Shape Requirements

- Implement `Shape` protocol
- Define progress as `AnimatableData`
- Use trigonometric calculations for path drawing
- Set initial angle to -90 degrees (12 o'clock position)

### Gradient Layer

- Implement using `LinearGradient`
- Use `TimerQuadrantShape` as mask
- Configure gradient stops:
  - 0.0: Start color (full opacity)
  - 0.5: Middle color (progress-based opacity)
  - 1.0: End color (progress-based opacity)

## Animation Specifications

### Progress Animation

```swift
withAnimation(.linear(duration: remainingTime)) {
    progress = 1.0
}
```

### State Transition Animation

```swift
withAnimation(.spring(
    response: 0.3,
    dampingFraction: 0.6,
    blendDuration: 0.1
)) {
    // State transition logic
}
```

### Rotation Animation

```swift
rotationEffect(.degrees(-360 * progress))
    .animation(.linear(duration: 0.1), value: progress)
```

## Timer Logic

### Required Published Properties

```swift
@Published var state: PomodoroState
@Published var progress: Double
@Published var timeRemaining: TimeInterval
@Published var isActive: Bool
```

### Timer Management

- Use Combine framework for timer implementation
- Maintain 60 Hz update frequency
- Implement weak references for timer
- Support background mode operation

### Progress Calculation

```swift
progress = 1 - (timeRemaining / totalDuration)
progress = min(max(progress, 0), 1)
```

## Interaction Guidelines

### Gesture Support

- Single tap: Toggle play/pause
- Double tap: Reset timer
- Long press: Switch to next state

### Haptic Feedback

- Timer start: Medium impact
- Timer completion: Rigid impact
- State change: Light impact

## Accessibility

### VoiceOver Integration

```swift
.accessibilityLabel("Timer \(timeString)")
.accessibilityValue("\(stateTitle)")
.accessibilityHint("Double tap to \(isRunning ? "pause" : "start")")
```

### Reduced Motion Support

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

// When reduced motion is active:
- Disable rotation animations
- Use instant color transitions
- Remove spring effects
```

## Memory Management

### Cleanup Requirements

- Invalidate timer on view cleanup
- Cancel all Combine subscriptions
- Avoid strong reference cycles

### State Management

- Handle state transitions in ViewModel
- Use state machine for complex state logic
- Manage side effects properly

## Testing Guidelines

### Required Test Coverage

- 100% ViewModel logic coverage
- Timer calculations
- State transitions
- Color interpolation

### Mock Objects

```swift
protocol MockTimer {
    // Timer simulation methods
}

protocol TimeProvider {
    // Time management methods
}
```

## Performance Guidelines

### Render Optimization

- Minimize unnecessary view updates
- Move heavy calculations to background
- Cache shape and gradient calculations
- Minimize draw calls

### Memory Optimization

- Prevent memory leaks
- Implement lazy loading for large data
- Use caching mechanism
- Regular memory graph inspection

## Preview Support

### Preview Configuration

```swift
struct TimerView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TimerView(viewModel: TimerViewModel())
                .previewDisplayName("Default")

            TimerView(viewModel: TimerViewModel())
                .environment(\.colorScheme, .dark)
                .previewDisplayName("Dark Mode")

            TimerView(viewModel: TimerViewModel())
                .environment(\.sizeCategory, .accessibilityLarge)
                .previewDisplayName("Large Text")
        }
    }
}
```

## Implementation Example

### Basic Timer Shape

```swift
struct TimerQuadrantShape: Shape {
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        path.move(to: center)
        path.addLine(to: CGPoint(x: center.x, y: center.y - radius))
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(-90),
            endAngle: .degrees(-90 + (360 * progress)),
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}
```

## Best Practices

### Code Organization

- Follow MVVM architecture
- Use proper encapsulation
- Implement clean code principles
- Maintain clear documentation

### Error Handling

- Implement proper error handling for timer operations
- Handle state transition edge cases
- Provide user feedback for errors
- Log important events for debugging

### Optimization

- Use SwiftUI's built-in optimization features
- Implement proper view identity management
- Use appropriate property wrappers
- Monitor performance metrics

## Notes

- All color values should be defined in asset catalog
- Support both portrait and landscape orientations
- Implement proper state restoration
- Follow Apple's Human Interface Guidelines

## Resources

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines)
- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
