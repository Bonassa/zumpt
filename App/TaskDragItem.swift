import CoreTransferable
import Foundation
import UniformTypeIdentifiers
import ZumptKit

nonisolated struct TaskDragItem: Codable, Transferable {
    let id: UUID
    let occurrence: TaskOccurrence?

    init(task: TaskItem) {
        id = task.id
        occurrence = task.occurrence
    }

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .zumptTask)
    }
}

extension UTType {
    nonisolated static let zumptTask = UTType(exportedAs: "com.renanbonassa.zumpt.task")
}
