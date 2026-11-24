import SwiftUI
import ZumptKit

struct TaskBlock: View {
    let task: TaskItem

    @Environment(TaskModel.self) private var model
    @Environment(TaskSelection.self) private var selection
    @Environment(\.undoManager) private var undoManager
    @Environment(\.locale) private var locale

    private static let completionAreaWidth: CGFloat = 22

    var body: some View {
        let isSelected = selection.selectedID == task.id
        let font = Font.system(size: 11, weight: task.isDone ? .medium : .semibold)
        HStack(spacing: 5) {
            CompletionButton(task: task, size: 12)
            if task.isOverdue {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.overdue)
                    .accessibilityHidden(true)
            }
            if selection.renamingID == task.id {
                TaskTitleField(task: task, font: font)
            } else {
                Text(verbatim: task.title)
                    .font(font)
                    .strikethrough(task.isDone)
                    .foregroundStyle(task.isDone ? .secondary : .primary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(fill(isSelected: isSelected), in: .rect(cornerRadius: 6))
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(
                    borderColor(isSelected: isSelected), lineWidth: isSelected ? 2 : 1.5)
        }
        .clipShape(.rect(cornerRadius: 6))
        .shadow(color: .black.opacity(task.isDone ? 0 : 0.08), radius: 1, y: 1)
        .contentShape(.rect(cornerRadius: 6))
        .onTapGesture(coordinateSpace: .local) { location in
            // Buttons nested in the scrolled week grid miss clicks, so the block routes clicks on the circle.
            if location.x <= Self.completionAreaWidth {
                model.toggleCompletion(task, undoManager: undoManager)
            } else {
                selection.selectAndShowDetails(task.id)
            }
        }
        .simultaneousGesture(
            SpatialTapGesture(count: 2, coordinateSpace: .local).onEnded { value in
                if value.location.x > Self.completionAreaWidth {
                    selection.requestRename(task)
                }
            }
        )
        .contextMenu {
            TaskContextMenu(task: task, model: model, selection: selection, undoManager: undoManager)
        }
        .taskDraggable(task)
        .taskKeyboardHandling(for: task)
        .taskDetailsPopover(for: task, arrowEdge: .trailing)
        .help(Text(verbatim: summary))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(verbatim: summary))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("task-\(task.title)")
    }

    private func fill(isSelected: Bool) -> Color {
        if isSelected {
            return .selectedTaskFill
        }
        return task.isDone ? .doneTaskFill : .taskBlockFill
    }

    private func borderColor(isSelected: Bool) -> Color {
        if isSelected {
            return .task
        }
        if task.isOverdue {
            return .overdue
        }
        return task.isDone ? .doneTaskBorder : .task
    }

    private var summary: String {
        let schedule =
            task.isAllDay
            ? String(localized: "All day")
            : task.scheduledStart.map { Self.timeRange(from: $0, locale: locale) } ?? ""
        return task.isOverdue
            ? String(localized: "\(task.title), \(schedule), Overdue")
            : "\(task.title), \(schedule)"
    }

    static func timeRange(from start: Date, locale: Locale) -> String {
        let end = start.addingTimeInterval(TimeInterval(TaskItem.durationInMinutes * 60))
        return (start..<end).formatted(Date.IntervalFormatStyle(date: .omitted, time: .shortened, locale: locale))
    }
}

struct CompletionButton: View {
    let task: TaskItem
    let size: CGFloat

    @Environment(TaskModel.self) private var model
    @Environment(\.undoManager) private var undoManager

    var body: some View {
        Button {
            model.toggleCompletion(task, undoManager: undoManager)
        } label: {
            ZStack {
                if task.isDone {
                    Circle()
                        .fill(Color.task)
                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.55, weight: .heavy))
                        .foregroundStyle(.white)
                } else {
                    Circle()
                        .strokeBorder(Color.task, lineWidth: 1.5)
                }
            }
            .frame(width: size, height: size)
            .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .help(task.isDone ? Text("Reopen") : Text("Complete"))
        .accessibilityLabel(task.isDone ? Text("Reopen \(task.title)") : Text("Complete \(task.title)"))
        .accessibilityIdentifier("complete-\(task.title)")
    }
}
