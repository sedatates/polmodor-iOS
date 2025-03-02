//
//  SubtaskAdd.swift
//  Polmodor
//
//  Created by sedat ateş on 27.02.2025.
//

import Foundation
import SwiftData
import SwiftUI

struct SubTaskAddView: View {
    @Bindable var task: PolmodorTask
    @State private var subtaskTitle = ""
    @State private var pomodoroCount = 1
    @State private var showWarning = false
    @State private var shouldScrollToBottom = false

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.themeManager) private var themeManager

    private var backgroundColor: Color {
        themeManager.isDarkMode ? Color(white: 0.15) : Color.white
    }

    private var accentColor: Color {
        task.category?.color ?? .blue
    }

    // Validate if we should show a warning
    private var shouldShowWarning: Bool {
        pomodoroCount > 4
    }

    // Maksimum pomodoro sayısı
    private let maxPomodoroCount = 10

    var body: some View {
        NavigationStack {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(spacing: 20) {
                        // Task info card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Task")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)

                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(accentColor.opacity(0.15))
                                        .frame(width: 36, height: 36)

                                    Image(systemName: task.iconName)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(accentColor)
                                        .symbolRenderingMode(.hierarchical)
                                }

                                Text(task.title)
                                    .font(.headline)
                                    .lineLimit(2)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.secondary.opacity(0.07))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)

                        // Subtask input
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Subtask")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)

                            TextField(
                                "Please enter a subtask",
                                text: $subtaskTitle
                            )
                            .font(.body.weight(.medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.secondary.opacity(0.07))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .onChange(of: subtaskTitle) { oldValue, newValue in
                                // Eğer ilk kez bir karakter girilmiş ise en aşağı kaydır
                                if oldValue.isEmpty && !newValue.isEmpty {
                                    shouldScrollToBottom = true
                                }
                            }
                        }
                        .padding(.horizontal)

                        // Pomodoro count selector
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Estimated Pomodoros")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)

                            VStack(spacing: 4) {
                                HStack {
                                    Text("Pomodoros: \(pomodoroCount)")
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)

                                    Spacer()

                                    HStack(spacing: 8) {
                                        Button(action: {
                                            if pomodoroCount > 1 {
                                                pomodoroCount -= 1
                                                showWarning = shouldShowWarning
                                            }
                                        }) {
                                            Image(systemName: "minus.circle.fill")
                                                .font(.system(size: 24))
                                                .foregroundStyle(
                                                    pomodoroCount > 1
                                                        ? accentColor : Color.secondary.opacity(0.3)
                                                )
                                        }

                                        Text("\(pomodoroCount)")
                                            .font(.headline)
                                            .monospacedDigit()
                                            .frame(minWidth: 28)

                                        Button(action: {
                                            if pomodoroCount < maxPomodoroCount {
                                                pomodoroCount += 1
                                                showWarning = shouldShowWarning
                                            }
                                        }) {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 24))
                                                .foregroundStyle(
                                                    pomodoroCount < maxPomodoroCount
                                                        ? accentColor : Color.secondary.opacity(0.3)
                                                )
                                        }
                                    }
                                }

                                Slider(
                                    value: Binding(
                                        get: { Double(pomodoroCount) },
                                        set: { newValue in
                                            pomodoroCount = min(
                                                maxPomodoroCount, max(1, Int(newValue.rounded())))
                                            showWarning = shouldShowWarning
                                        }
                                    ),
                                    in: 1...Double(maxPomodoroCount),
                                    step: 1
                                )
                                .accentColor(accentColor)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.secondary.opacity(0.07))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                            if showWarning {
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(Color.orange)

                                    Text(
                                        "Consider breaking this task into smaller parts for better focus and progress tracking."
                                    )
                                    .font(.caption)
                                    .foregroundStyle(Color.orange)
                                }
                                .padding(.horizontal, 6)
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                            }

                            // Maximum pomodoro sayısını gösteren bilgi metni
                            Text("Maximum \(maxPomodoroCount) pomodoros per subtask")
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                                .padding(.horizontal, 6)
                        }
                        .padding(.horizontal)
                        .animation(.easeInOut(duration: 0.2), value: showWarning)

                        Spacer(minLength: 20)

                        Button("Add Subtask") {
                            addSubtask()
                        }
                        .disabled(subtaskTitle.isEmpty)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    subtaskTitle.isEmpty
                                        ? Color.secondary.opacity(0.3) : accentColor)
                        )
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                        .id("bottomButton")  // Scroll için ID ekliyoruz
                    }
                    .padding(.top, 16)
                }
                .scrollIndicators(.hidden)
                .onChange(of: shouldScrollToBottom) { oldValue, newValue in
                    if newValue {
                        withAnimation(.smooth) {
                            scrollProxy.scrollTo("bottomButton", anchor: .bottom)
                        }
                        // Flagı resetliyoruz
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            shouldScrollToBottom = false
                        }
                    }
                }
                .navigationTitle("Add Subtask")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
                .background(backgroundColor.ignoresSafeArea())
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .withAppTheme()
        .onAppear {
            // Check if we should show a warning based on initial value
            showWarning = shouldShowWarning
        }
    }

    private func addSubtask() {
        // Only add if title is not empty
        if !subtaskTitle.isEmpty {
            // Create a new subtask with the entered title and pomodoro count
            let subtask = PolmodorSubTask(
                title: subtaskTitle,
                pomodoro: .init(total: pomodoroCount, completed: 0)
            )

            // Add the subtask to the parent task
            task.subTasks.append(subtask)

            // Make sure the model context is updated
            // This ensures changes are persisted and UI updates
            modelContext.insert(subtask)

            // Clear the input field
            subtaskTitle = ""
        }

        // Dismiss the sheet
        dismiss()
    }
}

// MARK: - Preview
#Preview {
    // Create a mock environment for the preview
    let config = ModelConfiguration(isStoredInMemoryOnly: true)

    do {
        let container = try ModelContainer(for: PolmodorTask.self, configurations: config)
        let task = PolmodorTask.mockTasks[0]
        container.mainContext.insert(task)

        return SubTaskAddView(task: task)
            .modelContainer(container)
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}
