import Foundation
import OSLog
import Observation
import SwiftData
import ZumptKit

@Observable
final class TaskModel {
    private(set) var tasks: [TaskItem] = []

    let now: () -> Date

    private let context: ModelContext
    private let logger = Logger(subsystem: "com.renanbonassa.zumpt", category: "tasks")

    init(container: ModelContainer, now: @escaping () -> Date) {
        context = ModelContext(container)
        context.autosaveEnabled = false
        self.now = now
        reload()
    }

    var backlog: [TaskItem] {
        Backlog.tasks(tasks)
    }

    @discardableResult
    func add(title: String, undoManager: UndoManager?) -> TaskItem? {
        guard let title = TaskTitle.normalized(title) else {
            return nil
        }
        let task = TaskItem(id: UUID(), title: title, createdAt: now())
        replace(nil, with: task, id: task.id, actionName: String(localized: "New Task"), undoManager: undoManager)
        return task
    }

    private func replace(
        _ oldTask: TaskItem?,
        with newTask: TaskItem?,
        id: UUID,
        actionName: String,
        undoManager: UndoManager?
    ) {
        write(newTask, id: id)
        undoManager?.registerUndo(withTarget: self) { [weak undoManager] model in
            model.replace(newTask, with: oldTask, id: id, actionName: actionName, undoManager: undoManager)
        }
        undoManager?.setActionName(actionName)
    }

    private func write(_ task: TaskItem?, id: UUID) {
        let record = record(id: id)
        switch (record, task) {
        case (let record?, let task?):
            record.update(from: task)
        case (let record?, nil):
            context.delete(record)
        case (nil, let task?):
            context.insert(TaskRecord(task))
        case (nil, nil):
            return
        }
        save()
    }

    private func record(id: UUID) -> TaskRecord? {
        var descriptor = FetchDescriptor<TaskRecord>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        do {
            return try context.fetch(descriptor).first
        } catch {
            logger.error(
                "Could not fetch task \(id, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    private func save() {
        do {
            try context.save()
        } catch {
            logger.error("Could not save tasks: \(error.localizedDescription, privacy: .public)")
        }
        reload()
    }

    private func reload() {
        do {
            tasks = try context.fetch(FetchDescriptor<TaskRecord>()).map(\.task)
        } catch {
            logger.error("Could not load tasks: \(error.localizedDescription, privacy: .public)")
        }
    }
}

extension TaskModel {
    static func make(options: LaunchOptions, calendar: Calendar) -> TaskModel {
        let model = TaskModel(container: container(for: options), now: options.now)
        #if DEBUG
            if let fixture = options.taskFixture {
                model.seed(FixtureTasks.tasks(named: fixture, now: options.now(), calendar: calendar))
            }
        #endif
        return model
    }

    private static func container(for options: LaunchOptions) -> ModelContainer {
        let schema = Schema([TaskRecord.self])
        let configuration: ModelConfiguration =
            switch options.tasksStore {
            case .memory:
                ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
            case .file(let url):
                ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
            case nil:
                ModelConfiguration("Tasks", schema: schema, cloudKitDatabase: .none)
            }
        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            preconditionFailure("Could not open the tasks store: \(error)")
        }
    }

    #if DEBUG
        private func seed(_ fixtureTasks: [TaskItem]) {
            for task in fixtureTasks {
                write(task, id: task.id)
            }
        }
    #endif
}
