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
  @State private var estimatedPomodoros: Int = 1
  @State private var iconName = "circle.fill"
  @State private var showIconPicker = false

  @FocusState private var titleFocused: Bool
  @FocusState private var descriptionFocused: Bool

  // Category creation states
  @State private var showAddCategory = false
  @State private var newCategoryName = ""
  @State private var newCategoryColor = Color.blue
  @State private var newCategoryIcon = "folder.fill"

  private let icons = [
    "circle.fill", "star.fill", "flag.fill", "bell.fill", "calendar",
    "doc.fill", "pencil", "hammer.fill", "wrench.fill", "link",
    "person.fill", "house.fill", "cart.fill", "gift.fill", "airplane",
    "car.fill", "leaf.fill", "gamecontroller.fill", "book.fill", "heart.fill",
    "lightbulb.fill", "brain.head.profile", "target", "trophy.fill",
  ]

  var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        taskDetailsSection
        iconSelectionSection
        categorySection
        prioritySection
        dueDateSection
        estimatedTimeSection
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 100)
    }
    .navigationTitle("New Task")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Cancel") {
          dismiss()
        }
        .foregroundColor(.secondary)
      }

      ToolbarItem(placement: .confirmationAction) {
        Button("Create") {
          createTask()
        }
        .fontWeight(.semibold)
        .disabled(title.isEmpty)
      }
    }
    .onAppear {
      titleFocused = true
    }
    .sheet(isPresented: $showAddCategory) {
      AddCategorySheet(
        categoryName: $newCategoryName,
        categoryColor: $newCategoryColor,
        categoryIcon: $newCategoryIcon,
        onSave: { name, color, icon in
          createCategory(name: name, color: color, icon: icon)
        }
      )
    }
  }

  private var headerSection: some View {
    VStack(spacing: 12) {
      Image(systemName: iconName)
        .font(.system(size: 60))
        .foregroundColor(selectedCategory?.color ?? .blue)
        .frame(width: 100, height: 100)
        .background(
          Circle()
            .fill((selectedCategory?.color ?? .blue).opacity(0.1))
        )
        .onTapGesture {
          showIconPicker = true
        }

      Text("What would you like to accomplish?")
        .font(.headline)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
    }
    .padding(.top, 20)
  }

  private var taskDetailsSection: some View {
    VStack(spacing: 20) {
      ModernTextField(
        title: "Task Title",
        text: $title,
        placeholder: "Enter task title...",
        icon: "text.cursor"
      )
      .focused($titleFocused)

      ModernTextEditor(
        title: "Description",
        text: $taskDescription,
        placeholder: "Add a description (optional)...",
        icon: "text.alignleft"
      )
      .focused($descriptionFocused)
    }
  }

  private var iconSelectionSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Image(systemName: "app.badge")
          .font(.title3)
          .foregroundColor(.blue)

        Text("Icon")
          .font(.headline.weight(.semibold))

        Spacer()

        Button("Change") {
          showIconPicker = true
        }
        .font(.subheadline.weight(.medium))
        .foregroundColor(.blue)
      }

      if showIconPicker {
        IconPickerGrid(selectedIcon: $iconName, icons: icons) {
          withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showIconPicker = false
          }
        }
      }
    }
    .padding(20)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color(.systemGray6).opacity(0.5))
    )
  }

  private var categorySection: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Image(systemName: "folder")
          .font(.title3)
          .foregroundColor(.orange)

        Text("Category")
          .font(.headline.weight(.semibold))

        Spacer()
      }

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 12) {
          // No Category Option
          CategoryChip(
            title: "None",
            color: .gray,
            isSelected: selectedCategory == nil
          ) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
              selectedCategory = nil
            }
          }

          ForEach(categories, id: \.id) { category in
            CategoryChip(
              title: category.name,
              color: category.color,
              isSelected: selectedCategory?.id == category.id
            ) {
              withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedCategory = category
              }
            }
          }

          // Add new category button
          Button {
            showAddCategory = true
          } label: {
            HStack(spacing: 8) {
              Image(systemName: "plus.circle.fill")
                .font(.caption)

              Text("Add Category")
                .font(.subheadline.weight(.medium))
            }
            .foregroundColor(.blue)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
              RoundedRectangle(cornerRadius: 20)
                .fill(Color.blue.opacity(0.1))
            )
            .overlay(
              RoundedRectangle(cornerRadius: 20)
                .stroke(Color.blue, lineWidth: 1)
            )
          }
        }
        .padding(.horizontal, 4)
      }
    }
    .padding(20)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color(.systemGray6).opacity(0.5))
    )
  }

  private var prioritySection: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Image(systemName: "exclamationmark.triangle")
          .font(.title3)
          .foregroundColor(.red)

        Text("Priority")
          .font(.headline.weight(.semibold))

        Spacer()
      }

      HStack(spacing: 12) {
        ForEach(TaskPriority.allCases, id: \.self) { priority in
          PriorityChip(
            priority: priority,
            isSelected: selectedPriority == priority
          ) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
              selectedPriority = priority
            }
          }
        }
      }
    }
    .padding(20)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color(.systemGray6).opacity(0.5))
    )
  }

  private var dueDateSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Image(systemName: "calendar")
          .font(.title3)
          .foregroundColor(.purple)

        Text("Due Date")
          .font(.headline.weight(.semibold))

        Spacer()

        Text(dueDate.formatted(date: .abbreviated, time: .omitted))
          .font(.subheadline)
          .foregroundColor(.secondary)
      }

      DatePicker(
        "Select due date",
        selection: $dueDate,
        in: Date()...,
        displayedComponents: [.date]
      )
      .datePickerStyle(.graphical)
    }
    .padding(20)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color(.systemGray6).opacity(0.5))
    )
  }

  private var estimatedTimeSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Image(systemName: "timer")
          .font(.title3)
          .foregroundColor(.red)

        Text("Estimated Pomodoros")
          .font(.headline.weight(.semibold))

        Spacer()

        Text("\(estimatedPomodoros)")
          .font(.title2.weight(.bold))
          .foregroundColor(.red)
      }

      VStack(spacing: 12) {
        HStack {
          Text("1")
            .font(.caption)
            .foregroundColor(.secondary)

          Slider(
            value: Binding(
              get: { Double(estimatedPomodoros) },
              set: { estimatedPomodoros = Int($0) }
            ),
            in: 1...20,
            step: 1
          )
          .tint(.red)

          Text("20")
            .font(.caption)
            .foregroundColor(.secondary)
        }

        Text("≈ \(estimatedPomodoros * 25) minutes")
          .font(.caption)
          .foregroundColor(.secondary)
      }
    }
    .padding(20)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color(.systemGray6).opacity(0.5))
    )
  }

  private func createTask() {
    let task = PolmodorTask(
      title: title,
      taskDescription: taskDescription,
      iconName: iconName,
      category: selectedCategory,
      priority: selectedPriority,
      timeRemaining: Double(estimatedPomodoros * 25 * 60),  // Convert to seconds
      dueDate: dueDate
    )

    modelContext.insert(task)
    dismiss()
  }

  private func createCategory(name: String, color: Color, icon: String) {
    let category = TaskCategory(
      name: name,
      iconName: icon,
      color: color
    )

    modelContext.insert(category)

    // Auto-select the newly created category
    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
      selectedCategory = category
    }

    // Reset form
    newCategoryName = ""
    newCategoryColor = .blue
    newCategoryIcon = "folder.fill"
    showAddCategory = false
  }
}

