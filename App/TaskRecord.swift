import Foundation
import SwiftData
import ZumptKit

@Model
final class TaskRecord {
    var id: UUID = UUID()
    var title: String = ""
    var createdAt: Date = Date.distantPast

    init(_ task: TaskItem) {
        id = task.id
        title = task.title
        createdAt = task.createdAt
    }

    var task: TaskItem {
        TaskItem(id: id, title: title, createdAt: createdAt)
    }

    func update(from task: TaskItem) {
        title = task.title
        createdAt = task.createdAt
    }
}
