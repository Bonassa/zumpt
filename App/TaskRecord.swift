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
            completedAt: completedAt
        )
    }

    func update(from task: TaskItem) {
        title = task.title
        createdAt = task.createdAt
        scheduledStart = task.scheduledStart
        completedAt = task.completedAt
    }
}
