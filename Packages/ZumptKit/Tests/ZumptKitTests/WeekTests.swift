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

    @Test func intervalCoversTheSevenDaysUpToTheNextWeekStart() throws {
        let calendar = try makeCalendar(firstWeekday: 1)

        let interval = Week(containing: try date(2026, 11, 4, in: calendar), calendar: calendar).interval(in: calendar)

        #expect(interval.start == (try date(2026, 11, 1, hour: 0, in: calendar)))
        #expect(interval.end == (try date(2026, 11, 8, hour: 0, in: calendar)))
    }

    @Test func containsDatesFromTheFirstDayUntilTheNextWeekStarts() throws {
        let calendar = try makeCalendar(firstWeekday: 1)
        let week = Week(containing: try date(2026, 11, 4, in: calendar), calendar: calendar)

        #expect(week.contains(try date(2026, 11, 1, hour: 0, in: calendar), calendar: calendar))
        #expect(week.contains(try date(2026, 11, 7, hour: 23, minute: 59, in: calendar), calendar: calendar))
        #expect(!week.contains(try date(2026, 11, 8, hour: 0, in: calendar), calendar: calendar))
        #expect(!week.contains(try date(2026, 10, 31, hour: 23, minute: 59, in: calendar), calendar: calendar))
    }

    @Test func addingWeeksMovesForwardAndBackAcrossTheYear() throws {
        let calendar = try makeCalendar(firstWeekday: 1)
        let week = Week(containing: try date(2026, 12, 23, in: calendar), calendar: calendar)

        let next = week.adding(weeks: 1, calendar: calendar)
        let previous = next.adding(weeks: -1, calendar: calendar)

        #expect(dayNumbers(of: next, in: calendar) == [27, 28, 29, 30, 31, 1, 2])
        #expect(next.number == 1)
        #expect(previous == week)
    }
}
