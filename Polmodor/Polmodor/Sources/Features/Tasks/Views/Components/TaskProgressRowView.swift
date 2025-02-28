//
//  TaskProgressRowView.swift
//  Polmodor
//
//  Created by sedat ateş on 27.02.2025.
//
import SwiftUI


struct TaskProgressRowView: View {
    let task: PolmodorTask
    
    private var completedCount: Int {
        task.subTasks.filter { $0.completed }.count
    }
    
    private var totalCount: Int {
        task.subTasks.count
    }
    
    private var progress: Double {
        totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("İlerleme")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(completedCount)/\(totalCount)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            
            // Dot-based progress indicator with animation
            HStack(spacing: 6) {
                ForEach(0..<min(totalCount, 10), id: \.self) { index in
                    Circle()
                        .fill(
                            index < completedCount
                            ? .green
                            : Color.secondary.opacity(0.2)
                        )
                        .frame(width: 8, height: 8)
                        .animation(
                            .spring(response: 0.3, dampingFraction: 0.7), value: completedCount
                        )
                        .scaleEffect(index < completedCount ? 1.2 : 1.0)
                        .animation(
                            .spring(response: 0.3, dampingFraction: 0.7), value: completedCount)
                }
                
                // If there are more than 10 subtasks, show a "+X more" indicator
                if totalCount > 10 {
                    Text("+\(totalCount - 10)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                }
                
                Spacer()
            }
        }
        
        
    }
}
