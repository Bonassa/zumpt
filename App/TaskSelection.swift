import AppKit
import Foundation
import Observation

@Observable
final class TaskSelection {
    private(set) var selectedID: UUID?
    private(set) var renamingID: UUID?
    private(set) var detailsID: UUID?
    private var pendingRenameID: UUID?
    var editor: TaskEditorRequest?

    @ObservationIgnored private var pendingDetails: Task<Void, Never>?

    func select(_ id: UUID) {
        if renamingID != id {
            renamingID = nil
        }
        if detailsID != id {
            closeDetails()
        }
        if pendingRenameID != id {
            pendingRenameID = nil
        }
        selectedID = id
    }

    func selectAndShowDetails(_ id: UUID) {
        guard editor == nil else {
            return
        }
        select(id)
        pendingDetails?.cancel()
        pendingDetails = Task { [weak self] in
            try? await Task.sleep(for: .seconds(NSEvent.doubleClickInterval))
            guard !Task.isCancelled, let self, selectedID == id, renamingID == nil else {
                return
            }
            detailsID = id
        }
    }

    func closeDetails() {
        pendingDetails?.cancel()
        pendingDetails = nil
        detailsID = nil
    }

    func renameAfterClosingDetails(_ id: UUID) {
        pendingRenameID = id
        closeDetails()
    }

    func detailsDidClose() {
        guard let id = pendingRenameID else {
            return
        }
        pendingRenameID = nil
        beginRenaming(id)
    }

    func beginRenaming(_ id: UUID) {
        closeDetails()
        renamingID = id
        selectedID = id
    }

    func endRenaming() {
        renamingID = nil
    }

    func clear() {
        pendingRenameID = nil
        closeDetails()
        renamingID = nil
        selectedID = nil
    }
}
