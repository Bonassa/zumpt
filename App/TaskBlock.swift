import SwiftUI
import ZumptKit

struct TaskBlock: View {
    let task: TaskItem

    @Environment(TaskModel.self) private var model
    @Environment(\.undoManager) private var undoManager
    @Environment(\.locale) private var locale

    private static let completionAreaWidth: CGFloat = 22

    var body: some View {
        HStack(spacing: 5) {
            CompletionButton(task: task, size: 12)
            Text(verbatim: task.title)
                .font(.system(size: 11, weight: task.isDone ? .medium : .semibold))
                .strikethrough(task.isDone)
                .foregroundStyle(task.isDone ? .secondary : .primary)
                .lineLimit(1)
        }
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(task.isDone ? Color.doneTaskFill : Color.taskBlockFill, in: .rect(cornerRadius: 6))
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(task.isDone ? Color.doneTaskBorder : Color.task, lineWidth: 1.5)
        }
        .clipShape(.rect(cornerRadius: 6))
        .shadow(color: .black.opacity(task.isDone ? 0 : 0.08), radius: 1, y: 1)
        .contentShape(.rect(cornerRadius: 6))
        .onTapGesture(coordinateSpace: .local) { location in
            // Buttons nested in the scrolled week grid miss clicks, so the block routes clicks on the circle.
            if location.x <= Self.completionAreaWidth {
                model.toggleCompletion(task.id, undoManager: undoManager)
            }
        }
        .draggable(TaskDragItem(id: task.id))
        .help(Text(verbatim: "\(task.title) · \(timeRange)"))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(verbatim: "\(task.title), \(timeRange)"))
        .accessibilityIdentifier("task-\(task.title)")
    }

    private var timeRange: String {
        task.scheduledStart.map { Self.timeRange(from: $0, locale: locale) } ?? ""
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
            model.toggleCompletion(task.id, undoManager: undoManager)
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
