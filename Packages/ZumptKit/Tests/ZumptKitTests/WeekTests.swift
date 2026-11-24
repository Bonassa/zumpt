import Foundation
import Testing
import ZumptKit

struct WeekTests {
    @Test(arguments: [1, 2])
    func showsMondayToFridayWhateverTheCalendarFirstWeekday(firstWeekday: Int) throws {
        let calendar = try makeCalendar(firstWeekday: firstWeekday)

        let week = Week(containing: try date(2026, 11, 4, in: calendar), calendar: calendar)

        #expect(dayNumbers(of: week, in: calendar) == [2, 3, 4, 5, 6])
        #expect(week.days.map { calendar.component(.weekday, from: $0) } == [2, 3, 4, 5, 6])
    }

    @Test func includesTheDateItWasBuiltFromWhenItIsMondayAtMidnight() throws {
        let calendar = try makeCalendar()

        let week = Week(containing: try date(2026, 11, 2, hour: 0, in: calendar), calendar: calendar)

        #expect(dayNumbers(of: week, in: calendar) == [2, 3, 4, 5, 6])
    }

    @Test func includesFridayUntilMidnight() throws {
        let calendar = try makeCalendar()

        let week = Week(containing: try date(2026, 11, 6, hour: 23, minute: 59, in: calendar), calendar: calendar)

        #expect(dayNumbers(of: week, in: calendar) == [2, 3, 4, 5, 6])
    }

    @Test(arguments: [1, 2])
    func showsTheComingWeekOnTheWeekend(firstWeekday: Int) throws {
        let calendar = try makeCalendar(firstWeekday: firstWeekday)

        let saturday = Week(containing: try date(2026, 11, 7, hour: 0, in: calendar), calendar: calendar)
        let sunday = Week(containing: try date(2026, 11, 8, hour: 23, minute: 59, in: calendar), calendar: calendar)

        #expect(dayNumbers(of: saturday, in: calendar) == [9, 10, 11, 12, 13])
        #expect(sunday == saturday)
    }

    @Test func numberFollowsTheCalendarWeekOfYear() throws {
        let calendar = try makeCalendar()

        let week = Week(containing: try date(2026, 11, 4, in: calendar), calendar: calendar)

        #expect(week.number == 45)
    }

    @Test(arguments: [1, 2])
    func numberOnTheWeekendIsTheComingWeek(firstWeekday: Int) throws {
        let calendar = try makeCalendar(firstWeekday: firstWeekday)

        let week = Week(containing: try date(2026, 11, 7, in: calendar), calendar: calendar)

        #expect(week.number == 46)
    }

    @Test func everyDayStartsAtMidnightWhenTheClocksChangeOverTheWeekend() throws {
        let calendar = try makeCalendar(timeZone: "America/New_York")

        let fallBack = Week(containing: try date(2026, 10, 31, in: calendar), calendar: calendar)
        let springForward = Week(containing: try date(2027, 3, 14, hour: 4, in: calendar), calendar: calendar)

        #expect(dayNumbers(of: fallBack, in: calendar) == [2, 3, 4, 5, 6])
        #expect(dayNumbers(of: springForward, in: calendar) == [15, 16, 17, 18, 19])
        for day in fallBack.days + springForward.days {
            let components = calendar.dateComponents([.hour, .minute, .second], from: day)
            #expect(components.hour == 0 && components.minute == 0 && components.second == 0)
        }
    }

    @Test func midweekDayFallsInTheMonthHoldingMostOfTheWeek() throws {
        let calendar = try makeCalendar()

        let week = Week(containing: try date(2026, 12, 1, in: calendar), calendar: calendar)

        #expect(dayNumbers(of: week, in: calendar) == [30, 1, 2, 3, 4])
        #expect(calendar.component(.month, from: week.midweekDay) == 12)
    }

    @Test func weekCrossingNewYearIsTheFirstWeekOfTheNewYear() throws {
        let calendar = try makeCalendar()

        let week = Week(containing: try date(2027, 1, 1, in: calendar), calendar: calendar)

        #expect(dayNumbers(of: week, in: calendar) == [28, 29, 30, 31, 1])
        #expect(week.number == 1)
    }

    @Test func intervalCoversMondayUntilSaturdayStarts() throws {
        let calendar = try makeCalendar()

        let interval = Week(containing: try date(2026, 11, 4, in: calendar), calendar: calendar).interval(in: calendar)

        #expect(interval.start == (try date(2026, 11, 2, hour: 0, in: calendar)))
        #expect(interval.end == (try date(2026, 11, 7, hour: 0, in: calendar)))
    }

    @Test func containsTheWorkingDaysButNotTheWeekend() throws {
        let calendar = try makeCalendar()
        let week = Week(containing: try date(2026, 11, 4, in: calendar), calendar: calendar)

        #expect(week.contains(try date(2026, 11, 2, hour: 0, in: calendar), calendar: calendar))
        #expect(week.contains(try date(2026, 11, 6, hour: 23, minute: 59, in: calendar), calendar: calendar))
        #expect(!week.contains(try date(2026, 11, 7, hour: 0, in: calendar), calendar: calendar))
        #expect(!week.contains(try date(2026, 11, 1, hour: 23, minute: 59, in: calendar), calendar: calendar))
    }

    @Test func addingWeeksMovesForwardAndBackAcrossTheYear() throws {
        let calendar = try makeCalendar()
        let week = Week(containing: try date(2026, 12, 23, in: calendar), calendar: calendar)

        let next = week.adding(weeks: 1, calendar: calendar)
        let previous = next.adding(weeks: -1, calendar: calendar)

        #expect(dayNumbers(of: next, in: calendar) == [28, 29, 30, 31, 1])
        #expect(next.number == 1)
        #expect(previous == week)
    }
}