struct ModernTextField: View {
  let title: String
  @Binding var text: String
  let placeholder: String
  let icon: String

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Image(systemName: icon)
          .font(.title3)
          .foregroundColor(.blue)

        Text(title)
          .font(.headline.weight(.semibold))

        Spacer()
      }

      TextField(placeholder, text: $text)
        .textFieldStyle(.plain)
        .font(.body)
        .padding(16)
        .background(
          RoundedRectangle(cornerRadius: 12)
            .fill(Color(.systemBackground))
            .overlay(
              RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
            )
        )
    }
  }
}

struct ModernTextEditor: View {
  let title: String
  @Binding var text: String
  let placeholder: String
  let icon: String

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Image(systemName: icon)
          .font(.title3)
          .foregroundColor(.blue)

        Text(title)
          .font(.headline.weight(.semibold))

        Spacer()
      }

      ZStack(alignment: .topLeading) {
        if text.isEmpty {
          Text(placeholder)
            .foregroundColor(.secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .allowsHitTesting(false)
        }

        TextEditor(text: $text)
          .font(.body)
          .padding(12)
          .frame(minHeight: 100)
          .scrollContentBackground(.hidden)
      }
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(Color(.systemBackground))
          .overlay(
            RoundedRectangle(cornerRadius: 12)
              .stroke(Color(.systemGray4), lineWidth: 1)
          )
      )
    }
  }
}

