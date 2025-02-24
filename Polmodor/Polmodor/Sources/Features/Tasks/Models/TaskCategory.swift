import SwiftUI

enum TaskCategory: String, Codable, CaseIterable {
    case all
    case work
    case study
    case personal

    var color: Color {
        switch self {
        case .all:
            return .gray
        case .work:
            return .blue
        case .study:
            return .green
        case .personal:
            return .orange
        }
    }

    var iconName: String {
        switch self {
        case .all:
            return "list.bullet"
        case .work:
            return "briefcase.fill"
        case .study:
            return "book.fill"
        case .personal:
            return "heart.fill"
        }
    }
} 