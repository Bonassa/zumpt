import Foundation

public enum TimedItem: Hashable, Sendable {
    case event(CalendarEvent)
    case task(TaskItem)

    public var id: String {
        switch self {
        case .event(let event): "event-\(event.id)"
        case .task(let task): "task-\(task.id.uuidString)"
        }
    }

    public var title: String {
        switch self {
        case .event(let event): event.title
        case .task(let task): task.title
        }
    }
}

public struct PositionedItem: Hashable, Sendable {
    public let item: TimedItem
    public let startMinute: Int
    public let endMinute: Int
    public let column: Int
    public let columnSpan: Int
    public let columnCount: Int
}

public enum DayLayout {
    public static let minutesPerDay = 24 * 60
    public static let minimumDurationInMinutes = 15

    public static func allDayEvents(_ events: [CalendarEvent], on day: Date, calendar: Calendar) -> [CalendarEvent] {
        let interval = dayInterval(containing: day, calendar: calendar)
        return
            events
            .filter { $0.isAllDay && overlaps($0, interval) }
            .sorted { ($0.start, $0.title, $0.id) < ($1.start, $1.title, $1.id) }
    }

    public static func timedItems(
        events: [CalendarEvent],
        tasks: [TaskItem],
        on day: Date,
        calendar: Calendar
    ) -> [PositionedItem] {
        let interval = dayInterval(containing: day, calendar: calendar)
        let eventSpans =
            events
            .filter { !$0.isAllDay && overlaps($0, interval) }
            .map { span(of: .event($0), from: $0.start, to: $0.end, within: interval, calendar: calendar) }
        let taskSpans = tasks.compactMap { task -> Span? in
            guard let start = task.scheduledStart, let end = task.scheduledEnd,
                overlaps(start: start, end: end, interval)
            else {
                return nil
            }
            return span(of: .task(task), from: start, to: end, within: interval, calendar: calendar)
        }
        return clusters(of: (eventSpans + taskSpans).sorted(by: isPlacedBefore)).flatMap(assignColumns)
    }

    private struct Span {
        let item: TimedItem
        let startMinute: Int
        let endMinute: Int
    }

    private static func dayInterval(containing day: Date, calendar: Calendar) -> DateInterval {
        guard let interval = calendar.dateInterval(of: .day, for: day) else {
            preconditionFailure("Calendar could not resolve the day containing \(day)")
        }
        return interval
    }

    private static func overlaps(_ event: CalendarEvent, _ interval: DateInterval) -> Bool {
        overlaps(start: event.start, end: event.end, interval)
    }

    private static func overlaps(start: Date, end: Date, _ interval: DateInterval) -> Bool {
        start < interval.end && (end > interval.start || start >= interval.start)
    }

    private static func span(
        of item: TimedItem,
        from start: Date,
        to end: Date,
        within day: DateInterval,
        calendar: Calendar
    ) -> Span {
        let startMinute = start <= day.start ? 0 : minutesSinceStartOfDay(start, calendar: calendar)
        let endMinute = end >= day.end ? minutesPerDay : minutesSinceStartOfDay(end, calendar: calendar)
        let paddedEndMinute = min(minutesPerDay, max(endMinute, startMinute + minimumDurationInMinutes))
        return Span(item: item, startMinute: startMinute, endMinute: paddedEndMinute)
    }

    private static func minutesSinceStartOfDay(_ date: Date, calendar: Calendar) -> Int {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    private static func isPlacedBefore(_ lhs: Span, _ rhs: Span) -> Bool {
        if lhs.startMinute != rhs.startMinute {
            return lhs.startMinute < rhs.startMinute
        }
        if lhs.endMinute != rhs.endMinute {
            return lhs.endMinute > rhs.endMinute
        }
        return (lhs.item.title, lhs.item.id) < (rhs.item.title, rhs.item.id)
    }

    private static func clusters(of spans: [Span]) -> [[Span]] {
        var clusters: [[Span]] = []
        var clusterEndMinute = Int.min
        for span in spans {
            if span.startMinute >= clusterEndMinute || clusters.isEmpty {
                clusters.append([span])
            } else {
                clusters[clusters.count - 1].append(span)
            }
            clusterEndMinute = max(clusterEndMinute, span.endMinute)
        }
        return clusters
    }

    private static func assignColumns(_ cluster: [Span]) -> [PositionedItem] {
        var columnEndMinutes: [Int] = []
        var columns: [Int] = []
        for span in cluster {
            if let freeColumn = columnEndMinutes.firstIndex(where: { $0 <= span.startMinute }) {
                columnEndMinutes[freeColumn] = span.endMinute
                columns.append(freeColumn)
            } else {
                columnEndMinutes.append(span.endMinute)
                columns.append(columnEndMinutes.count - 1)
            }
        }
        let placed = Array(zip(cluster, columns))
        let columnCount = columnEndMinutes.count
        return placed.map { span, column in
            PositionedItem(
                item: span.item,
                startMinute: span.startMinute,
                endMinute: span.endMinute,
                column: column,
                columnSpan: freeColumnSpan(of: span, from: column, among: placed, columnCount: columnCount),
                columnCount: columnCount
            )
        }
    }

    private static func freeColumnSpan(
        of span: Span,
        from column: Int,
        among placed: [(Span, Int)],
        columnCount: Int
    ) -> Int {
        var columnSpan = 1
        for nextColumn in (column + 1)..<max(columnCount, column + 1) {
            let isTaken = placed.contains { other, otherColumn in
                otherColumn == nextColumn
                    && other.startMinute < span.endMinute
                    && span.startMinute < other.endMinute
            }
            if isTaken {
                break
            }
            columnSpan += 1
        }
        return columnSpan
    }
}
