//
//  PolmodorTaskRow.swift
//  Polmodor
//
//  Created by sedat ateş on 27.02.2025.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Task Row View
struct PolmodorTaskRow: View {
    let task: PolmodorTask
    @State private var isExpanded = false
    @State private var showAddSubtask = false
    @Namespace private var animation
    @Environment(\.colorScheme) private var colorScheme
    
    // Animation properties
    @State private var cardHeight: CGFloat = 0
    @State private var subtaskOpacity: Double = 0
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.15) : Color.white
    }
    
    private var accentColor: Color {
        task.category?.color ?? .blue
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main task card
            VStack(spacing: 0) {
                // Task header
                PolmodorTaskHeader(task: task, accentColor: Color.accentColor, isExpanded: $isExpanded)
                
                // PolmodorTaskInfoRow
                PolmodorTaskInfoRow(task: task)
                
                // Subtask progress indicator
                TaskProgressRowView(task: task)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                
                if isExpanded {
                    // Subtasks section (expanded)
                    Divider()
                        .padding(.horizontal, 16)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    
                    PolmodorTaskExpandedView(
                        task: task,
                        accentColor: accentColor,
                        isExpanded: $isExpanded,
                        showAddSubtask: $showAddSubtask
                    )
                    .padding(.horizontal, 16)
                }
            }
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.secondary.opacity(0.1), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        
        .sheet(isPresented: $showAddSubtask) {
            SubTaskAddView(task: task)
                .presentationDetents([.medium])
        }
        .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 16))
        .contextMenu {
            NavigationLink(destination: TaskDetailView(task: task)) {
                Label("View Details", systemImage: "info.circle")
            }
            
            if !task.completed {
                Button {
                    // Mark as completed logic
                } label: {
                    Label("Complete", systemImage:
                            "checkmark.circle")
                }
            }
            
            Button(role: .destructive) {
                // Delete task logic
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        
        
    }
    
    
    
    
}

struct TaskRowView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            ForEach(PolmodorTask.mockTasks) { task in
                PolmodorTaskRow(task: task)
                    .padding(.horizontal)
            }
            
        }
    }
}
