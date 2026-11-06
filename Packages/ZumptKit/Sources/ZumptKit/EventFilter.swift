import Foundation

public enum EventFilter {
    public static func visible(
        _ events: [CalendarEvent],
        hiddenCalendarIDs: Set<String>,
        calendarOrder: [String]
    ) -> [CalendarEvent] {
        let shown = events.filter { !$0.isDeclined && !hiddenCalendarIDs.contains($0.calendarID) }
        return mergingCopies(of: shown, calendarOrder: calendarOrder)
    }

    private struct MeetingKey: Hashable {
        let title: String
        let start: Date
        let end: Date
        let isAllDay: Bool
    }

    private static let forwardPrefix = #"^\s*(fwd?|enc)\s*:\s*"#

    private static func mergingCopies(of events: [CalendarEvent], calendarOrder: [String]) -> [CalendarEvent] {
        let rank = Dictionary(calendarOrder.enumerated().map { ($1, $0) }, uniquingKeysWith: { first, _ in first })
        let byCalendarOrder = events.enumerated().sorted { lhs, rhs in
            let lhsRank = rank[lhs.element.calendarID] ?? Int.max
            let rhsRank = rank[rhs.element.calendarID] ?? Int.max
            return lhsRank != rhsRank ? lhsRank < rhsRank : lhs.offset < rhs.offset
        }

        var calendarIDsByMeeting: [MeetingKey: String] = [:]
        var kept: [CalendarEvent] = []
        for (_, event) in byCalendarOrder {
            let key = MeetingKey(
                title: meetingTitle(of: event.title),
                start: event.start,
                end: event.end,
                isAllDay: event.isAllDay
            )
            if let keptCalendarID = calendarIDsByMeeting[key], keptCalendarID != event.calendarID {
                continue
            }
            calendarIDsByMeeting[key] = event.calendarID
            kept.append(event)
        }
        return kept
    }

    private static func meetingTitle(of title: String) -> String {
        var result = title
        while let prefix = result.range(of: forwardPrefix, options: [.regularExpression, .caseInsensitive]) {
            result.removeSubrange(prefix)
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
