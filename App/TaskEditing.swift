import SwiftUI
import ZumptKit

struct TaskTitleField: View {
    let task: TaskItem
    let font: Font

    @State private var draft: String
    @FocusState private var isFocused: Bool
    @Environment(TaskModel.self) private var model
    @Environment(TaskSelection.self) private var selection
    @Environment(\.undoManager) private var undoManager

    init(task: TaskItem, font: Font) {
        self.task = task
        self.font = font
        _draft = State(initialValue: task.title)
    }

    var body: some View {
        TextField("Title", text: $draft)
            .textFieldStyle(.plain)
            .font(font)
            .focused($isFocused)
            .onSubmit(save)
            .onExitCommand(perform: selection.endRenaming)
            .onAppear {
                Task {
                    isFocused = true
                }
            }
            .onChange(of: isFocused) { _, isFocused in
                if !isFocused, selection.renamingID == task.id {
                    save()
                }
            }
            .accessibilityIdentifier("rename-field")
    }

    private func save() {
        model.rename(task.id, to: draft, undoManager: undoManager)
        selection.endRenaming()
    }
}

struct TaskContextMenu: View {
    let task: TaskItem
    let model: TaskModel
    let selection: TaskSelection
    let undoManager: UndoManager?

    var body: some View {
        Button("Rename") {
            selection.beginRenaming(task.id)
        }
        Divider()
        Button("Delete", role: .destructive) {
            selection.clear()
            model.delete(task.id, undoManager: undoManager)
        }
    }
}

extension View {
    func taskKeyboardHandling(for task: TaskItem) -> some View {
        modifier(TaskKeyboardHandling(task: task))
    }
}

private struct TaskKeyboardHandling: ViewModifier {
    let task: TaskItem

    @FocusState private var isFocused: Bool
    @Environment(TaskModel.self) private var model
    @Environment(TaskSelection.self) private var selection
    @Environment(\.undoManager) private var undoManager

    func body(content: Content) -> some View {
        content
            .focusable()
            .focusEffectDisabled()
            .focused($isFocused)
            .onChange(of: selection.selectedID == task.id && selection.renamingID == nil) { _, shouldFocus in
                if shouldFocus {
                    Task {
                        isFocused = true
                    }
                }
            }
            .onExitCommand {
                if selection.detailsID == task.id {
                    selection.closeDetails()
                }
            }
            .onDeleteCommand {
                guard selection.selectedID == task.id, selection.renamingID == nil else {
                    return
                }
                selection.clear()
                model.delete(task.id, undoManager: undoManager)
            }
    }
}
