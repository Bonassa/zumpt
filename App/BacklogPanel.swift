import SwiftUI
import ZumptKit

struct BacklogPanel: View {
    let model: TaskModel
    let workspace: Workspace

    @State private var isDropTargeted = false
    @State private var draft = ""
    @FocusState private var isNewTaskFieldFocused: Bool
    @Environment(\.undoManager) private var undoManager

    static let width: CGFloat = 280

    var body: some View {
        let filter = workspace.backlogFilter
        let backlog = filter.tasks(in: model.backlog)
        let isAddingTask = workspace.isAddingTask
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                BacklogHeader(count: backlog.count, addTask: workspace.beginNewTask)
                Text("Tasks without a time. Drag one into the week to schedule it.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 16)
            if filter != .all {
                FilterChip(filter: filter) {
                    workspace.backlogFilter = .all
                }
                .padding(.horizontal, 16)
            }
            if isAddingTask {
                newTaskField
                    .padding(.horizontal, 16)
            }
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 6) {
                    if backlog.isEmpty && !isAddingTask {
                        emptyMessage(for: filter)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 2)
                            .accessibilityIdentifier("backlog-empty")
                    }
                    let overdue = backlog.filter(\.isOverdue)
                    if !overdue.isEmpty {
                        if filter != .overdue {
                            Text("Overdue")
                                .font(.system(size: 11, weight: .semibold))
                                .tracking(0.44)
                                .textCase(.uppercase)
                                .foregroundStyle(Color.overdue)
                                .padding(.horizontal, 2)
                                .accessibilityAddTraits(.isHeader)
                                .accessibilityIdentifier("backlog-overdue-header")
                        }
                        rows(overdue)
                        if overdue.count < backlog.count {
                            Color.clear.frame(height: 4)
                        }
                    }
                    rows(backlog.filter { !$0.isOverdue })
                }
                .animation(.snappy(duration: 0.2), value: backlog.map(\.id))
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .scrollIndicators(.automatic)
        }
        .padding(.top, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.backlogBackground)
        .overlay {
            if isDropTargeted {
                Rectangle()
                    .fill(Color.task.opacity(0.06))
                    .strokeBorder(Color.task, lineWidth: 2)
                    .allowsHitTesting(false)
            }
        }
        .dropDestination(for: TaskDragItem.self) { items, _ in
            isDropTargeted = false
            for item in items where item.occurrence == nil {
                model.move(item, to: nil, undoManager: undoManager)
            }
        }
        .taskDropTarget(accepts: { $0.occurrence == nil }, isTargeted: $isDropTargeted)
        .onChange(of: workspace.newTaskRequests) {
            isNewTaskFieldFocused = true
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("backlog")
    }

    private func emptyMessage(for filter: BacklogFilter) -> Text {
        switch filter {
        case .all: Text("Press ⌘N to add a task.")
        case .overdue: Text("No overdue tasks.")
        }
    }

    private func rows(_ tasks: [TaskItem]) -> some View {
        ForEach(tasks) { task in
            BacklogRow(task: task)
                .taskDraggable(task)
        }
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

    private func commitNewTask() {
        model.add(title: draft, undoManager: undoManager)
        endNewTask()
    }

    private func endNewTask() {
        draft = ""
        workspace.endNewTask()
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

private struct FilterChip: View {
    let filter: BacklogFilter
    let clear: () -> Void

    private var tint: Color {
        filter == .overdue ? .overdue : .task
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: filter.systemImage)
                .font(.system(size: 10.5, weight: .semibold))
            Text(filter.title)
                .font(.system(size: 11.5, weight: .semibold))
            Button("Show All Tasks", systemImage: "xmark", action: clear)
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
                .font(.system(size: 9, weight: .bold))
                .frame(width: 14, height: 14)
                .contentShape(.rect)
                .help(Text("Show All Tasks"))
                .accessibilityIdentifier("backlog-filter-clear")
        }
        .foregroundStyle(tint)
        .padding(.leading, 8)
        .padding(.trailing, 4)
        .frame(height: 22)
        .background(Capsule().fill(tint.opacity(0.12)))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("backlog-filter-chip")
    }
}

private struct BacklogRow: View {
    let task: TaskItem

    @Environment(TaskModel.self) private var model
    @Environment(TaskSelection.self) private var selection
    @Environment(\.undoManager) private var undoManager
    @Environment(\.locale) private var locale

    var body: some View {
        let isSelected = selection.selectedID == task.id
        HStack(spacing: 10) {
            CompletionButton(task: task, size: 16)
            VStack(alignment: .leading, spacing: 2) {
                if selection.renamingID == task.id {
                    TaskTitleField(task: task, font: .system(size: 13, weight: .medium))
                } else {
                    Text(verbatim: task.title)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(2)
                }
                if task.isOverdue, let missedStart = task.missedStart {
                    Text("Due \(missedStart.formatted(Self.dueDateStyle(locale: locale)))")
                        .font(.system(size: 11.5))
                        .foregroundStyle(Color.overdue)
                        .accessibilityIdentifier("backlog-task-due-\(task.title)")
                }
            }
            .frame(maxWidth: .infinity, minHeight: 20, alignment: .leading)
        }
        .padding(.vertical, 8)
        .padding(.leading, 10)
        .padding(.trailing, 8)
        .background(isSelected ? Color.selectedTaskFill : Color.backlogCard, in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isSelected ? Color.task : Color.backlogCardBorder, lineWidth: isSelected ? 2 : 1)
        }
        .contentShape(.rect(cornerRadius: 8))
        .onTapGesture {
            selection.selectAndShowDetails(task.id)
        }
        .simultaneousGesture(
            TapGesture(count: 2).onEnded {
                selection.beginRenaming(task.id)
            }
        )
        .contextMenu {
            TaskContextMenu(task: task, model: model, selection: selection, undoManager: undoManager)
        }
        .taskKeyboardHandling(for: task)
        .taskDetailsPopover(for: task, arrowEdge: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(verbatim: task.title))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("backlog-task-\(task.title)")
    }

    private static func dueDateStyle(locale: Locale) -> Date.FormatStyle {
        Date.FormatStyle(locale: locale).weekday(.abbreviated).month(.abbreviated).day()
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
