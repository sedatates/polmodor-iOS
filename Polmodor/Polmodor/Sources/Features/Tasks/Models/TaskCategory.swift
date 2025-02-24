import SwiftData
import SwiftUI

@Model
final class TaskCategory: Identifiable {
    var id: UUID
    var name: String
    var iconName: String
    
    // Color için bileşenlerini saklama
    var colorHex: String
    


    init(id: UUID = UUID(), name: String, iconName: String, color: Color) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorHex = color.toHex() ?? "#0000FF" // varsayılan mavi
    }
    
    // Color için computed property
    var color: Color {
        get {
            Color(hex: colorHex) 
        }
        set {
            colorHex = newValue.toHex() ?? "#0000FF"
        }
    }
    
    static var all: TaskCategory {
        TaskCategory(name: "All", iconName: "list.bullet", color: Color(hex: "#FFA500"))
    }

    static var defaultCategories: [TaskCategory] {
        [
            TaskCategory(name: "Work", iconName: "briefcase.fill", color: .blue),
            TaskCategory(name: "Study", iconName: "book.fill", color: .green),
            TaskCategory(name: "Personal", iconName: "heart.fill", color: .orange),
        ]
    }
}