struct IconPickerGrid: View {
  @Binding var selectedIcon: String
  let icons: [String]
  let onSelection: () -> Void

  var body: some View {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6), spacing: 12)
    {
      ForEach(icons, id: \.self) { icon in
        Button {
          selectedIcon = icon
          onSelection()
        } label: {
          Image(systemName: icon)
            .font(.title2)
            .foregroundColor(selectedIcon == icon ? .white : .primary)
            .frame(width: 44, height: 44)
            .background(
              RoundedRectangle(cornerRadius: 12)
                .fill(selectedIcon == icon ? Color.blue : Color(.systemGray5))
            )
        }
        .scaleEffect(selectedIcon == icon ? 1.1 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: selectedIcon)
      }
    }
    .transition(.scale.combined(with: .opacity))
  }
}

struct CategoryChip: View {
  let title: String
  let color: Color
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 8) {
        Circle()
          .fill(color)
          .frame(width: 12, height: 12)

        Text(title)
          .font(.subheadline.weight(.medium))
      }
      .foregroundColor(isSelected ? .white : .primary)
      .padding(.horizontal, 16)
      .padding(.vertical, 10)
      .background(
        RoundedRectangle(cornerRadius: 20)
          .fill(isSelected ? color : Color(.systemGray5))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 20)
          .stroke(color, lineWidth: isSelected ? 0 : 1)
      )
    }
    .scaleEffect(isSelected ? 1.05 : 1.0)
    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
  }
}

struct PriorityChip: View {
  let priority: TaskPriority
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 8) {
        Image(systemName: priority.iconName)
          .font(.caption)

        Text(priority.rawValue.capitalized)
          .font(.subheadline.weight(.medium))
      }
      .foregroundColor(isSelected ? .white : priority.color)
      .padding(.horizontal, 16)
      .padding(.vertical, 10)
      .background(
        RoundedRectangle(cornerRadius: 20)
          .fill(isSelected ? priority.color : priority.color.opacity(0.1))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 20)
          .stroke(priority.color, lineWidth: isSelected ? 0 : 1)
      )
    }
    .scaleEffect(isSelected ? 1.05 : 1.0)
    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
  }
}

struct AddCategorySheet: View {
  @Binding var categoryName: String
  @Binding var categoryColor: Color
  @Binding var categoryIcon: String
  let onSave: (String, Color, String) -> Void

  @Environment(\.dismiss) private var dismiss
  @FocusState private var nameFieldFocused: Bool

  private let categoryIcons = [
    "folder.fill", "briefcase.fill", "house.fill", "car.fill",
    "heart.fill", "star.fill", "book.fill", "gamecontroller.fill",
    "music.note", "paintbrush.fill", "camera.fill", "phone.fill",
    "envelope.fill", "gift.fill", "cart.fill", "creditcard.fill",
    "leaf.fill", "globe", "airplane", "bicycle",
  ]

