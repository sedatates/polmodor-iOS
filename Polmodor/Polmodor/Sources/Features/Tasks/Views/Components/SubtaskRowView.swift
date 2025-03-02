//
//  SubtaskProgressView.swift
//  Polmodor
//
//  Created by sedat ateş on 27.02.2025.
//

import Foundation
import SwiftData
import SwiftUI

#if os(iOS)
    import UIKit
#endif

// MARK: - Subtask Row View
struct SubtaskRowView: View {
    let subtask: PolmodorSubTask
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var timerViewModel: TimerViewModel

    // For animation and state tracking
    @State private var isCompleted: Bool
    @State private var showCompletionAlert = false

    init(subtask: PolmodorSubTask) {
        self.subtask = subtask
        // Initialize local state with the subtask's completion status
        _isCompleted = State(initialValue: subtask.completed)
    }

    // Computed property to check if this subtask is the active subtask
    private var isActiveSubtask: Bool {
        timerViewModel.activeSubtaskID == subtask.id
    }

    var body: some View {
        HStack {
            // Subtask title and progress
            VStack(alignment: .leading, spacing: 2) {
                Text(subtask.title)
                    .font(.subheadline)
                    .strikethrough(isCompleted)
                    .foregroundStyle(isCompleted ? .secondary : .primary)

                Text("\(subtask.pomodoro.completed)/\(subtask.pomodoro.total) pomodoros")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Current task toggle with improved styling
            Button(action: {
                if !isCompleted {
                    if isActiveSubtask {
                        // Clear the active subtask
                        timerViewModel.setActiveSubtask(nil as UUID?)

                        // Provide haptic feedback when clearing task
                        #if os(iOS)
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                        #endif
                    } else {
                        // Set this as the active subtask - this will automatically persist via TimerViewModel
                        timerViewModel.setActiveSubtask(subtask.id)

                        // Provide stronger haptic feedback when setting active task
                        #if os(iOS)
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                        #endif
                    }
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: isActiveSubtask ? "checkmark.circle.fill" : "circle")
                        .symbolRenderingMode(.hierarchical)
                    Text(isActiveSubtask ? "Active" : "Set Active")
                        .font(.caption.bold())
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isActiveSubtask ? Color.orange : Color.gray.opacity(0.2))
                )
                .foregroundStyle(isActiveSubtask ? .white : .primary)
            }
            .buttonStyle(.plain)
            .opacity(isCompleted ? 0.4 : 1.0)
            .disabled(isCompleted)
            // Highlight the active task button more prominently
            .shadow(
                color: isActiveSubtask ? Color.orange.opacity(0.4) : .clear, radius: 3, x: 0, y: 1)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !isCompleted {
                showCompletionAlert = true
            }
        }
        .alert("Subtask'ı tamamlıyor musunuz?", isPresented: $showCompletionAlert) {
            Button("İptal", role: .cancel) {}
            Button("Tamamla", role: .destructive) {
                completeSubtask()
            }
        } message: {
            Text("Bu işlem geri alınamaz. Subtask'ı tamamlamak istediğinize emin misiniz?")
        }
    }

    private func completeSubtask() {
        // If the task is completed, it should no longer be the active task
        if timerViewModel.activeSubtaskID == subtask.id {
            timerViewModel.setActiveSubtask(nil as UUID?)
        }

        // Update our local state for immediate UI feedback
        withAnimation(.easeInOut(duration: 0.2)) {
            isCompleted = true
        }

        // Update the model
        subtask.completed = true
        try? modelContext.save()

        // Provide subtle haptic feedback
        #if os(iOS)
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        #endif
    }
}

// MARK: - Preview
#Preview {
    // Mock setup for preview
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PolmodorTask.self, configurations: config)

    let timerViewModel = TimerViewModel()

    return VStack {
        SubtaskRowView(subtask: PolmodorTask.mockTasks[0].subTasks[0])
        SubtaskRowView(subtask: PolmodorTask.mockTasks[0].subTasks[1])
    }
    .padding()
    .modelContainer(container)
    .environmentObject(timerViewModel)
}
