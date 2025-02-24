import Foundation

struct PolmodorSubTask: Identifiable, Codable {
  let id: UUID
  let title: String
  var completed: Bool
  var pomodoro: PomodoroProgress

  struct PomodoroProgress: Codable {
    var total: Int
    var completed: Int

    init(total: Int, completed: Int) {
      self.total = total
      self.completed = completed
    }
  }

  init(id: UUID = UUID(), title: String, completed: Bool = false, pomodoro: PomodoroProgress) {
    self.id = id
    self.title = title
    self.completed = completed
    self.pomodoro = pomodoro
  }
}
