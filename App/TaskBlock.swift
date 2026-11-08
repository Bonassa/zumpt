import SwiftUI
import ZumptKit

struct TaskBlock: View {
    let task: TaskItem

    @Environment(\.locale) private var locale

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .strokeBorder(Color.task, lineWidth: 1.5)
                .frame(width: 12, height: 12)
                .accessibilityHidden(true)
            Text(verbatim: task.title)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)
        }
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.taskBlockFill, in: .rect(cornerRadius: 6))
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Color.task, lineWidth: 1.5)
        }
        .clipShape(.rect(cornerRadius: 6))
        .shadow(color: .black.opacity(0.08), radius: 1, y: 1)
        .contentShape(.rect(cornerRadius: 6))
        .draggable(TaskDragItem(id: task.id))
        .help(Text(verbatim: "\(task.title) · \(timeRange)"))
        .accessibilityElement(children: .ignore)
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
