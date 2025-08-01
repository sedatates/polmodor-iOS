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

    var body: some View {
        Group {
            if let subtask = activeSubtask, let task = parentTask {
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        // Task icon
                        taskIcon(for: task)

                        // Task details
                        taskDetails(subtask: subtask, task: task)

                        Spacer()

                        // Pomodoro progress
                        pomodoroProgress(for: subtask)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
                    )

                    // Clear button
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            timerViewModel.activeSubtaskID = nil
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                                .imageScale(.small)

                            Text("Clear task")
                                .font(.caption.weight(.medium))
                        }
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial.opacity(0.7))
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
                        )
                    }
                    .padding(.top, 12)
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
            // Ensure we load the active subtask when the view appears
            loadActiveSubtask(id: timerViewModel.activeSubtaskID)
        }
        // Add another observation to refresh when app becomes active
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // Reload the active subtask when returning to foreground
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

    // MARK: - Helper Views

    @ViewBuilder
    private func taskIcon(for task: PolmodorTask) -> some View {
        ZStack {
            Circle()
                .fill(task.category?.color.opacity(0.15) ?? Color.blue.opacity(0.15))
                .frame(width: 40, height: 40)

            Image(systemName: task.iconName)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(task.category?.color ?? Color.blue)
                .symbolRenderingMode(.hierarchical)
        }
    }

    @ViewBuilder
    private func taskDetails(subtask: PolmodorSubTask, task: PolmodorTask) -> some View {
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
    }

    @ViewBuilder
    private func pomodoroProgress(for subtask: PolmodorSubTask) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("\(subtask.pomodoro.completed)/\(subtask.pomodoro.total)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(timerViewModel.currentStateColor)

            Text("pomodoros")
                .font(.caption)
                .foregroundStyle(.secondary)
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
        timerViewModel.activeSubtaskID = subtask.id

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
