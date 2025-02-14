import Foundation
import Combine

protocol TaskServiceProtocol {
    var tasksPublisher: AnyPublisher<[PolmodorTask], Never> { get }
    
    func fetchTasks() -> AnyPublisher<[PolmodorTask], Never>
    func addTask(_ task: PolmodorTask) -> AnyPublisher<Void, Never>
    func updateTask(_ task: PolmodorTask) -> AnyPublisher<Void, Never>
    func deleteTask(_ task: PolmodorTask) -> AnyPublisher<Void, Never>
    func deleteAllTasks() -> AnyPublisher<Void, Never>
}

class TaskService: TaskServiceProtocol {
    private let tasksSubject = CurrentValueSubject<[PolmodorTask], Never>([])
    private let userDefaults: UserDefaults
    private let tasksKey = "savedTasks"
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        loadTasks()
    }
    
    var tasksPublisher: AnyPublisher<[PolmodorTask], Never> {
        tasksSubject.eraseToAnyPublisher()
    }
    
    func fetchTasks() -> AnyPublisher<[PolmodorTask], Never> {
        tasksPublisher
    }
    
    func addTask(_ task: PolmodorTask) -> AnyPublisher<Void, Never> {
        var tasks = tasksSubject.value
        tasks.append(task)
        tasksSubject.send(tasks)
        saveTasks()
        return Just(()).eraseToAnyPublisher()
    }
    
    func updateTask(_ task: PolmodorTask) -> AnyPublisher<Void, Never> {
        var tasks = tasksSubject.value
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            tasksSubject.send(tasks)
            saveTasks()
        }
        return Just(()).eraseToAnyPublisher()
    }
    
    func deleteTask(_ task: PolmodorTask) -> AnyPublisher<Void, Never> {
        var tasks = tasksSubject.value
        tasks.removeAll { $0.id == task.id }
        tasksSubject.send(tasks)
        saveTasks()
        return Just(()).eraseToAnyPublisher()
    }
    
    func deleteAllTasks() -> AnyPublisher<Void, Never> {
        tasksSubject.send([])
        saveTasks()
        return Just(()).eraseToAnyPublisher()
    }
    
    private func loadTasks() {
        guard let data = userDefaults.data(forKey: tasksKey),
              let tasks = try? JSONDecoder().decode([PolmodorTask].self, from: data) else {
            return
        }
        tasksSubject.send(tasks)
    }
    
    private func saveTasks() {
        guard let data = try? JSONEncoder().encode(tasksSubject.value) else {
            return
        }
        userDefaults.set(data, forKey: tasksKey)
    }
} 