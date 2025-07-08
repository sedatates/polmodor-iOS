import Foundation
import SwiftUI

enum TaskPriority: String, Codable, CaseIterable, Hashable {
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

    var iconName: String {
        switch self {
        case .low:
            return "arrow.down.circle.fill"
        case .medium:
            return "arrow.up.circle.fill"
        case .high:
            return "arrow.up.circle.fill"
        }
    }
}
