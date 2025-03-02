//
//  CurrentTaskView.swift
//  Polmodor
//
//  Created by sedat ateş on 3.03.2025.
//

import Foundation
import SwiftData
import SwiftUI

/// A view that displays the currently active subtask in the timer
struct CurrentTaskView: View {
  @EnvironmentObject var timerViewModel: TimerViewModel
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.modelContext) private var modelContext

  @State private var activeSubtask: PolmodorSubTask?
  @State private var parentTask: PolmodorTask?

  private var backgroundColor: Color {
    colorScheme == .dark ? Color(white: 0.18) : Color(white: 0.97)
  }

  var body: some View {
    Group {
      if let subtask = activeSubtask, let task = parentTask {
        VStack(spacing: 0) {
          HStack(spacing: 12) {
            // Task icon
            ZStack {
              Circle()
                .fill(task.category?.color.opacity(0.15) ?? Color.blue.opacity(0.15))
                .frame(width: 40, height: 40)

              Image(systemName: task.iconName)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(task.category?.color ?? Color.blue)
                .symbolRenderingMode(.hierarchical)
            }

            // Task details
            VStack(alignment: .leading, spacing: 4) {
              Text("You are working on:")
                .font(.caption)
                .foregroundStyle(.secondary)

              Text(subtask.title)
                .font(.headline)
                .lineLimit(1)

              Text("from \"\(task.title)\"")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            Spacer()

            // Pomodoro progress
            VStack(alignment: .trailing, spacing: 2) {
              Text("\(subtask.pomodoro.completed)/\(subtask.pomodoro.total)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(timerViewModel.currentStateColor)

              Text("pomodoros")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
          .padding(16)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 16)
          )
          .overlay(
            RoundedRectangle(cornerRadius: 16)
              .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
          )

          // Clear button
          Button(action: {
            withAnimation(.spring(response: 0.3)) {
              timerViewModel.setActiveSubtask(nil)
            }
          }) {
            Text("Clear active task")
              .font(.caption.weight(.medium))
              .foregroundStyle(.secondary)
              .padding(.vertical, 8)
          }
          .padding(.top, 4)
        }
        .padding(.horizontal)
        .transition(.move(edge: .top).combined(with: .opacity))
      } else {
        // Empty placeholder when no task is active
        EmptyView()
      }
    }
    .onChange(of: timerViewModel.activeSubtaskID) { _, newID in
      loadActiveSubtask(id: newID)
    }
    .onAppear {
      loadActiveSubtask(id: timerViewModel.activeSubtaskID)
    }
  }

  // Load the subtask and its parent task from the model context
  private func loadActiveSubtask(id: UUID?) {
    guard let subtaskID = id else {
      withAnimation(.spring(response: 0.3)) {
        activeSubtask = nil
        parentTask = nil
      }
      return
    }

    do {
      // Fetch the subtask
      let subtaskDescriptor = FetchDescriptor<PolmodorSubTask>(
        predicate: #Predicate { subtask in
          subtask.id == subtaskID
        }
      )

      let results = try modelContext.fetch(subtaskDescriptor)
      guard let subtask = results.first else {
        withAnimation(.spring(response: 0.3)) {
          activeSubtask = nil
          parentTask = nil
        }
        return
      }

      // Find the parent task
      let taskDescriptor = FetchDescriptor<PolmodorTask>(
        predicate: #Predicate { task in
          task.subTasks.contains(where: { $0.id == subtaskID })
        }
      )

      let taskResults = try modelContext.fetch(taskDescriptor)
      let foundParentTask = taskResults.first

      // Update state with animations
      withAnimation(.spring(response: 0.3)) {
        self.activeSubtask = subtask
        self.parentTask = foundParentTask
      }
    } catch {
      print("Error fetching active subtask: \(error)")
      withAnimation(.spring(response: 0.3)) {
        activeSubtask = nil
        parentTask = nil
      }
    }
  }
}

// MARK: - Preview
#Preview {
  let config = ModelConfiguration(isStoredInMemoryOnly: true)

  do {
    let container = try ModelContainer(for: PolmodorTask.self, configurations: config)
    let task = PolmodorTask.mockTasks[0]
    let subtask = task.subTasks[0]
    container.mainContext.insert(task)

    let timerViewModel = TimerViewModel()
    timerViewModel.setActiveSubtask(subtask.id)

    return VStack {
      CurrentTaskView()
        .environmentObject(timerViewModel)
        .modelContainer(container)
    }
    .padding(.vertical)
    .background(Color.black.opacity(0.05))
  } catch {
    return Text("Failed to create preview: \(error.localizedDescription)")
  }
}
