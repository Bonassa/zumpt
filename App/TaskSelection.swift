import Foundation
import Observation

@Observable
final class TaskSelection {
    private(set) var selectedID: UUID?
    private(set) var renamingID: UUID?

    func select(_ id: UUID) {
        if renamingID != id {
            renamingID = nil
        }
        selectedID = id
    }

    func beginRenaming(_ id: UUID) {
        renamingID = id
        selectedID = id
    }

    func endRenaming() {
        renamingID = nil
    }

    func clear() {
        renamingID = nil
        selectedID = nil
    }
}
