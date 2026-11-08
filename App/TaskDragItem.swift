import CoreTransferable
import Foundation
import UniformTypeIdentifiers

nonisolated struct TaskDragItem: Codable, Transferable {
    let id: UUID

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .zumptTask)
    }
}

extension UTType {
    nonisolated static let zumptTask = UTType(exportedAs: "com.renanbonassa.zumpt.task")
}
