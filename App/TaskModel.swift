import Foundation
import OSLog
import Observation
import SwiftData
import ZumptKit

@Observable
final class TaskModel {
    private var tasks: [TaskItem] = []
    private var series: [UUID: TaskSeries] = [:]
    private var today: Date

    let now: () -> Date
    let calendar: Calendar

    private let context: ModelContext
    private let logger = Logger(subsystem: "com.renanbonassa.zumpt", category: "tasks")
    @ObservationIgnored private var dayChangeObserver: DayChangeObserver?

    private enum Entry {
        case task(TaskItem)
        case series(TaskSeries)

        var id: UUID {
            switch self {
            case .task(let task): task.id
            case .series(let series): series.id
            }
        }
    }

    init(container: ModelContainer, calendar: Calendar, now: @escaping () -> Date) {
        context = ModelContext(container)
        context.autosaveEnabled = false
        self.calendar = calendar
        self.now = now
        today = calendar.startOfDay(for: now())
        reload()
        dayChangeObserver = DayChangeObserver { [weak self] in
            self?.returnOverdueTasks()
        }
    }

    var backlog: [TaskItem] {
        Backlog.tasks(tasks)
    }

    func tasks(in week: Week, now: Date) -> [TaskItem] {
        // Include the preceding day so a late-night timed task can continue into the first column.
        let previous = calendar.date(byAdding: .day, value: -1, to: week.days[0])
        let days = ([previous].compactMap { $0 } + week.days).map { RecurrenceDay($0, calendar: calendar) }
        return tasks + series.values.flatMap { $0.tasks(on: days, now: max(today, now), calendar: calendar) }
    }

    func rule(for occurrence: TaskOccurrence) -> RecurrenceRule? {
        series[occurrence.seriesID]?.rule(on: occurrence.originalDay)
    }

    @discardableResult
    func add(title: String, undoManager: UndoManager?) -> TaskItem? {
        guard let title = TaskTitle.normalized(title) else {
            return nil
        }
        let task = TaskItem(id: UUID(), title: title, createdAt: now())
        return replace(nil, with: .task(task), actionName: String(localized: "New Task"), undoManager: undoManager)
            ? task : nil
    }

    func setRule(_ rule: RecurrenceRule, for task: TaskItem, undoManager: UndoManager?) {
        if let occurrence = task.occurrence {
            changeSeries(occurrence, actionName: String(localized: "Edit Repetition"), undoManager: undoManager) {
                $0.changeRule(from: occurrence.originalDay, to: rule)
            }
        } else if let current = tasks.first(where: { $0.id == task.id }) {
            let repeated = TaskSeries(task: current, rule: rule, calendar: calendar)
            replace(
                .task(current), with: .series(repeated), actionName: String(localized: "Set Repetition"),
                undoManager: undoManager)
        }
    }

    func move(_ item: TaskDragItem, to start: Date?, allDay: Bool = false, undoManager: UndoManager?) {
        let actionName = String(localized: "Move Task")
        if let occurrence = item.occurrence {
            guard let start else {
                return
            }
            let placement = OccurrencePlacement(start, allDay: allDay, calendar: calendar)
            changeSeries(occurrence, actionName: actionName, undoManager: undoManager) {
                $0.move(occurrence.originalDay, to: placement)
            }
            return
        }
        guard let task = tasks.first(where: { $0.id == item.id }), task.scheduledStart != start else {
            return
        }
        var moved = task
        moved.scheduledStart = start
        if start != nil {
            moved.missedStart = nil
        }
        replace(.task(task), with: .task(moved), actionName: actionName, undoManager: undoManager)
    }

    func toggleCompletion(_ task: TaskItem, undoManager: UndoManager?) {
        let timestamp = now()
        if let occurrence = task.occurrence {
            guard
                let current = series[occurrence.seriesID]?
                    .task(on: occurrence.originalDay, now: timestamp, calendar: calendar)
            else {
                return
            }
            changeSeries(occurrence, actionName: completionAction(for: current), undoManager: undoManager) {
                $0.toggleCompletion(on: occurrence.originalDay, now: timestamp)
            }
        } else if let current = tasks.first(where: { $0.id == task.id }) {
            var toggled = current
            toggled.completedAt = current.isDone ? nil : timestamp
            replace(
                .task(current), with: .task(toggled), actionName: completionAction(for: current),
                undoManager: undoManager)
        }
    }