  private let categoryColors: [Color] = [
    .blue, .red, .green, .orange, .purple, .pink,
    .yellow, .teal, .indigo, .cyan, .mint, .brown,
  ]

  var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: 24) {
          headerSection
          nameSection
          iconSection
          colorSection
        }
        .padding(20)
        .padding(.bottom, 100)
      }
      .navigationTitle("New Category")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
          .foregroundColor(.secondary)
        }

        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            onSave(categoryName, categoryColor, categoryIcon)
          }
          .fontWeight(.semibold)
          .disabled(categoryName.isEmpty)
        }
      }
      .onAppear {
        nameFieldFocused = true
      }
    }
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
  }

  private var headerSection: some View {
    VStack(spacing: 12) {
      Image(systemName: categoryIcon)
        .font(.system(size: 60))
        .foregroundColor(categoryColor)
        .frame(width: 100, height: 100)
        .background(
          Circle()
            .fill(categoryColor.opacity(0.1))
        )

      Text("Create a new category")
        .font(.headline)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
    }
    .padding(.top, 20)
  }

  private var nameSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Image(systemName: "textformat")
          .font(.title3)
          .foregroundColor(.blue)

        Text("Category Name")
          .font(.headline.weight(.semibold))

        Spacer()
      }

      TextField("Enter category name...", text: $categoryName)
        .textFieldStyle(.plain)
        .font(.body)
        .padding(16)
        .background(
          RoundedRectangle(cornerRadius: 12)
            .fill(Color(.systemBackground))
            .overlay(
              RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
            )
        )
        .focused($nameFieldFocused)
    }
  }

  private var iconSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Image(systemName: "app.badge")
          .font(.title3)
          .foregroundColor(.orange)

        Text("Icon")
          .font(.headline.weight(.semibold))

        Spacer()
      }

      LazyVGrid(
        columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5), spacing: 12
      ) {
        ForEach(categoryIcons, id: \.self) { icon in
          Button {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
              categoryIcon = icon
            }
          } label: {
            Image(systemName: icon)
              .font(.title2)
              .foregroundColor(categoryIcon == icon ? .white : categoryColor)
              .frame(width: 50, height: 50)
              .background(
                RoundedRectangle(cornerRadius: 12)
                  .fill(categoryIcon == icon ? categoryColor : categoryColor.opacity(0.1))
              )
          }
          .scaleEffect(categoryIcon == icon ? 1.1 : 1.0)
          .animation(.spring(response: 0.2, dampingFraction: 0.7), value: categoryIcon)
        }
      }
    }
    .padding(20)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color(.systemGray6).opacity(0.5))
    )
  }

  private var colorSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Image(systemName: "paintpalette")
          .font(.title3)
          .foregroundColor(.purple)

        Text("Color")
          .font(.headline.weight(.semibold))

        Spacer()
      }

      LazyVGrid(
        columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6), spacing: 12
      ) {
        ForEach(categoryColors, id: \.self) { color in
          Button {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
              categoryColor = color
            }
          } label: {
            Circle()
              .fill(color)
              .frame(width: 44, height: 44)
              .overlay(
                Circle()
                  .stroke(.white, lineWidth: 3)
                  .opacity(categoryColor == color ? 1 : 0)
              )
              .overlay(
                Circle()
                  .stroke(Color(.systemGray4), lineWidth: 1)
                  .opacity(categoryColor == color ? 0 : 1)
              )
          }
          .scaleEffect(categoryColor == color ? 1.2 : 1.0)
          .animation(.spring(response: 0.2, dampingFraction: 0.7), value: categoryColor)
        }
      }
    }
    .padding(20)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color(.systemGray6).opacity(0.5))
    )
  }
}

#Preview {
  AddTaskView()
    .modelContainer(ModelContainerSetup.setupModelContainer())
}
