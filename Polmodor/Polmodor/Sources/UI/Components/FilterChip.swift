import SwiftUI

/// A customizable filter chip component that displays a count badge.
/// Used for filtering tasks by status, category, or other criteria.
struct FilterChip: View {
  let title: String
  let iconName: String
  let color: Color
  let isSelected: Bool
  let action: () -> Void
  var count: Int? = nil

  var body: some View {
    Button(action: action) {
      HStack(spacing: 6) {
        Image(systemName: iconName)
          .font(.system(size: 12, weight: .semibold))
          .symbolRenderingMode(.hierarchical)

        Text(title)
          .font(.system(size: 14, weight: isSelected ? .semibold : .medium))

        if let count = count, count > 0 {
          Text("\(count)")
            .font(.system(size: 12, weight: .semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
              Capsule()
                .fill(isSelected ? color : Color.secondary.opacity(0.3))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(
        Capsule()
          .fill(isSelected ? color.opacity(0.2) : Color.secondary.opacity(0.1))
      )
      .foregroundColor(isSelected ? color : .primary)
      .overlay(
        Capsule()
          .strokeBorder(isSelected ? color : Color.clear, lineWidth: 1)
      )
      .shadow(color: isSelected ? color.opacity(0.3) : .clear, radius: 3, x: 0, y: 1)
    }
    .buttonStyle(PlainButtonStyle())
    .contentShape(Capsule())
  }
}

#Preview {
  VStack {
    HStack {
      FilterChip(
        title: "Work",
        iconName: "briefcase.fill",
        color: .blue,
        isSelected: true,
        action: {},
        count: 5
      )

      FilterChip(
        title: "Personal",
        iconName: "person.fill",
        color: .green,
        isSelected: false,
        action: {},
        count: 3
      )
    }

    HStack {
      FilterChip(
        title: "To Do",
        iconName: "circle",
        color: .gray,
        isSelected: true,
        action: {},
        count: 8
      )

      FilterChip(
        title: "Completed",
        iconName: "checkmark.circle.fill",
        color: .green,
        isSelected: false,
        action: {},
        count: 0
      )
    }
  }
  .padding()
  .previewLayout(.sizeThatFits)
}
