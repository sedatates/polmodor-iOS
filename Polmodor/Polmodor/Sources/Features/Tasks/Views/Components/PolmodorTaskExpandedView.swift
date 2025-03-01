//
//  PolmodorTaskExpandedView.swift
//  Polmodor
//
//  Created by sedat ateş on 1.03.2025.
//

import Foundation
import SwiftUI


struct PolmodorTaskExpandedView: View {
    let task: PolmodorTask
    let accentColor: Color
    @Binding var isExpanded: Bool
    @Binding var showAddSubtask: Bool
    
    
    
    
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
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.bottom, 16)
                    
                    CustomNavigationLink {
                        TaskDetailView(task: task)
                    } label: {
                        Text("View Details")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.gray)
                            .padding(.vertical, 8)
                    }
                    
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
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    .padding(.horizontal, 16)
                    
                    HStack {
                        Button(action: {
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
                        
                        Spacer()
                        
                        ZStack {
                            CustomNavigationLink {
                                TaskDetailView(task: task)
                            } label: {
                                Text("View Details")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.gray)
                                    .padding(.vertical, 8)
                            }
                        }
                    }.padding(.horizontal, 16).padding(.bottom, 16)
                }
            }
        }
        .animation(
            .easeInOut(duration: 0.3).delay(isExpanded ? 0.1 : 0), value: isExpanded)
    }
}




struct PolmodorTaskExpandedView_Previews: PreviewProvider {
    static var previews: some View {
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
}
