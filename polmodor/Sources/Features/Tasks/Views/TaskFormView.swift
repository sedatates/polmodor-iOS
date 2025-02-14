import SwiftUI

@available(iOS 14.0, *)
struct TaskFormView: View {
    @Environment(\.presentationMode) private var presentationMode

    @State private var title = ""
    @State private var description = ""
    @State private var pomodoroCount = 1

    let onSave: (PolmodorTask) -> Void

    var body: some View {
        Form {
            Section {
                TextField("Title", text: $title)
                TextEditor(text: $description)
                    .frame(minHeight: 100)
                    .placeholder(when: description.isEmpty) {
                        Text("Description (optional)")
                            .foregroundColor(.secondary)
                    }
            }

            Section("Pomodoros") {
                Stepper("Count: \(pomodoroCount)", value: $pomodoroCount, in: 1...10)
            }
        }
        .navigationTitle("New Task")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            },
            trailing: Button("Add") {
                let task = PolmodorTask(
                    title: title,
                    description: description,
                    pomodoroCount: pomodoroCount
                )
                onSave(task)
                presentationMode.wrappedValue.dismiss()
            }
            .disabled(title.isEmpty)
        )
    }
}

@available(iOS 14.0, *)
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#if DEBUG
    @available(iOS 14.0, *)
    struct TaskFormView_Previews: PreviewProvider {
        static var previews: some View {
            NavigationView {
                TaskFormView { _ in }
            }
        }
    }
#endif
