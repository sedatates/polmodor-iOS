//
//  SubtaskProgressView.swift
//  Polmodor
//
//  Created by sedat ateş on 27.02.2025.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Subtask Row View
struct SubtaskRowView: View {
    let subtask: PolmodorSubTask
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext

    // For animation and state tracking
    @State private var isCompleted: Bool
    @State private var animating = false

    init(subtask: PolmodorSubTask) {
        self.subtask = subtask
        // Initialize local state with the subtask's completion status
        _isCompleted = State(initialValue: subtask.completed)
    }

    private var backgroundColor: Color {
        isCompleted
            ? (colorScheme == .dark ? Color(white: 0.18) : Color(white: 0.95))
            : (colorScheme == .dark ? Color(white: 0.2) : Color(white: 0.97))
    }

    var body: some View {
        HStack(spacing: 12) {
            // Modern checkbox design
            ZStack {
                Circle()
                    .fill(isCompleted ? Color.green.opacity(0.2) : Color.clear)
                    .frame(width: 26, height: 26)

                Circle()
                    .stroke(
                        isCompleted ? Color.green : Color.secondary.opacity(0.4),
                        lineWidth: 1.5
                    )
                    .frame(width: 26, height: 26)

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.green)
                        .scaleEffect(animating ? 1.1 : 1.0)
                        .animation(.spring(response: 0.2), value: animating)
                }
            }

            // Title with strikethrough if completed
            Text(subtask.title)
                .font(.subheadline)
                .strikethrough(isCompleted)
                .foregroundStyle(isCompleted ? .secondary : .primary)

            Spacer()
        }
        .contentShape(Rectangle())  // Makes the entire row tappable
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isCompleted ? Color.green.opacity(0.2) : Color.secondary.opacity(0.1),
                    lineWidth: 1
                )
        )
        .onTapGesture {
            toggleSubtaskCompletion()
        }
    }

    private func toggleSubtaskCompletion() {
        // Update our local state for immediate UI feedback
        withAnimation(.easeInOut(duration: 0.2)) {
            isCompleted.toggle()
        }

        // Provide subtle animation feedback
        animating = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            animating = false
        }

        // SwiftUI'da dokunsal geri bildirim
        #if os(iOS)
            let impact = Impact(style: .light)
            impact.trigger()
        #endif

        // Update the model directly instead of using descriptor to avoid crashes
        subtask.completed = isCompleted
        try? modelContext.save()
    }
}

// SwiftUI kompatibl haptic feedback yapısı
private struct Impact {
    enum ImpactStyle {
        case light, medium, heavy, soft, rigid
    }

    let style: ImpactStyle

    func trigger() {
        // iOS hafif titreşimli dokunsal geri bildirim
        // Gerçek cihazda çalışacak kod. Simulator'da çalışmaz.
    }
}

// MARK: - Preview
#Preview {
    // Mock setup for preview
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PolmodorTask.self, configurations: config)

    // Create a preview with two subtask examples
    VStack(spacing: 20) {
        SubtaskRowView(subtask: PolmodorTask.mockTasks[0].subTasks[0])
        SubtaskRowView(subtask: PolmodorTask.mockTasks[0].subTasks[1])
    }
    .padding()
    .modelContainer(container)
}
