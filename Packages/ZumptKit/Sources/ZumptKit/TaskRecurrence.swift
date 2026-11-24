import Foundation

/// Calendar dates are stored as Gregorian days at UTC midnight, independent of the display time zone.
public struct RecurrenceDay: Codable, Hashable, Comparable, Sendable {
    fileprivate let date: Date

    fileprivate static let calendar: Calendar = {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = .gmt
        calendar.firstWeekday = 2
        return calendar
    }()

    public init(_ localDate: Date, calendar: Calendar) {
        var local = Self.calendar
        local.timeZone = calendar.timeZone
        let components = local.dateComponents([.year, .month, .day], from: localDate)
        date = Self.calendar.date(from: components) ?? Self.calendar.startOfDay(for: localDate)
    }

    fileprivate init(utcDate: Date) {
        date = utcDate
    }

    public var weekday: Int {
        Self.calendar.component(.weekday, from: date)
    }

    public func localDate(in calendar: Calendar) -> Date {
        var local = Self.calendar
        local.timeZone = calendar.timeZone
        let components = Self.calendar.dateComponents([.year, .month, .day], from: date)
        return local.date(from: components) ?? date
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.date < rhs.date
    }
}

public struct OccurrencePlacement: Codable, Hashable, Sendable {
    public let day: RecurrenceDay
    public let minute: Int?

    public init(day: RecurrenceDay, minute: Int? = nil) {
        self.day = day
        self.minute = minute
    }

    public init(_ date: Date, allDay: Bool, calendar: Calendar) {
        day = RecurrenceDay(date, calendar: calendar)
        minute = allDay ? nil : calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
    }

    public func start(in calendar: Calendar) -> Date {
        let start = day.localDate(in: calendar)
        guard let minute else {
            return start
        }
        // Start just before midnight so midnight itself can match. Use the first valid time in a gap.
        let components = DateComponents(hour: minute / 60, minute: minute % 60, second: 0)
        return calendar.nextDate(
            after: start.addingTimeInterval(-1),
            matching: components,
            matchingPolicy: .nextTime,
            repeatedTimePolicy: .first
        ) ?? start
    }
}

public struct RecurrenceRule: Codable, Equatable, Sendable {
    public enum Frequency: String, CaseIterable, Identifiable, Codable, Sendable {
        case daily
        case weekly
        case monthly
        case yearly

        public var id: Self { self }
    }

    public let frequency: Frequency
    public let interval: Int
    public let firstDay: RecurrenceDay
    public let weekdays: Set<Int>
    public let weekStartsOn: Int
    public let minute: Int?
    public let endDay: RecurrenceDay?
    private let anchorDayOfMonth: Int

    public init?(
        frequency: Frequency,
        interval: Int,
        firstDay: RecurrenceDay,
        weekdays: Set<Int> = [],
        weekStartsOn: Int = 2,
        minute: Int? = nil,
        endDay: RecurrenceDay? = nil,
        preservingAnchorOf previousRule: RecurrenceRule? = nil
    ) {
        guard interval > 0,
            endDay.map({ $0 >= firstDay }) ?? true,
            minute.map({ (0..<(24 * 60)).contains($0) }) ?? true,
            weekdays.isSubset(of: 1...7),
            (1...7).contains(weekStartsOn),
            frequency != .weekly || !weekdays.isEmpty
        else {
            return nil
        }
        self.frequency = frequency
        self.interval = interval
        self.firstDay = firstDay
        self.weekdays = frequency == .weekly ? weekdays : []
        self.weekStartsOn = frequency == .weekly ? weekStartsOn : 2
        self.minute = minute
        self.endDay = endDay
        if let previousRule, previousRule.frequency == frequency, previousRule.includes(firstDay) {
            anchorDayOfMonth = previousRule.anchorDayOfMonth
        } else {
            anchorDayOfMonth = RecurrenceDay.calendar.component(.day, from: firstDay.date)
        }
    }

    func starting(on day: RecurrenceDay) -> RecurrenceRule? {
        RecurrenceRule(
            frequency: frequency, interval: interval, firstDay: day, weekdays: weekdays,
            weekStartsOn: weekStartsOn, minute: minute, endDay: endDay, preservingAnchorOf: self
        )
    }

    /// Every frequency but weekly starts on its first day; a weekly rule matches within its first two intervals.
    var firstOccurrence: RecurrenceDay? {
        (0..<(7 * (interval + 1))).lazy
            .compactMap { RecurrenceDay.calendar.date(byAdding: .day, value: $0, to: self.firstDay.date) }
            .map(RecurrenceDay.init(utcDate:))
            .first(where: includes)
    }

    public func includes(_ day: RecurrenceDay) -> Bool {
        guard day >= firstDay, endDay.map({ day <= $0 }) ?? true else {
            return false
        }
        let calendar = RecurrenceDay.calendar
        switch frequency {
        case .daily:
            let days = calendar.dateComponents([.day], from: firstDay.date, to: day.date).day ?? 0
            return days.isMultiple(of: interval)
        case .weekly:
            var calendar = calendar
            calendar.firstWeekday = weekStartsOn
            guard weekdays.contains(day.weekday),
                let firstWeek = calendar.dateInterval(of: .weekOfYear, for: firstDay.date),
                let week = calendar.dateInterval(of: .weekOfYear, for: day.date)
            else {
                return false
            }
            let weeks = calendar.dateComponents([.weekOfYear], from: firstWeek.start, to: week.start).weekOfYear ?? 0
            return weeks.isMultiple(of: interval)
        case .monthly, .yearly:
            let first = calendar.dateComponents([.year, .month], from: firstDay.date)
            let current = calendar.dateComponents([.year, .month, .day], from: day.date)
            guard let firstYear = first.year, let firstMonth = first.month,
                let year = current.year, let month = current.month,
                let daysInMonth = calendar.range(of: .day, in: .month, for: day.date)
            else {
                return false
            }
            if frequency == .yearly {
                guard month == firstMonth, (year - firstYear).isMultiple(of: interval) else {
                    return false
                }
            } else {
                let months = (year - firstYear) * 12 + month - firstMonth
                guard months.isMultiple(of: interval) else {
                    return false
                }
            }
            return current.day == min(anchorDayOfMonth, daysInMonth.count)
        }
    }
}

public struct TaskOccurrence: Codable, Hashable, Sendable {
    public let seriesID: UUID
    public let originalDay: RecurrenceDay

    public var id: UUID {
        // Pair the series UUID with the original day so projections have the same ID after reopening.
        let dayNumber = Int64(originalDay.date.timeIntervalSinceReferenceDate / 86_400)
        let bits = UInt64(bitPattern: dayNumber)
        var bytes = seriesID.uuid
        bytes.6 = (bytes.6 & 0x0F) | 0x80
        bytes.12 ^= UInt8(truncatingIfNeeded: bits >> 24)
        bytes.13 ^= UInt8(truncatingIfNeeded: bits >> 16)
        bytes.14 ^= UInt8(truncatingIfNeeded: bits >> 8)
        bytes.15 ^= UInt8(truncatingIfNeeded: bits)
        return UUID(uuid: bytes)
    }
}

public enum OccurrenceScope: Hashable, Sendable {
    case thisOccurrence
    case thisAndFollowing
}
