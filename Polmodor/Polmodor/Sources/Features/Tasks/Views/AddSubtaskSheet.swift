import SwiftUI

struct AddSubtaskSheet: View {
  @Binding var isPresented: Bool
  @Binding var newSubtaskTitle: String
  @Binding var selectedPomodoroCount: Int
  let addSubtask: () -> Void

  var body: some View {
    NavigationView {
      Form {
        TextField("Subtask Title", text: $newSubtaskTitle)

        Stepper(
          "Pomodoros: \(selectedPomodoroCount)",
          value: $selectedPomodoroCount, in: 1...10
        )
      }
      .navigationTitle("Add Subtask")
      .navigationBarItems(
        leading: cancelButton,
        trailing: addButton
      )
    }
    .presentationDetents([.medium])
  }

  private var cancelButton: some View {
    Button("Cancel") {
      isPresented = false
      newSubtaskTitle = ""
      selectedPomodoroCount = 1
    }
  }

  private var addButton: some View {
    Button("Add") {
      addSubtask()
      isPresented = false
      newSubtaskTitle = ""
      selectedPomodoroCount = 1
    }
    .disabled(newSubtaskTitle.isEmpty)
  }
}

#Preview {
  AddSubtaskSheet(
    isPresented: .constant(true),
    newSubtaskTitle: .constant(""),
    selectedPomodoroCount: .constant(1),
    addSubtask: {}
  )
}
