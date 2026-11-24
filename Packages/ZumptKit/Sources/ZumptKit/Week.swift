import Foundation

public struct Week: Hashable, Sendable {
    public let days: [Date]
    public let number: Int

    private static let dayCount = 5
    private static let sunday = 1
    private static let monday = 2
    private static let saturday = 7

    public init(containing date: Date, calendar: Calendar) {
        let monday = Self.monday(ofWeekShowing: date, calendar: calendar)
        days = (0..<Self.dayCount).map { offset in
            Self.day(offset, after: monday, calendar: calendar)
        }
        number = calendar.component(.weekOfYear, from: monday)
    }

    public var midweekDay: Date {
        days[days.count / 2]
    }

    public func interval(in calendar: Calendar) -> DateInterval {
        DateInterval(start: days[0], end: Self.day(days.count, after: days[0], calendar: calendar))
    }

    public func contains(_ date: Date, calendar: Calendar) -> Bool {
        let interval = interval(in: calendar)
        return date >= interval.start && date < interval.end
    }

    public func adding(weeks: Int, calendar: Calendar) -> Week {
        Week(containing: Self.day(weeks * 7, after: days[0], calendar: calendar), calendar: calendar)
    }

    private static func monday(ofWeekShowing date: Date, calendar: Calendar) -> Date {
        let weekday = calendar.component(.weekday, from: date)
        let offset =
            switch weekday {
            case sunday: 1
            case saturday: 2
            default: monday - weekday
            }
        return day(offset, after: date, calendar: calendar)
    }

    private static func day(_ offset: Int, after date: Date, calendar: Calendar) -> Date {
        guard let day = calendar.date(byAdding: .day, value: offset, to: date) else {
            preconditionFailure("Calendar could not add \(offset) days to \(date)")
        }
        return calendar.startOfDay(for: day)
    }
}
