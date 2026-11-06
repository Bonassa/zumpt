import Foundation

public struct PositionedEvent: Hashable, Sendable {
    public let event: CalendarEvent
    public let startMinute: Int
    public let endMinute: Int
    public let column: Int
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

    public static func timedEvents(_ events: [CalendarEvent], on day: Date, calendar: Calendar) -> [PositionedEvent] {
        let interval = dayInterval(containing: day, calendar: calendar)
        let spans =
            events
            .filter { !$0.isAllDay && overlaps($0, interval) }
            .map { span(of: $0, within: interval, calendar: calendar) }
            .sorted(by: isPlacedBefore)
        return clusters(of: spans).flatMap(assignColumns)
    }

    private struct Span {
        let event: CalendarEvent
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
        event.start < interval.end && (event.end > interval.start || event.start >= interval.start)
    }

    private static func span(of event: CalendarEvent, within day: DateInterval, calendar: Calendar) -> Span {
        let startMinute = event.start <= day.start ? 0 : minutesSinceStartOfDay(event.start, calendar: calendar)
        let endMinute = event.end >= day.end ? minutesPerDay : minutesSinceStartOfDay(event.end, calendar: calendar)
        let paddedEndMinute = min(minutesPerDay, max(endMinute, startMinute + minimumDurationInMinutes))
        return Span(event: event, startMinute: startMinute, endMinute: paddedEndMinute)
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
        return (lhs.event.title, lhs.event.id) < (rhs.event.title, rhs.event.id)
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

    private static func assignColumns(_ cluster: [Span]) -> [PositionedEvent] {
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
        return zip(cluster, columns).map { span, column in
            PositionedEvent(
                event: span.event,
                startMinute: span.startMinute,
                endMinute: span.endMinute,
                column: column,
                columnCount: columnEndMinutes.count
            )
        }
    }
}
