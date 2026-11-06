import Foundation
import Testing
import ZumptKit

func makeCalendar(firstWeekday: Int = 1, timeZone: String = "America/Sao_Paulo") throws -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = Locale(identifier: "pt_BR")
    calendar.timeZone = try #require(TimeZone(identifier: timeZone))
    calendar.firstWeekday = firstWeekday
    calendar.minimumDaysInFirstWeek = 1
    return calendar
}

func date(
    _ year: Int,
    _ month: Int,
    _ day: Int,
    hour: Int = 12,
    minute: Int = 0,
    in calendar: Calendar
) throws -> Date {
    try #require(calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)))
}

func dayNumbers(of week: Week, in calendar: Calendar) -> [Int] {
    week.days.map { calendar.component(.day, from: $0) }
}

func makeEvent(
    _ title: String,
    from start: Date,
    to end: Date,
    isAllDay: Bool = false,
    calendarID: String = "work",
    isDeclined: Bool = false,
    isCanceled: Bool = false
) -> CalendarEvent {
    CalendarEvent(
        id: "\(calendarID)-\(title)-\(start.timeIntervalSinceReferenceDate)",
        title: title,
        start: start,
        end: end,
        isAllDay: isAllDay,
        calendarID: calendarID,
        isDeclined: isDeclined,
        isCanceled: isCanceled
    )
}