    func rename(
        _ task: TaskItem, to text: String, scope: OccurrenceScope = .thisOccurrence, undoManager: UndoManager?
    ) {
        let actionName = String(localized: "Rename Task")
        if let occurrence = task.occurrence {
            changeSeries(occurrence, actionName: actionName, undoManager: undoManager) {
                $0.rename(on: occurrence.originalDay, to: text, scope: scope)
            }
        } else if let current = tasks.first(where: { $0.id == task.id }) {
            var renamed = current
            renamed.title = TaskTitle.renamed(current.title, to: text)
            if renamed != current {
                replace(.task(current), with: .task(renamed), actionName: actionName, undoManager: undoManager)
            }
        }
    }

    func delete(_ task: TaskItem, scope: OccurrenceScope = .thisOccurrence, undoManager: UndoManager?) {
        let actionName = String(localized: "Delete Task")
        if let occurrence = task.occurrence {
            changeSeries(occurrence, actionName: actionName, undoManager: undoManager) {
                $0.delete(on: occurrence.originalDay, scope: scope)
            }
        } else if let current = tasks.first(where: { $0.id == task.id }) {
            replace(.task(current), with: nil, actionName: actionName, undoManager: undoManager)
        }
    }

    func returnOverdueTasks() {
        let timestamp = now()
        today = calendar.startOfDay(for: timestamp)
        let overdue = OverdueTasks.returned(from: tasks, now: timestamp, calendar: calendar)
        guard !overdue.isEmpty else {
            return
        }
        do {
            for task in overdue {
                try applyTask(task, id: task.id)
            }
            try context.save()
        } catch {
            context.rollback()
            logger.error("Could not return overdue tasks: \(error.localizedDescription, privacy: .public)")
        }
        reload()
    }

    private func completionAction(for task: TaskItem) -> String {
        task.isDone ? String(localized: "Reopen Task") : String(localized: "Complete Task")
    }

    private func changeSeries(
        _ occurrence: TaskOccurrence, actionName: String, undoManager: UndoManager?, update: (inout TaskSeries) -> Void
    ) {
        guard let old = series[occurrence.seriesID] else {
            return
        }
        var new = old
        update(&new)
        if new != old {
            replace(.series(old), with: .series(new), actionName: actionName, undoManager: undoManager)
        }
    }

    @discardableResult
    private func replace(
        _ old: Entry?, with new: Entry?, actionName: String, undoManager: UndoManager?
    ) -> Bool {
        guard let id = new?.id ?? old?.id else {
            return false
        }
        do {
            if case .task(let task) = new {
                try applyTask(OverdueTasks.reconciled(task, now: now(), calendar: calendar), id: id)
            } else if case .task = old {
                try applyTask(nil, id: id)
            }
            if case .series(let series) = new {
                try applySeries(series, id: id)
            } else if case .series = old {
                try applySeries(nil, id: id)
            }
            try context.save()
        } catch {
            context.rollback()
            logger.error("Could not save tasks: \(error.localizedDescription, privacy: .public)")
            return false
        }
        reload()
        undoManager?.registerUndo(withTarget: self) { [weak undoManager] model in
            model.replace(new, with: old, actionName: actionName, undoManager: undoManager)
        }
        undoManager?.setActionName(actionName)
        return true
    }

    private func applyTask(_ task: TaskItem?, id: UUID) throws {
        var descriptor = FetchDescriptor<TaskRecord>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        let record = try context.fetch(descriptor).first
        switch (record, task) {
        case (let record?, let task?): record.update(from: task)
        case (let record?, nil): context.delete(record)
        case (nil, let task?): context.insert(TaskRecord(task))
        case (nil, nil): break
        }
    }

    private func applySeries(_ series: TaskSeries?, id: UUID) throws {
        var descriptor = FetchDescriptor<TaskSeriesRecord>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        let record = try context.fetch(descriptor).first
        if let series {
            let data = try JSONEncoder().encode(series)
            if let record {
                record.data = data
            } else {
                context.insert(TaskSeriesRecord(id: id, data: data))
            }
        } else if let record {
            context.delete(record)
        }
    }

    private func reload() {
        do {
            tasks = try context.fetch(FetchDescriptor<TaskRecord>()).map(\.task)
            let records = try context.fetch(FetchDescriptor<TaskSeriesRecord>())
            var loaded: [UUID: TaskSeries] = [:]
            for record in records {
                do {
                    loaded[record.id] = try JSONDecoder().decode(TaskSeries.self, from: record.data)
                } catch {
                    logger.error(
                        "Could not decode recurring task \(record.id, privacy: .public): \(error.localizedDescription, privacy: .public)"
                    )
                }
            }
            series = loaded
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
        let schema = Schema([TaskRecord.self, TaskSeriesRecord.self])
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
            do {
                for task in fixtureTasks where series[task.id] == nil {
                    try applyTask(task, id: task.id)
                }
                try context.save()
            } catch {
                context.rollback()
                logger.error("Could not seed tasks: \(error.localizedDescription, privacy: .public)")
            }
            reload()
        }
    #endif
}
