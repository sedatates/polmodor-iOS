//
//  PolmodorTaskExpandedView.swift
//  Polmodor
//
//  Created by sedat ateş on 1.03.2025.
//

import Foundation
import SwiftData
import SwiftUI

struct PolmodorTaskExpandedView: View {
  let task: PolmodorTask
  let accentColor: Color
  @Binding var isExpanded: Bool
  @Binding var showAddSubtask: Bool
  @EnvironmentObject private var timerViewModel: TimerViewModel
  @State private var showTaskDetail = false

  var body: some View {
    VStack(spacing: 0) {
      if task.subTasks.isEmpty {
        // Empty state
        VStack(spacing: 16) {
          Image(systemName: "checklist")
            .font(.system(size: 36))
            .foregroundStyle(Color.secondary.opacity(0.3))
            .symbolRenderingMode(.hierarchical)
            .padding(.top, 16)

          Text("No subtasks yet")
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Color.secondary)

          Button(action: {
            print("🔧 Add Subtask button tapped - Empty state")
            showAddSubtask = true
          }) {
            HStack(spacing: 8) {
              Image(systemName: "plus.circle.fill")
                .font(.system(size: 16))
              Text("Add a subtask")
                .font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
              Capsule()
                .fill(accentColor.opacity(0.15))
            )
            .foregroundStyle(accentColor)
          }
          .buttonStyle(.plain)

          .padding(.bottom, 16)

          Button(action: {
            print("🔧 View Details button tapped - Empty state")
            showTaskDetail = true
          }) {
            Text("View Details")
              .font(.subheadline.weight(.medium))
              .foregroundStyle(.gray)
              .padding(.vertical, 8)
          }
          .buttonStyle(.plain)

        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
      } else {
        // Subtask list
        VStack(alignment: .leading, spacing: 12) {
          Text("Subtasks")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.top, 16)
            .padding(.horizontal, 16)

          ForEach(task.subTasks) { subtask in
            SubtaskRowView(subtask: subtask)
              .padding(.horizontal, 16)
              .padding(.vertical, 4)
              .background(
                RoundedRectangle(cornerRadius: 8)
                  .fill(
                    timerViewModel.activeSubtaskID == subtask.id
                      ? Color.orange.opacity(0.1) : Color.clear)
              )
              .animation(
                .easeInOut(duration: 0.2), value: timerViewModel.activeSubtaskID
              )
              .transition(.opacity.combined(with: .move(edge: .top)))
          }

          HStack {
            Button(action: {
              print("🔧 Add Subtask button tapped - With subtasks")
              showAddSubtask = true
            }) {
              HStack(spacing: 6) {
                Image(systemName: "plus.circle.fill")
                  .font(.system(size: 14))
                Text("Add a subtask")
                  .font(.subheadline.weight(.medium))
              }
              .foregroundStyle(accentColor)
              .padding(.vertical, 8)
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: {
              print("🔧 View Details button tapped - With subtasks")
              showTaskDetail = true
            }) {
              Text("View Details")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.gray)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
          }.padding(.horizontal, 16).padding(.bottom, 16)
        }
      }
    }
    .animation(
      .easeInOut(duration: 0.3).delay(isExpanded ? 0.1 : 0), value: isExpanded
    )
    .sheet(isPresented: $showTaskDetail) {
      NavigationStack {
        TaskDetailView(task: task)
          .navigationTitle("Task Details")
          .navigationBarTitleDisplayMode(.inline)
      }
      .presentationDetents([.large])
    }
  }
}

// MARK: - Previews
struct PolmodorTaskExpandedView_Previews: PreviewProvider {
  static var previews: some View {
    VStack(spacing: 20) {
      PolmodorTaskExpandedView(
        task: PolmodorTask.mockTasks[2],
        accentColor: .blue,
        isExpanded: .constant(true),
        showAddSubtask: .constant(false)
      )

      PolmodorTaskExpandedView(
        task: PolmodorTask.mockTasks[0],
        accentColor: .blue,
        isExpanded: .constant(true),
        showAddSubtask: .constant(false)
      )
    }
    .padding()
    .environmentObject(TimerViewModel())
  }
}
