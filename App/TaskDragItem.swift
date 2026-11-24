import CoreTransferable
import Foundation
import SwiftUI
import UniformTypeIdentifiers
import ZumptKit

nonisolated struct TaskDragItem: Codable, Hashable, Sendable, Transferable {
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

extension DropSession {
    var draggedTasks: [TaskDragItem] {
        localSession?.draggedItemIDs(for: TaskDragItem.self) ?? []
    }
}

extension View {
    func taskDraggable(_ task: TaskItem) -> some View {
        draggable(TaskDragItem.self, id: \.self, item: TaskDragItem(task: task))
    }

    func taskDropTarget(
        accepts: @escaping (TaskDragItem) -> Bool,
        isTargeted: Binding<Bool>
    ) -> some View {
        dropConfiguration { session in
            DropConfiguration(operation: Self.accepts(session, accepts) ? .move : .forbidden)
        }
        .onDropSessionUpdated { session in
            switch session.phase {
            case .entering, .active:
                isTargeted.wrappedValue = Self.accepts(session, accepts)
            default:
                isTargeted.wrappedValue = false
            }
        }
    }

    private static func accepts(_ session: DropSession, _ accepts: (TaskDragItem) -> Bool) -> Bool {
        let tasks = session.draggedTasks
        return !tasks.isEmpty && tasks.allSatisfy(accepts)
    }
}
