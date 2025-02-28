//
//  PolmodorTaskRow.swift
//  Polmodor
//
//  Created by sedat ateş on 27.02.2025.
//

import Foundation
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
                HStack(alignment: .center, spacing: 12) {
                    // Task icon with category color
                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(0.15))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: task.iconName)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(accentColor)
                            .symbolRenderingMode(.hierarchical)
                    }
                    
                    // Task content
                    VStack(alignment: .leading, spacing: 4) {
                        // Title row
                        Text(task.title)
                            .font(.headline)
                            .strikethrough(task.completed)
                            .foregroundStyle(task.completed ? .secondary : .primary)
                            .lineLimit(1)
                        
                        // Description if available
                        if !task.taskDescription.isEmpty {
                            Text(task.taskDescription)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(isExpanded ? 3 : 1)
                                .animation(.easeInOut, value: isExpanded)
                        }
                    }
                    
                    Spacer()
                    
                    // Status indicators
                    HStack(spacing: 8) {
                        if task.completed {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .symbolRenderingMode(.hierarchical)
                                .font(.system(size: 18))
                        } else if task.isTimerRunning {
                            Image(systemName: "timer.circle.fill")
                                .foregroundStyle(.orange)
                                .symbolRenderingMode(.hierarchical)
                                .font(.system(size: 18))
                                .symbolEffect(.pulse, options: .repeating)
                        }
                        
                        // Dropdown indicator
                        ZStack {
                            Circle()
                                .fill(Color.secondary.opacity(0.15))
                                .frame(width: 28, height: 28)
                            
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.secondary)
                                .rotationEffect(isExpanded ? .degrees(180) : .degrees(0))
                        }
                        .contentShape(Circle())
                        .onTapGesture {
                            withAnimation(
                                .spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.3)
                            ) {
                                isExpanded.toggle()
                                subtaskOpacity = isExpanded ? 1 : 0
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                
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
                
                // Subtask progress indicator
                
                TaskProgressRowView(task: task)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                
                // Divider that appears when expanded
                if isExpanded {
                    Divider()
                        .padding(.horizontal, 16)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                // Subtasks section (expanded)
                if isExpanded {
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
                                    .buttonStyle(ScaleButtonStyle())
                                    .contentShape(Rectangle())
                                    
                                    Spacer()
                                    ZStack {
                                        CustomNavigationLink {
                                            TaskDetailView(task: task)
                                        } label: {
                                            Text("View Details")
                                                .font(.subheadline.weight(.medium))
                                                .foregroundStyle(accentColor)
                                                .padding(.vertical, 8)
                                        }
                                        
                                        
                                        
                                        
                                    }
                                    
                                    
                                }.padding(.horizontal, 16).padding(.bottom, 16)
                                
                                
                            }
                        }
                    }
                    .opacity(subtaskOpacity)
                    .animation(
                        .easeInOut(duration: 0.3).delay(isExpanded ? 0.1 : 0), value: isExpanded)
                }
            }
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.07), radius: 8, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.secondary.opacity(0.1), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .padding(.vertical, 6)
        .sheet(isPresented: $showAddSubtask) {
            SubTaskAddView(task: task)
                .presentationDetents([.medium])
        }
        .contextMenu {
            NavigationLink(destination: TaskDetailView(task: task)) {
                Label("Detayları Görüntüle", systemImage: "info.circle")
            }
            
            if !task.completed {
                Button {
                    // Mark as completed logic
                } label: {
                    Label("Tamamlandı Olarak İşaretle", systemImage: "checkmark.circle")
                }
            }
            
            Button(role: .destructive) {
                // Delete task logic
            } label: {
                Label("Sil", systemImage: "trash")
            }
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
