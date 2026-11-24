import Foundation
import SwiftData
import ZumptKit

@Model
final class TaskRecord {
    var id: UUID = UUID()
    var title: String = ""
    var createdAt: Date = Date.distantPast
    var scheduledStart: Date?
    var completedAt: Date?
    var missedStart: Date?

    init(_ task: TaskItem) {
        id = task.id
        update(from: task)
    }

    var task: TaskItem {
        TaskItem(
            id: id,
            title: title,
            createdAt: createdAt,
            scheduledStart: scheduledStart,
            completedAt: completedAt,
            missedStart: missedStart
        )
    }

    func update(from task: TaskItem) {
        title = task.title
        createdAt = task.createdAt
        scheduledStart = task.scheduledStart
        completedAt = task.completedAt
        missedStart = task.missedStart
    }
}

/// One record stores the rule history and exceptions for a series.
@Model
final class TaskSeriesRecord {
    @Attribute(.unique) var id: UUID
    var data: Data

    init(id: UUID, data: Data) {
        self.id = id
        self.data = data
    }
}
