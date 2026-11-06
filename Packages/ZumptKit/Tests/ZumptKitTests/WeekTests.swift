import Foundation
import Testing
import ZumptKit

struct WeekTests {
    @Test func startsOnTheCalendarFirstWeekday() throws {
        let calendar = try makeCalendar(firstWeekday: 1)

        let week = Week(containing: try date(2026, 11, 4, in: calendar), calendar: calendar)

        #expect(dayNumbers(of: week, in: calendar) == [1, 2, 3, 4, 5, 6, 7])
    }

    @Test func startsOnMondayWhenTheCalendarDoes() throws {
        let calendar = try makeCalendar(firstWeekday: 2)

        let week = Week(containing: try date(2026, 11, 4, in: calendar), calendar: calendar)

        #expect(dayNumbers(of: week, in: calendar) == [2, 3, 4, 5, 6, 7, 8])
    }

    @Test func includesTheDateItWasBuiltFromWhenItIsTheFirstDay() throws {
        let calendar = try makeCalendar(firstWeekday: 1)

        let week = Week(containing: try date(2026, 11, 1, hour: 0, in: calendar), calendar: calendar)

        #expect(dayNumbers(of: week, in: calendar) == [1, 2, 3, 4, 5, 6, 7])
    }

    @Test func numberFollowsTheCalendarWeekOfYear() throws {
        let calendar = try makeCalendar(firstWeekday: 1)

        let week = Week(containing: try date(2026, 11, 4, in: calendar), calendar: calendar)

        #expect(week.number == 45)
    }

    @Test func everyDayStartsAtMidnightAcrossADaylightSavingChange() throws {
        let calendar = try makeCalendar(firstWeekday: 1, timeZone: "America/New_York")

        let week = Week(containing: try date(2026, 11, 3, in: calendar), calendar: calendar)

        #expect(dayNumbers(of: week, in: calendar) == [1, 2, 3, 4, 5, 6, 7])
        for day in week.days {
            let components = calendar.dateComponents([.hour, .minute, .second], from: day)
            #expect(components.hour == 0 && components.minute == 0 && components.second == 0)
        }
    }

    @Test func midweekDayFallsInTheMonthHoldingMostOfTheWeek() throws {
        let calendar = try makeCalendar(firstWeekday: 1)

        let week = Week(containing: try date(2026, 12, 1, in: calendar), calendar: calendar)

        #expect(dayNumbers(of: week, in: calendar) == [29, 30, 1, 2, 3, 4, 5])
        #expect(calendar.component(.month, from: week.midweekDay) == 12)
    }

    @Test func weekCrossingNewYearIsTheFirstWeekOfTheNewYear() throws {
        let calendar = try makeCalendar(firstWeekday: 1)

        let week = Week(containing: try date(2027, 1, 1, in: calendar), calendar: calendar)

        #expect(dayNumbers(of: week, in: calendar) == [27, 28, 29, 30, 31, 1, 2])
        #expect(week.number == 1)
    }
}

private func makeCalendar(firstWeekday: Int, timeZone: String = "America/Sao_Paulo") throws -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = Locale(identifier: "pt_BR")
    calendar.timeZone = try #require(TimeZone(identifier: timeZone))
    calendar.firstWeekday = firstWeekday
    calendar.minimumDaysInFirstWeek = 1
    return calendar
}

private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12, in calendar: Calendar) throws -> Date {
    try #require(calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour)))
}

private func dayNumbers(of week: Week, in calendar: Calendar) -> [Int] {
    week.days.map { calendar.component(.day, from: $0) }
}
