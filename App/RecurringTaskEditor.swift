import SwiftUI
import ZumptKit

struct TaskEditorRequest: Identifiable {
    enum Action {
        case repetition
        case reschedule
        case rename
        case delete
    }

    let task: TaskItem
    let action: Action

    var id: UUID { task.id }
}

struct RecurringTaskEditor: View {
    let request: TaskEditorRequest
    let model: TaskModel
    let undoManager: UndoManager?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        switch request.action {
        case .repetition:
            RepetitionEditor(task: request.task, model: model, undoManager: undoManager)
        case .reschedule:
            OccurrenceDateEditor(task: request.task, model: model, undoManager: undoManager)
        case .rename, .delete:
            OccurrenceScopeEditor(task: request.task, deleting: request.action == .delete) { title, scope in
                if request.action == .delete {
                    model.delete(request.task, scope: scope, undoManager: undoManager)
                } else {
                    model.rename(request.task, to: title, scope: scope, undoManager: undoManager)
                }
                dismiss()
            }
        }
    }
}

private struct RepetitionEditor: View {
    let task: TaskItem
    let model: TaskModel
    let undoManager: UndoManager?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale

    @State private var frequency: RecurrenceRule.Frequency
    @State private var interval: String
    @State private var firstDate: Date
    @State private var weekdays: Set<Int>
    @State private var hasTime: Bool
    @State private var time: Date
    @State private var hasEndDate: Bool
    @State private var endDate: Date

    private let previousRule: RecurrenceRule?
    private let originalDay: RecurrenceDay?

    init(task: TaskItem, model: TaskModel, undoManager: UndoManager?) {
        self.task = task
        self.model = model
        self.undoManager = undoManager
        let calendar = model.calendar
        let previous = task.occurrence.flatMap { model.rule(for: $0) }
        let original = task.occurrence?.originalDay
        let first = original?.localDate(in: calendar) ?? task.scheduledStart ?? model.now()
        let proposedTime =
            previous?.minute
            ?? task.scheduledStart.map {
                calendar.component(.hour, from: $0) * 60 + calendar.component(.minute, from: $0)
            }
        // Use an ordinary reference day so a DST gap on the first date cannot rewrite the desired time.
        let referenceDate = calendar.date(from: DateComponents(year: 2001, month: 1, day: 15)) ?? first
        let referenceDay = RecurrenceDay(referenceDate, calendar: calendar)
        previousRule = previous
        originalDay = original
        _frequency = State(initialValue: previous?.frequency ?? .daily)
        _interval = State(initialValue: String(previous?.interval ?? 1))
        _firstDate = State(initialValue: first)
        _weekdays = State(initialValue: previous?.weekdays ?? [])
        _hasTime = State(
            initialValue: previous.map { $0.minute != nil } ?? (task.scheduledStart != nil && !task.isAllDay))
        _time = State(
            initialValue: OccurrencePlacement(day: referenceDay, minute: proposedTime ?? 9 * 60).start(in: calendar))
        _hasEndDate = State(initialValue: previous?.endDay != nil)
        _endDate = State(initialValue: previous?.endDay?.localDate(in: calendar) ?? first)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(task.occurrence == nil ? "Set Repetition" : "Edit Repetition")
                .font(.headline)
            if task.occurrence != nil {
                Text("Changes apply to this occurrence and following unfinished occurrences.")
                    .foregroundStyle(.secondary)
            }
            Form {
                Picker("Repeat", selection: $frequency) {
                    ForEach(RecurrenceRule.Frequency.allCases) { frequency in
                        Text(frequency.label).tag(frequency)
                    }
                }
                TextField("Interval", text: $interval)
                    .accessibilityIdentifier("recurrence-interval")
                DatePicker("First date", selection: $firstDate, displayedComponents: .date)
                    .accessibilityIdentifier("recurrence-first-date")
                if frequency == .weekly {
                    LabeledContent("Weekdays") {
                        HStack(spacing: 4) {
                            ForEach(orderedWeekdays, id: \.self) { weekday in
                                Toggle(isOn: weekdayBinding(weekday)) {
                                    Text(verbatim: weekdaySymbols.shortStandaloneWeekdaySymbols[weekday - 1])
                                }
                                .toggleStyle(.button)
                                .help(Text(verbatim: weekdaySymbols.standaloneWeekdaySymbols[weekday - 1]))
                            }
                        }
                    }
                }
                Toggle("Set a time", isOn: $hasTime)
                if hasTime {
                    DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                }
                Toggle("End repetition", isOn: $hasEndDate)
                if hasEndDate {
                    DatePicker("End date", selection: $endDate, displayedComponents: .date)
                }
            }
            if let validationMessage {
                Text(validationMessage)
                    .foregroundStyle(Color.overdue)
            }
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Save") {
                    if let rule {
                        model.setRule(rule, for: task, undoManager: undoManager)
                        dismiss()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(rule == nil)
                .accessibilityIdentifier("recurrence-save")
            }
        }
        .padding(20)
        .frame(width: 490)
    }

    private var firstDay: RecurrenceDay {
        RecurrenceDay(firstDate, calendar: model.calendar)
    }

    private var endDay: RecurrenceDay? {
        hasEndDate ? RecurrenceDay(endDate, calendar: model.calendar) : nil
    }

    private var effectiveWeekdays: Set<Int> {
        // An untouched weekly rule starts on the first date's weekday.
        weekdays.isEmpty ? [firstDay.weekday] : weekdays
    }

    private var validationMessage: LocalizedStringResource? {
        if (Int(interval.trimmingCharacters(in: .whitespaces)) ?? 0) <= 0 {
            return "Enter a positive whole number for the interval."
        }
        if let originalDay, firstDay < originalDay {
            return "Choose a first date on or after the original occurrence date."
        }
        if let endDay, endDay < firstDay {
            return "Choose an end date on or after the first date."
        }
        return nil
    }

    private var rule: RecurrenceRule? {
        guard validationMessage == nil, let interval = Int(interval.trimmingCharacters(in: .whitespaces)) else {
            return nil
        }
        let placement = OccurrencePlacement(time, allDay: !hasTime, calendar: model.calendar)
        let weeklyRule = previousRule.flatMap { $0.frequency == .weekly ? $0 : nil }
        return RecurrenceRule(
            frequency: frequency, interval: interval, firstDay: firstDay, weekdays: effectiveWeekdays,
            weekStartsOn: weeklyRule?.weekStartsOn ?? model.calendar.firstWeekday,
            minute: placement.minute, endDay: endDay,
            preservingAnchorOf: firstDay == originalDay ? previousRule : nil
        )
    }

    private var weekdaySymbols: Calendar {
        var calendar = model.calendar
        calendar.locale = locale
        return calendar
    }

    private var orderedWeekdays: [Int] {
        (0..<7).map { (weekdaySymbols.firstWeekday - 1 + $0) % 7 + 1 }
    }

    private func weekdayBinding(_ weekday: Int) -> Binding<Bool> {
        Binding(
            get: { effectiveWeekdays.contains(weekday) },
            set: { selected in
                var updated = effectiveWeekdays
                if selected {
                    updated.insert(weekday)
                } else if updated.count > 1 {
                    updated.remove(weekday)
                }
                weekdays = updated
            }
        )
    }
}

