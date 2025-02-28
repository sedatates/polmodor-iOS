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
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.15) : Color.white
    }

    private var accentColor: Color {
        task.category?.color ?? .blue
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Task info card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Ana Görev")
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
                    Text("Subtask Başlığı")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    TextField("Subtask için başlık girin", text: $subtaskTitle)
                        .font(.body.weight(.medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.secondary.opacity(0.07))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)

                Spacer()

                Button("Subtask Ekle") {
                    addSubtask()
                }
                .disabled(subtaskTitle.isEmpty)
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(subtaskTitle.isEmpty ? Color.secondary.opacity(0.3) : accentColor)
                )
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
            .padding(.top, 16)
            .navigationTitle("Yeni Subtask")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func addSubtask() {
        // Only add if title is not empty
        if !subtaskTitle.isEmpty {
            // Create a new subtask with the entered title
            let subtask = PolmodorSubTask(
                title: subtaskTitle,
                pomodoro: .init(total: 1, completed: 0)
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
