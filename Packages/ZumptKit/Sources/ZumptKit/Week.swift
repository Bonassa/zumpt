import Foundation

public struct Week: Hashable, Sendable {
    public let days: [Date]
    public let number: Int

    public init(containing date: Date, calendar: Calendar) {
        let firstDay = Self.firstDay(ofWeekContaining: date, calendar: calendar)
        days = (0..<7).map { offset in
            Self.day(offset, after: firstDay, calendar: calendar)
        }
        number = calendar.component(.weekOfYear, from: firstDay)
    }

    public var midweekDay: Date {
        days[3]
    }

    private static func firstDay(ofWeekContaining date: Date, calendar: Calendar) -> Date {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: date) else {
            preconditionFailure("Calendar could not resolve the week containing \(date)")
        }
        return interval.start
    }

    private static func day(_ offset: Int, after firstDay: Date, calendar: Calendar) -> Date {
        guard let day = calendar.date(byAdding: .day, value: offset, to: firstDay) else {
            preconditionFailure("Calendar could not add \(offset) days to \(firstDay)")
        }
        return day
    }
}