private struct OccurrenceDateEditor: View {
    let task: TaskItem
    let model: TaskModel
    let undoManager: UndoManager?

    @Environment(\.dismiss) private var dismiss
    @State private var date: Date
    @State private var hasTime: Bool

    init(task: TaskItem, model: TaskModel, undoManager: UndoManager?) {
        self.task = task
        self.model = model
        self.undoManager = undoManager
        _date = State(initialValue: task.scheduledStart ?? model.now())
        _hasTime = State(initialValue: !task.isAllDay)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Reschedule Occurrence")
                .font(.headline)
            Form {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                Toggle("Set a time", isOn: $hasTime)
                if hasTime {
                    DatePicker("Time", selection: $date, displayedComponents: .hourAndMinute)
                }
            }
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Save") {
                    model.move(TaskDragItem(task: task), to: date, allDay: !hasTime, undoManager: undoManager)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 360)
    }
}

private struct OccurrenceScopeEditor: View {
    let task: TaskItem
    let deleting: Bool
    let apply: (String, OccurrenceScope) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var scope: OccurrenceScope = .thisOccurrence

    init(task: TaskItem, deleting: Bool, apply: @escaping (String, OccurrenceScope) -> Void) {
        self.task = task
        self.deleting = deleting
        self.apply = apply
        _title = State(initialValue: task.title)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(deleting ? "Delete Task" : "Rename Task")
                .font(.headline)
            if deleting {
                Text(verbatim: task.title)
            } else {
                TextField("Title", text: $title)
                    .accessibilityIdentifier("occurrence-title")
            }
            Picker("Apply to", selection: $scope) {
                Text("This occurrence").tag(OccurrenceScope.thisOccurrence)
                Text("This and following").tag(OccurrenceScope.thisAndFollowing)
            }
            .pickerStyle(.radioGroup)
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(deleting ? "Delete" : "Rename", role: deleting ? .destructive : nil) {
                    apply(title, scope)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!deleting && TaskTitle.normalized(title) == nil)
                .accessibilityIdentifier("occurrence-scope-apply")
            }
        }
        .padding(20)
        .frame(width: 360)
    }
}

extension RecurrenceRule.Frequency {
    var label: LocalizedStringResource {
        switch self {
        case .daily: "Daily"
        case .weekly: "Weekly"
        case .monthly: "Monthly"
        case .yearly: "Yearly"
        }
    }
}
