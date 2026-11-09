import Foundation
import Testing
import ZumptKit

struct OverdueTasksTests {
    @Test func returnsATaskFromYesterdayToTheBacklogKeepingItsTime() throws {
        let calendar = try makeCalendar()
        let start = try date(2026, 11, 3, hour: 10, in: calendar)
        let task = makeTask("Enviar NF de outubro", scheduledAt: start)

        let returned = OverdueTasks.returned(
            from: [task],
            now: try date(2026, 11, 4, hour: 8, in: calendar),
            calendar: calendar
        )

        #expect(returned.map(\.id) == [task.id])
        #expect(returned.map(\.scheduledStart) == [nil])
        #expect(returned.map(\.missedStart) == [start])
        #expect(returned.map(\.isOverdue) == [true])
    }

    @Test func keepsATaskWhoseTimePassedEarlierToday() throws {
        let calendar = try makeCalendar()
        let task = makeTask("Pagar boleto", scheduledAt: try date(2026, 11, 4, hour: 9, in: calendar))

        let returned = OverdueTasks.returned(
            from: [task],
            now: try date(2026, 11, 4, hour: 23, minute: 59, in: calendar),
            calendar: calendar
        )

        #expect(returned.isEmpty)
    }

    @Test func returnsTheTaskAtMidnight() throws {
        let calendar = try makeCalendar()
        let task = makeTask("Planejar a semana", scheduledAt: try date(2026, 11, 4, hour: 23, minute: 30, in: calendar))

        let returned = OverdueTasks.returned(
            from: [task],
            now: try date(2026, 11, 5, hour: 0, in: calendar),
            calendar: calendar
        )

        #expect(returned.map(\.title) == ["Planejar a semana"])
    }

    @Test func leavesDoneUnscheduledAndFutureTasksAlone() throws {
        let calendar = try makeCalendar()
        let yesterday = try date(2026, 11, 3, hour: 10, in: calendar)
        let tasks = [
            makeTask("Done yesterday", scheduledAt: yesterday, completedAt: yesterday),
            makeTask("Backlog"),
            makeTask("Tomorrow", scheduledAt: try date(2026, 11, 5, hour: 10, in: calendar)),
        ]

        let returned = OverdueTasks.returned(
            from: tasks,
            now: try date(2026, 11, 4, hour: 12, in: calendar),
            calendar: calendar
        )

        #expect(returned.isEmpty)
    }

    @Test func reconcilesATaskReopenedAfterItsDayEnded() throws {
        let calendar = try makeCalendar()
        let start = try date(2026, 11, 2, hour: 8, minute: 30, in: calendar)
        let reopened = makeTask("Pagar fatura do cartão", scheduledAt: start)

        let reconciled = OverdueTasks.reconciled(
            reopened, now: try date(2026, 11, 4, hour: 12, in: calendar), calendar: calendar)

        #expect(reconciled.id == reopened.id)
        #expect(reconciled.scheduledStart == nil)
        #expect(reconciled.missedStart == start)
        #expect(reconciled.isOverdue)
    }

    @Test func reconcilesOtherTasksToThemselves() throws {
        let calendar = try makeCalendar()
        let yesterday = try date(2026, 11, 3, hour: 10, in: calendar)
        let tasks = [
            makeTask("Done yesterday", scheduledAt: yesterday, completedAt: yesterday),
            makeTask("Backlog"),
            makeTask("Earlier today", scheduledAt: try date(2026, 11, 4, hour: 9, in: calendar)),
            makeTask("Tomorrow", scheduledAt: try date(2026, 11, 5, hour: 10, in: calendar)),
        ]
        let now = try date(2026, 11, 4, hour: 12, in: calendar)

        let reconciled = tasks.map { OverdueTasks.reconciled($0, now: now, calendar: calendar) }

        #expect(reconciled == tasks)
    }

    @Test func usesTheDayOfTheCurrentTimeZone() throws {
        let saoPaulo = try makeCalendar(timeZone: "America/Sao_Paulo")
        let task = makeTask("Ligar para o banco", scheduledAt: try date(2026, 11, 4, hour: 0, minute: 30, in: saoPaulo))
        let losAngeles = try makeCalendar(timeZone: "America/Los_Angeles")
        let lateEveningInLosAngeles = try date(2026, 11, 3, hour: 22, in: losAngeles)

        let returned = OverdueTasks.returned(from: [task], now: lateEveningInLosAngeles, calendar: losAngeles)

        #expect(returned.isEmpty, "It is still Nov 3 in Los Angeles, the day the task falls on there")
    }

    @Test func handlesTheDayDaylightSavingTimeEnds() throws {
        let calendar = try makeCalendar(timeZone: "America/New_York")
        let task = makeTask("Revisar orçamento", scheduledAt: try date(2026, 11, 1, hour: 1, minute: 30, in: calendar))

        let lateThatDay = OverdueTasks.returned(
            from: [task],
            now: try date(2026, 11, 1, hour: 23, minute: 59, in: calendar),
            calendar: calendar
        )
        let nextDay = OverdueTasks.returned(
            from: [task],
            now: try date(2026, 11, 2, hour: 0, in: calendar),
            calendar: calendar
        )

        #expect(lateThatDay.isEmpty)
        #expect(nextDay.map(\.title) == ["Revisar orçamento"])
    }
}

@MainActor
struct DayChangeObserverTests {
    @Test func runsWhenTheCalendarDayChanges() {
        let center = NotificationCenter()
        var changes = 0
        let observer = DayChangeObserver(center: center) {
            changes += 1
        }

        center.post(name: .NSCalendarDayChanged, object: nil)
        center.post(name: .NSSystemClockDidChange, object: nil)
        center.post(name: .NSCalendarDayChanged, object: nil)

        #expect(changes == 2)
        withExtendedLifetime(observer) {}
    }

    @Test func stopsWhenItGoesAway() {
        let center = NotificationCenter()
        var changes = 0
        var observer: DayChangeObserver? = DayChangeObserver(center: center) {
            changes += 1
        }

        observer = nil
        center.post(name: .NSCalendarDayChanged, object: nil)

        #expect(observer == nil)
        #expect(changes == 0)
    }
}
