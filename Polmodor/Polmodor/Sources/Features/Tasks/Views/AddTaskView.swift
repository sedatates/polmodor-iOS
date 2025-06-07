import SwiftData
import SwiftUI

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskCategory.name) private var categories: [TaskCategory]
    
    @State private var title = ""
    @State private var taskDescription = ""
    @State private var selectedCategory: TaskCategory?
    @State private var selectedPriority = TaskPriority.medium
    @State private var dueDate = Date().addingTimeInterval(86400)
    @State private var timeRemaining: Double = 25 * 60  // 25 minutes
    @State private var iconName = "circle.fill"
    
    private let icons = [
        "circle.fill",
        "star.fill",
        "flag.fill",
        "bell.fill",
        "calendar",
        "doc.fill",
        "pencil",
        "hammer.fill",
        "wrench.fill",
        "link",
        "person.fill",
        "house.fill",
        "cart.fill",
        "gift.fill",
        "airplane",
        "car.fill",
        "leaf.fill",
        "gamecontroller.fill",
    ]
    
    var body: some View {
        Form {
            Section("Task Details") {
                TextField("Title", text: $title)
                TextField("Description", text: $taskDescription, axis: .vertical)
                    .lineLimit(3...6)
            }
            
            Section("Icon") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(icons, id: \.self) { icon in
                            Button {
                                iconName = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundStyle(iconName == icon ? .blue : .gray)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        Circle()
                                            .fill(iconName == icon ? .blue.opacity(0.2) : .clear)
                                    )
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            
            Section("Category") {
                Picker("Category", selection: $selectedCategory) {
                    Text("None")
                        .tag(TaskCategory?.none)
                    ForEach(categories) { category in
                        Text(category.name)
                            .tag(TaskCategory?.some(category))
                    }
                }
            }
            
            Section("Priority") {
                Picker("Priority", selection: $selectedPriority) {
                    ForEach(TaskPriority.allCases, id: \.self) { priority in
                        Label(priority.rawValue.capitalized, systemImage: priority.iconName)
                            .tag(priority)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Section("Time") {
                DatePicker("Due Date", selection: $dueDate, in: Date()...)
                
                Stepper(
                    "Time Required: \(Int(timeRemaining / 60)) minutes",
                    value: $timeRemaining,
                    in: 5 * 60...120 * 60,
                    step: 5 * 60
                )
            }
        }
        .navigationTitle("New Task")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Add") {
                    addTask()
                    dismiss()
                }
                .disabled(title.isEmpty)
            }
        }
    }
    
    private func addTask() {
        let task = PolmodorTask(
            title: title,
            taskDescription: taskDescription,
            iconName: iconName,
            category: selectedCategory ?? categories.first!,
            priority: selectedPriority,
            timeRemaining: timeRemaining,
            dueDate: dueDate
        )
        
        modelContext.insert(task)
    }
}

