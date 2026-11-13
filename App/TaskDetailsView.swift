import SwiftUI
import ZumptKit

struct TaskDetailsView: View {
    let task: TaskItem

    @Environment(TaskModel.self) private var model
    @Environment(TaskSelection.self) private var selection
    @Environment(\.undoManager) private var undoManager
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                CompletionButton(task: task, size: 16)
                    .padding(.top, 2)
                VStack(alignment: .leading, spacing: 4) {
                    Text(verbatim: task.title)
                        .font(.system(size: 15, weight: .semibold))
                        .strikethrough(task.isDone)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                        .accessibilityIdentifier("task-details-title")
                    Text(timeText)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("task-details-time")
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                if let completedAt = task.completedAt {
                    DetailRow(systemImage: "checkmark.circle.fill", iconColor: .task) {
                        Text("Completed \(moment(completedAt))")
                    }
                    .accessibilityIdentifier("task-details-status")
                } else if task.isOverdue, let missedStart = task.missedStart {
                    DetailRow(systemImage: "exclamationmark.circle.fill", iconColor: .overdue) {
                        Text("Overdue since \(moment(missedStart))")
                            .foregroundStyle(Color.overdue)
                    }
                    .accessibilityIdentifier("task-details-status")
                }
                DetailRow(systemImage: "clock") {
                    Text("Created \(moment(task.createdAt))")
                        .foregroundStyle(.secondary)
                }
                .accessibilityIdentifier("task-details-created")
            }

            Divider()

            HStack {
                Button("Rename", systemImage: "pencil") {
                    selection.renameAfterClosingDetails(task.id)
                }
                .accessibilityIdentifier("task-details-rename")
                Spacer(minLength: 0)
                Button("Delete", systemImage: "trash", role: .destructive) {
                    selection.clear()
                    model.delete(task.id, undoManager: undoManager)
                }
                .keyboardShortcut(.delete, modifiers: [])
                .accessibilityIdentifier("task-details-delete")
            }
            .buttonStyle(.borderless)
        }
        .font(.system(size: 12.5))
        .padding(16)
        .frame(width: 340, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("task-details")
        .onDisappear(perform: selection.detailsDidClose)
    }

    private var timeText: String {
        guard let start = task.scheduledStart else {
            return String(localized: "No time · In the backlog")
        }
        let dayStyle = Date.FormatStyle(locale: locale).weekday(.wide).day().month(.wide)
        let day = EventDetailsView.capitalizingFirstLetter(of: start.formatted(dayStyle), locale: locale)
        return "\(day) · \(TaskBlock.timeRange(from: start, locale: locale))"
    }

    private func moment(_ date: Date) -> String {
        date.formatted(
            Date.FormatStyle(locale: locale).weekday(.abbreviated).day().month(.abbreviated).hour().minute()
        )
    }
}

extension View {
    func taskDetailsPopover(for task: TaskItem, arrowEdge: Edge) -> some View {
        modifier(TaskDetailsPopover(task: task, arrowEdge: arrowEdge))
    }
}

private struct TaskDetailsPopover: ViewModifier {
    let task: TaskItem
    let arrowEdge: Edge

    @Environment(TaskSelection.self) private var selection
    @Environment(\.locale) private var locale

    func body(content: Content) -> some View {
        content.popover(isPresented: isPresented, arrowEdge: arrowEdge) {
            TaskDetailsView(task: task)
                .environment(\.locale, locale)
        }
    }

    private var isPresented: Binding<Bool> {
        Binding(
            get: { selection.detailsID == task.id },
            set: { isPresented in
                if !isPresented, selection.detailsID == task.id {
                    selection.closeDetails()
                }
            }
        )
    }
}
