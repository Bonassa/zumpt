import Foundation

public struct TaskSeries: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    private let createdAt: Date
    private let initialTitle: String
    private var schedules: [Schedule]
    private var titleChanges: [TitleChange] = []
    private var exceptions: [RecurrenceDay: Exception] = [:]

    private struct Schedule: Codable, Equatable {
        let rule: RecurrenceRule
        var before: RecurrenceDay?

        func includes(_ day: RecurrenceDay) -> Bool {
            (before.map { day < $0 } ?? true) && rule.includes(day)
        }

        var hasOccurrences: Bool {
            rule.firstOccurrence.map(includes) ?? false
        }
    }

    private struct TitleChange: Codable, Equatable {
        let day: RecurrenceDay
        let title: String
    }

    private struct Exception: Codable, Equatable {
        var title: String?
        var placement: OccurrencePlacement?
        var completion: Completion?
        var isDeleted = false
    }

    private struct Completion: Codable, Equatable {
        let date: Date
        var title: String
        var placement: OccurrencePlacement
    }

    public init(task: TaskItem, rule: RecurrenceRule, calendar: Calendar) {
        id = task.id
        createdAt = task.createdAt
        initialTitle = task.title
        schedules = [Schedule(rule: rule)]
        if let completedAt = task.completedAt, let start = task.scheduledStart {
            let placement = OccurrencePlacement(start, allDay: false, calendar: calendar)
            exceptions[placement.day] = Exception(
                completion: Completion(date: completedAt, title: task.title, placement: placement))
        }
    }

    public func rule(on originalDay: RecurrenceDay) -> RecurrenceRule? {
        schedules.last { $0.includes(originalDay) }?.rule
    }

    public var isEmpty: Bool {
        schedules.isEmpty && exceptions.keys.allSatisfy { placement(on: $0) == nil }
    }

    public func tasks(on days: [RecurrenceDay], now: Date, calendar: Calendar) -> [TaskItem] {
        let visibleDays = Set(days)
        let movedIntoRange = exceptions.compactMap { day, exception in
            exception.placement.map { visibleDays.contains($0.day) } == true ? day : nil
        }
        return visibleDays.union(movedIntoRange).sorted().compactMap { day in
            guard let placement = placement(on: day), visibleDays.contains(placement.day) else {
                return nil
            }
            return task(on: day, now: now, calendar: calendar)
        }
    }

    public func task(on originalDay: RecurrenceDay, now: Date, calendar: Calendar) -> TaskItem? {
        guard let placement = placement(on: originalDay) else {
            return nil
        }
        let occurrence = TaskOccurrence(seriesID: id, originalDay: originalDay)
        let start = placement.start(in: calendar)
        let completedAt = exceptions[originalDay]?.completion?.date
        let overdue = completedAt == nil && placement.day < RecurrenceDay(now, calendar: calendar)
        return TaskItem(
            id: occurrence.id, title: title(on: originalDay), createdAt: createdAt,
            scheduledStart: start, completedAt: completedAt, missedStart: overdue ? start : nil,
            occurrence: occurrence, isAllDay: placement.minute == nil
        )
    }

    public func placement(on day: RecurrenceDay) -> OccurrencePlacement? {
        if let exception = exceptions[day] {
            guard !exception.isDeleted else {
                return nil
            }
            if let placement = exception.completion?.placement ?? exception.placement {
                return placement
            }
        }
        return rule(on: day).map { OccurrencePlacement(day: day, minute: $0.minute) }
    }

    public mutating func move(_ day: RecurrenceDay, to placement: OccurrencePlacement) {
        guard let current = self.placement(on: day), current != placement else {
            return
        }
        exceptions[day, default: Exception()].placement = placement
        exceptions[day]?.completion?.placement = placement
    }

    public mutating func toggleCompletion(on day: RecurrenceDay, now: Date) {
        guard let placement = placement(on: day) else {
            return
        }
        if exceptions[day]?.completion != nil {
            exceptions[day]?.completion = nil
            if exceptions[day]?.placement == nil, rule(on: day) == nil {
                exceptions[day]?.placement = placement
            }
            if exceptions[day] == Exception() {
                exceptions[day] = nil
            }
        } else {
            exceptions[day, default: Exception()].completion = Completion(
                date: now, title: title(on: day), placement: placement)
        }
    }

    public mutating func rename(on day: RecurrenceDay, to text: String, scope: OccurrenceScope) {
        guard placement(on: day) != nil, let title = TaskTitle.normalized(text) else {
            return
        }
        switch scope {
        case .thisOccurrence:
            guard title != self.title(on: day) else {
                return
            }
            exceptions[day, default: Exception()].title = title
            exceptions[day]?.completion?.title = title
        case .thisAndFollowing:
            titleChanges.removeAll { $0.day >= day }
            titleChanges.append(TitleChange(day: day, title: title))
            for key in Array(exceptions.keys) where key >= day && exceptions[key]?.completion == nil {
                exceptions[key]?.title = nil
            }
        }
    }

    public mutating func delete(on day: RecurrenceDay, scope: OccurrenceScope) {
        guard placement(on: day) != nil else {
            return
        }
        switch scope {
        case .thisOccurrence:
            exceptions[day] = Exception(isDeleted: true)
        case .thisAndFollowing:
            truncateSchedules(before: day)
            exceptions = exceptions.filter { $0.key < day || $0.value.completion != nil }
        }
    }

    public mutating func changeRule(from day: RecurrenceDay, to rule: RecurrenceRule) {
        guard placement(on: day) != nil, rule.firstDay >= day, self.rule(on: day)?.starting(on: day) != rule else {
            return
        }
        truncateSchedules(before: day)
        schedules.append(Schedule(rule: rule))
        exceptions = exceptions.filter { $0.key < day || $0.value.completion != nil || rule.includes($0.key) }
    }

    private func title(on day: RecurrenceDay) -> String {
        exceptions[day]?.completion?.title ?? exceptions[day]?.title ?? seriesTitle(on: day)
    }

    private func seriesTitle(on day: RecurrenceDay) -> String {
        titleChanges.last { $0.day <= day }?.title ?? initialTitle
    }

    private mutating func truncateSchedules(before day: RecurrenceDay) {
        schedules.removeAll { $0.rule.firstDay >= day }
        if let last = schedules.indices.last, schedules[last].before.map({ $0 > day }) ?? true {
            schedules[last].before = day
        }
        schedules.removeAll { !$0.hasOccurrences }
    }
}
