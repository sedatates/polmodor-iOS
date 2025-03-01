//
//  PolmodorTaskInfoRow.swift
//  Polmodor
//
//  Created by sedat ateş on 1.03.2025.
//

import Foundation
import SwiftUI


struct PolmodorTaskInfoRow: View {
    let task: PolmodorTask
    
   
    
    var body: some View {
        // Metadata row
        HStack(spacing: 12) {
            // Pomodoro count
            HStack(spacing: 6) {
                Image(systemName: "timer")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                
                Text("\(task.completedPomodoros)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.secondary.opacity(0.1))
            .clipShape(Capsule())
            
            // Due date if not completed
            if !task.completed {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundStyle(isDueSoon(task.dueDate) ? .red : .secondary)
                    
                    Text(formatDueDate(task.dueDate))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(isDueSoon(task.dueDate) ? .red : .secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.1))
                .clipShape(Capsule())
            }
            
            Spacer()
            
            // Category tag
            if let category = task.category {
                Text(category.name)
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(category.color.opacity(0.15))
                    .foregroundStyle(category.color)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}

private func formatDueDate(_ date: Date) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .short
    return formatter.localizedString(for: date, relativeTo: Date())
}

private func isDueSoon(_ date: Date) -> Bool {
    return date < Date().addingTimeInterval(24 * 60 * 60)  // 24 hours
}

struct PolmodorTaskInfoRow_Previews: PreviewProvider {
    static var previews: some View {
        PolmodorTaskInfoRow(task: PolmodorTask.mockTasks.first!)
            .previewLayout(.sizeThatFits)
            .padding()
        
        PolmodorTaskInfoRow(task: PolmodorTask.mockTasks.last!)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
