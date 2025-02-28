//
//  SubtaskProgressView.swift
//  Polmodor
//
//  Created by sedat ateş on 27.02.2025.
//

import Foundation
import SwiftUI


// MARK: - Subtask Row View
struct SubtaskRowView: View {
    let subtask: PolmodorSubTask
    @Environment(\.colorScheme) private var colorScheme

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.2) : Color(white: 0.97)
    }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                // Toggle completion logic
            }) {
                ZStack {
                    Circle()
                        .stroke(
                            subtask.completed ? Color.green : Color.secondary.opacity(0.3),
                            lineWidth: 1.5
                        )
                        .frame(width: 22, height: 22)

                    if subtask.completed {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())

            VStack(alignment: .leading, spacing: 4) {
                Text(subtask.title)
                    .font(.subheadline.weight(subtask.completed ? .regular : .medium))
                    .strikethrough(subtask.completed)
                    .foregroundStyle(subtask.completed ? .secondary : .primary)

                // Add creation date or other metadata if available
                if subtask.completed {
                    Text("Tamamlandı")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            Spacer()

            if subtask.completed {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
                    .background(Circle().fill(Color.green))
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.secondary.opacity(0.1), lineWidth: 1)
        )
    }
}


struct SubtaskRowView_Previews: PreviewProvider {
    static var previews: some View {
        SubtaskRowView(subtask: PolmodorTask.mockTasks[0].subTasks[0])
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
