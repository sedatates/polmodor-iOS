//
//  PolmodorTaskHeader.swift
//  Polmodor
//
//  Created by sedat ateş on 1.03.2025.
//

import Foundation
import SwiftUI
import UIKit

struct PolmodorTaskHeader: View {
  var task: PolmodorTask
  var accentColor: Color
  @Binding var isExpanded: Bool
  @Environment(\.modelContext) private var modelContext

  var body: some View {

    HStack(alignment: .center, spacing: 12) {
      // Task icon with category color
      ZStack {
        Circle()
          .fill(accentColor.opacity(0.15))
          .frame(width: 36, height: 36)

        Image(systemName: task.iconName)
          .font(.system(size: 16, weight: .medium))
          .foregroundStyle(accentColor)
          .symbolRenderingMode(.hierarchical)
      }

      // Task content
      VStack(alignment: .leading, spacing: 4) {
        // Title row
        Text(task.title)
          .font(.headline)
          .strikethrough(task.completed)
          .foregroundStyle(task.completed ? .secondary : .primary)
          .lineLimit(1)

        // Description if available
        if !task.taskDescription.isEmpty {
          Text(task.taskDescription)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(isExpanded ? 3 : 1)
            .animation(.easeInOut, value: isExpanded)
        }
      }

      Spacer()

      // Status indicators
      HStack(spacing: 8) {
        if task.completed {
          Button(action: {
            uncompleteTask()
          }) {
            Image(systemName: "checkmark.circle.fill")
              .foregroundStyle(.green)
              .symbolRenderingMode(.hierarchical)
              .font(.system(size: 18))
          }
          .buttonStyle(.plain)
        } else {
          Button(action: {
            completeTask()
          }) {
            Image(systemName: "circle")
              .foregroundStyle(.secondary)
              .symbolRenderingMode(.hierarchical)
              .font(.system(size: 18))
          }
          .buttonStyle(.plain)

          if task.isTimerRunning {
            Image(systemName: "timer.circle.fill")
              .foregroundStyle(.orange)
              .symbolRenderingMode(.hierarchical)
              .font(.system(size: 18))
              .symbolEffect(.pulse, options: .repeating)
          }
        }

        // Dropdown indicator
        ZStack {
          Circle()
            .fill(Color.secondary.opacity(0.15))
            .frame(width: 28, height: 28)

          Image(systemName: "chevron.down")
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.secondary)
            .rotationEffect(isExpanded ? .degrees(180) : .degrees(0))
        }
        .contentShape(Circle())
        .onTapGesture {
          withAnimation(
            .spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.3)
          ) {
            isExpanded.toggle()
          }
        }
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 16)
  }

  private func completeTask() {
    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
      task.completed = true
      task.completedAt = Date()
      task.status = .completed

      // Haptic feedback
      let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
      impactFeedback.impactOccurred()
    }
  }

  private func uncompleteTask() {
    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
      task.completed = false
      task.completedAt = nil
      task.status = .todo

      // Haptic feedback
      let impactFeedback = UIImpactFeedbackGenerator(style: .light)
      impactFeedback.impactOccurred()
    }
  }
}

struct PolmodorTaskHeader_Previews: PreviewProvider {
  static var previews: some View {
    PolmodorTaskHeader(
      task: PolmodorTask.mockTasks.first!,
      accentColor: Color.accentColor,
      isExpanded: .constant(false)
    )
    .previewLayout(.sizeThatFits)
    .padding()
  }
}
