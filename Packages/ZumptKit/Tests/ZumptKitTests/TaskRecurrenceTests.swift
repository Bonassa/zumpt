import Foundation
import Testing
import ZumptKit

struct TaskRecurrenceTests {
    @Test func everyOtherWeekUsesSelectedWeekdaysAcrossYearBoundaries() throws {
        let calendar = try makeCalendar()
        let days = try [
            day(2026, 12, 28, in: calendar), day(2026, 12, 30, in: calendar),
            day(2027, 1, 4, in: calendar), day(2027, 1, 6, in: calendar),
            day(2027, 1, 11, in: calendar), day(2027, 1, 13, in: calendar), day(2027, 1, 18, in: calendar),
        ]
        let rule = try #require(
            RecurrenceRule(frequency: .weekly, interval: 2, firstDay: days[0], weekdays: [2, 4], endDay: days[5])
        )
        #expect(days.filter(rule.includes) == [days[0], days[1], days[4], days[5]])
        #expect(!rule.includes(try day(2026, 12, 23, in: calendar)))
    }

    @Test func weeklyIntervalsUseTheStoredWeekStart() throws {
        let calendar = try makeCalendar(firstWeekday: 1)
        let monday = try day(2026, 11, 2, in: calendar)
        let sunday = try day(2026, 11, 8, in: calendar)
        let secondSunday = try day(2026, 11, 15, in: calendar)
        let rule = try #require(
            RecurrenceRule(frequency: .weekly, interval: 2, firstDay: monday, weekdays: [1, 2], weekStartsOn: 1)
        )
        #expect(rule.includes(monday))
        #expect(!rule.includes(sunday))
        #expect(rule.includes(secondSunday))
    }

    @Test func monthAndLeapYearFallbacksKeepOriginalAnchor() throws {
        let calendar = try makeCalendar()
        let january = try day(2024, 1, 31, in: calendar)
        let february = try day(2024, 2, 29, in: calendar)
        let march = try day(2024, 3, 31, in: calendar)
        let nextFebruary = try day(2025, 2, 28, in: calendar)

        let monthly = try #require(RecurrenceRule(frequency: .monthly, interval: 1, firstDay: january))
        #expect(monthly.includes(february))
        #expect(monthly.includes(march))
        #expect(!monthly.includes(try day(2024, 3, 29, in: calendar)))
        let edited = try #require(
            RecurrenceRule(
                frequency: .monthly, interval: 1, firstDay: february, minute: 540, preservingAnchorOf: monthly)
        )
        #expect(edited.includes(march))

        let yearly = try #require(RecurrenceRule(frequency: .yearly, interval: 1, firstDay: february))
        #expect(yearly.includes(nextFebruary))
        #expect(yearly.includes(try day(2028, 2, 29, in: calendar)))
        #expect(!yearly.includes(try day(2028, 2, 28, in: calendar)))
    }

    @Test func timesUseTheNextValidMinuteAndFirstRepeatedTime() throws {
        let calendar = try makeCalendar(timeZone: "America/New_York")
        let gap = try day(2026, 3, 8, in: calendar)
        let afterGap = try day(2026, 3, 9, in: calendar)
        let repeated = try day(2026, 11, 1, in: calendar)
        let skippedTime = OccurrencePlacement(day: gap, minute: 150).start(in: calendar)
        let regularTime = OccurrencePlacement(day: afterGap, minute: 150).start(in: calendar)
        let repeatedTime = OccurrencePlacement(day: repeated, minute: 90).start(in: calendar)
        #expect(skippedTime == (try date(2026, 3, 8, hour: 3, in: calendar)))
        #expect(regularTime == (try date(2026, 3, 9, hour: 2, minute: 30, in: calendar)))
        #expect(calendar.timeZone.secondsFromGMT(for: repeatedTime) == -4 * 3_600)
        #expect(calendar.component(.hour, from: repeatedTime) == 1)
        #expect(calendar.component(.minute, from: repeatedTime) == 30)
    }

    @Test func aTimeZoneChangeKeepsTheLocalDateTimeAndIdentity() throws {
        let newYork = try makeCalendar(timeZone: "America/New_York")
        let saoPaulo = try makeCalendar(timeZone: "America/Sao_Paulo")
        let first = try day(2026, 11, 4, in: newYork)
        let rule = try #require(RecurrenceRule(frequency: .daily, interval: 1, firstDay: first, minute: 1_380))
        let series = TaskSeries(task: makeTask("Routine"), rule: rule, calendar: newYork)
        let now = first.localDate(in: newYork)
        let original = try #require(series.task(on: first, now: now, calendar: newYork))
        let projected = try #require(series.task(on: first, now: now, calendar: saoPaulo))
        let start = try #require(projected.scheduledStart)
        #expect(projected.id == original.id)
        #expect(start != original.scheduledStart)
        #expect(saoPaulo.component(.day, from: start) == 4)
        #expect(saoPaulo.component(.hour, from: start) == 23)
    }

    @Test func invalidRulesAreRejected() throws {
        let calendar = try makeCalendar()
        let first = try day(2026, 11, 4, in: calendar)
        let earlier = try day(2026, 11, 3, in: calendar)
        #expect(RecurrenceRule(frequency: .daily, interval: 0, firstDay: first) == nil)
        #expect(RecurrenceRule(frequency: .daily, interval: -2, firstDay: first) == nil)
        #expect(RecurrenceRule(frequency: .weekly, interval: 1, firstDay: first) == nil)
        #expect(RecurrenceRule(frequency: .daily, interval: 1, firstDay: first, endDay: earlier) == nil)
    }

    @Test func missedOccurrencesStayDatedAndCompletionIsIndependent() throws {
        let calendar = try makeCalendar()
        let monday = try day(2026, 11, 2, in: calendar)
        let tuesday = try day(2026, 11, 3, in: calendar)
        let wednesday = try day(2026, 11, 4, in: calendar)
        let now = tuesday.localDate(in: calendar)
        let rule = try #require(RecurrenceRule(frequency: .daily, interval: 1, firstDay: monday))
        var series = TaskSeries(task: makeTask("Daily routine"), rule: rule, calendar: calendar)
        let tasks = series.tasks(on: [monday, tuesday, wednesday], now: now, calendar: calendar)
        #expect(tasks.map(\.isOverdue) == [true, false, false])
        #expect(tasks.allSatisfy { $0.isAllDay && $0.scheduledEnd == nil })
        #expect(tasks[0].scheduledStart == monday.localDate(in: calendar))
        #expect(Backlog.tasks(tasks).isEmpty)
        #expect(OverdueTasks.returned(from: tasks, now: now, calendar: calendar).isEmpty)

        series.toggleCompletion(on: monday, now: now)
        let completed = series.tasks(on: [monday, tuesday, wednesday], now: now, calendar: calendar)
        #expect(completed.map(\.isDone) == [true, false, false])
        #expect(completed[0].id == tasks[0].id)
        #expect(completed[1...] == tasks[1...])
        series.toggleCompletion(on: monday, now: now)
        #expect(series.tasks(on: [monday, tuesday, wednesday], now: now, calendar: calendar) == tasks)
    }

    @Test func scopeFollowsOriginalDatesEvenWhenOccurrencesAreMoved() throws {
        let calendar = try makeCalendar()
        let monday = try day(2026, 11, 2, in: calendar)
        let tuesday = try day(2026, 11, 3, in: calendar)
        let wednesday = try day(2026, 11, 4, in: calendar)
        let thursday = try day(2026, 11, 5, in: calendar)
        let friday = try day(2026, 11, 6, in: calendar)
        let now = wednesday.localDate(in: calendar)
        let rule = try #require(RecurrenceRule(frequency: .daily, interval: 1, firstDay: monday))
        var series = TaskSeries(task: makeTask("Routine"), rule: rule, calendar: calendar)

        series.move(monday, to: OccurrencePlacement(day: friday, minute: 540))
        series.move(wednesday, to: OccurrencePlacement(day: monday))
        series.toggleCompletion(on: thursday, now: now)
        series.rename(on: wednesday, to: "Exception", scope: .thisOccurrence)
        #expect(series.task(on: wednesday, now: now, calendar: calendar)?.title == "Exception")
        #expect(series.task(on: tuesday, now: now, calendar: calendar)?.title == "Routine")
        series.rename(on: tuesday, to: "New name", scope: .thisAndFollowing)
        #expect(series.task(on: monday, now: now, calendar: calendar)?.title == "Routine")
        #expect(series.task(on: wednesday, now: now, calendar: calendar)?.title == "New name")
        #expect(series.task(on: thursday, now: now, calendar: calendar)?.title == "Routine")
        #expect(series.tasks(on: [monday], now: now, calendar: calendar).map(\.occurrence?.originalDay) == [wednesday])
        #expect(series.tasks(on: [friday], now: now, calendar: calendar).count == 2)

        series.delete(on: tuesday, scope: .thisOccurrence)
        #expect(series.task(on: tuesday, now: now, calendar: calendar) == nil)
        #expect(series.task(on: wednesday, now: now, calendar: calendar) != nil)
        series.delete(on: wednesday, scope: .thisAndFollowing)
        #expect(series.task(on: wednesday, now: now, calendar: calendar) == nil)
        #expect(series.task(on: thursday, now: now, calendar: calendar)?.isDone == true)
        let remaining = series.tasks(on: [friday], now: now, calendar: calendar)
        #expect(remaining.map(\.occurrence?.originalDay) == [monday])
        let timed = try #require(remaining.first)
        #expect(timed.scheduledEnd?.timeIntervalSince(try #require(timed.scheduledStart)) == 1_800)
    }

    @Test func ruleChangesKeepHistoryAndCompletedOccurrencesThroughCoding() throws {
        let calendar = try makeCalendar()
        let monday = try day(2026, 11, 2, in: calendar)
        let tuesday = try day(2026, 11, 3, in: calendar)
        let wednesday = try day(2026, 11, 4, in: calendar)
        let thursday = try day(2026, 11, 5, in: calendar)
        let friday = try day(2026, 11, 6, in: calendar)
        let now = friday.localDate(in: calendar)
        let days = [monday, tuesday, wednesday, thursday, friday]
        let daily = try #require(RecurrenceRule(frequency: .daily, interval: 1, firstDay: monday))
        var series = TaskSeries(task: makeTask("Routine"), rule: daily, calendar: calendar)
        series.rename(on: monday, to: "Earlier change", scope: .thisOccurrence)
        series.toggleCompletion(on: wednesday, now: now)
        series.toggleCompletion(on: thursday, now: now)
        let original = series.tasks(on: days, now: now, calendar: calendar)

        let everyOtherDay = try #require(
            RecurrenceRule(frequency: .daily, interval: 2, firstDay: tuesday, minute: 600, endDay: thursday)
        )
        series.changeRule(from: tuesday, to: everyOtherDay)
        let data = try JSONEncoder().encode(series)
        let reopened = try JSONDecoder().decode(TaskSeries.self, from: data)
        let reopenedAgain = try JSONDecoder().decode(TaskSeries.self, from: data)
        let changed = reopened.tasks(on: days, now: now, calendar: calendar)
        #expect(changed == reopenedAgain.tasks(on: days, now: now, calendar: calendar))
        #expect(Set(changed.map(\.id)).count == changed.count)
        #expect(changed.count == 4)
        #expect(changed[0] == original[0])
        #expect(changed[1].isOverdue && !changed[1].isAllDay)
        #expect(changed[2] == original[2])
        #expect(changed[3] == original[3])
    }

    private func day(_ year: Int, _ month: Int, _ day: Int, in calendar: Calendar) throws -> RecurrenceDay {
        RecurrenceDay(try date(year, month, day, in: calendar), calendar: calendar)
    }
}
