import SwiftUI

enum TaskPriority: String, Codable, CaseIterable {
    case low
    case medium
    case high

    var color: Color {
        switch self {
        case .low:
            return .green
        case .medium:
            return .orange
        case .high:
            return .red
        }
    }
} 
