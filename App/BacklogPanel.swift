import SwiftUI
import ZumptKit

struct BacklogPanel: View {
    let model: TaskModel

    @State private var isAddingTask = false
    @State private var draft = ""
    @FocusState private var isNewTaskFieldFocused: Bool
    @Environment(\.undoManager) private var undoManager

    static let width: CGFloat = 280

    var body: some View {
        let backlog = model.backlog
        VStack(alignment: .leading, spacing: 12) {
            BacklogHeader(count: backlog.count, addTask: beginNewTask)
                .padding(.horizontal, 16)
            if isAddingTask {
                newTaskField
                    .padding(.horizontal, 16)
            }
            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 6) {
                    if backlog.isEmpty && !isAddingTask {
                        Text("Press ⌘N to add a task.")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 2)
                            .accessibilityIdentifier("backlog-empty")
                    }
                    ForEach(backlog) { task in
                        BacklogRow(task: task)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .scrollIndicators(.automatic)
        }
        .padding(.top, 16)
        .frame(width: Self.width)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color.backlogBackground)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("backlog")
        .focusedSceneValue(\.newTask, beginNewTask)
    }

    private var newTaskField: some View {
        TextField("New task", text: $draft)
            .textFieldStyle(.plain)
            .font(.system(size: 13))
            .focused($isNewTaskFieldFocused)
            .padding(.horizontal, 10)
            .frame(height: 36)
            .background(Color.backlogCard, in: .rect(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.task, lineWidth: 1.5)
            }
            .onSubmit(commitNewTask)
            .onExitCommand(perform: endNewTask)
            .onAppear {
                Task {
                    isNewTaskFieldFocused = true
                }
            }
            .accessibilityIdentifier("new-task-field")
    }

    private func beginNewTask() {
        if isAddingTask {
            isNewTaskFieldFocused = true
        } else {
            isAddingTask = true
        }
    }

    private func commitNewTask() {
        model.add(title: draft, undoManager: undoManager)
        endNewTask()
    }

    private func endNewTask() {
        draft = ""
        isAddingTask = false
    }
}

private struct BacklogHeader: View {
    let count: Int
    let addTask: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text("Backlog")
                .font(.system(size: 15, weight: .bold))
                .accessibilityAddTraits(.isHeader)
            Text(verbatim: "\(count)")
                .font(.system(size: 11.5, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .padding(.horizontal, 7)
                .padding(.vertical, 1)
                .background(Capsule().fill(Color.primary.opacity(0.08)))
                .accessibilityLabel(Text("\(count) tasks"))
                .accessibilityIdentifier("backlog-count")
            Spacer(minLength: 0)
            Button("New Task", systemImage: "plus", action: addTask)
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .font(.system(size: 13, weight: .medium))
                .help(Text("New Task"))
                .accessibilityIdentifier("new-task-button")
        }
        .frame(height: 24)
    }
}

private struct BacklogRow: View {
    let task: TaskItem

    var body: some View {
        Text(verbatim: task.title)
            .font(.system(size: 13, weight: .medium))
            .lineLimit(2)
            .frame(maxWidth: .infinity, minHeight: 20, alignment: .leading)
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(Color.backlogCard, in: .rect(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.backlogCardBorder, lineWidth: 1)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("backlog-task-\(task.title)")
    }
}

extension FocusedValues {
    @Entry var newTask: (() -> Void)?
}

struct NewTaskCommand: View {
    @FocusedValue(\.newTask) private var newTask

    var body: some View {
        Button("New Task") {
            newTask?()
        }
        .keyboardShortcut("n", modifiers: .command)
        .disabled(newTask == nil)
    }
}
