import Foundation
import OSLog
import Observation
import SwiftData
import ZumptKit

@Observable
final class TaskModel {
    private(set) var tasks: [TaskItem] = []

    let now: () -> Date

    private let calendar: Calendar
    private let context: ModelContext
    private let logger = Logger(subsystem: "com.renanbonassa.zumpt", category: "tasks")
    @ObservationIgnored private var dayChangeObserver: DayChangeObserver?

    init(container: ModelContainer, calendar: Calendar, now: @escaping () -> Date) {
        context = ModelContext(container)
        context.autosaveEnabled = false
        self.calendar = calendar
        self.now = now
        reload()
        dayChangeObserver = DayChangeObserver { [weak self] in
            self?.returnOverdueTasks()
        }
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

    func move(_ id: UUID, to start: Date?, undoManager: UndoManager?) {
        guard let task = tasks.first(where: { $0.id == id }), task.scheduledStart != start else {
            return
        }
        var moved = task
        moved.scheduledStart = start
        if start != nil {
            moved.missedStart = nil
        }
        replace(task, with: moved, id: id, actionName: String(localized: "Move Task"), undoManager: undoManager)
    }

    func toggleCompletion(_ id: UUID, undoManager: UndoManager?) {
        guard let task = tasks.first(where: { $0.id == id }) else {
            return
        }
        var toggled = task
        toggled.completedAt = task.isDone ? nil : now()
        let actionName = task.isDone ? String(localized: "Reopen Task") : String(localized: "Complete Task")
        replace(task, with: toggled, id: id, actionName: actionName, undoManager: undoManager)
    }

    func returnOverdueTasks() {
        let overdue = OverdueTasks.returned(from: tasks, now: now(), calendar: calendar)
        guard !overdue.isEmpty else {
            return
        }
        for task in overdue {
            apply(task, id: task.id)
        }
        save()
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
        apply(task, id: id)
        save()
    }

    private func apply(_ task: TaskItem?, id: UUID) {
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
        let model = TaskModel(container: container(for: options), calendar: calendar, now: options.now)
        #if DEBUG
            if let fixture = options.taskFixture {
                model.seed(FixtureTasks.tasks(named: fixture, now: options.now(), calendar: calendar))
            }
        #endif
        model.returnOverdueTasks()
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
                apply(task, id: task.id)
            }
            save()
        }
    #endif
}
