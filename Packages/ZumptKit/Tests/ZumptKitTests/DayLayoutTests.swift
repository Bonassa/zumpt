import Foundation
import Testing
import ZumptKit

struct DayLayoutTests {
    @Test func placesTimedEventsByMinutesSinceTheStartOfTheDay() throws {
        let calendar = try makeCalendar()
        let event = makeEvent(
            "Planejamento",
            from: try date(2026, 11, 2, hour: 11, in: calendar),
            to: try date(2026, 11, 2, hour: 12, minute: 30, in: calendar)
        )

        let layout = timedItems([event], on: try date(2026, 11, 2, in: calendar), calendar: calendar)

        #expect(layout.map(\.startMinute) == [660])
        #expect(layout.map(\.endMinute) == [750])
        #expect(layout.map(\.column) == [0])
        #expect(layout.map(\.columnCount) == [1])
    }

    @Test func leavesOutEventsFromOtherDaysAndAllDayEvents() throws {
        let calendar = try makeCalendar()
        let events = [
            makeEvent(
                "Yesterday",
                from: try date(2026, 11, 1, hour: 10, in: calendar),
                to: try date(2026, 11, 1, hour: 11, in: calendar)
            ),
            makeEvent(
                "Holiday",
                from: try date(2026, 11, 2, hour: 0, in: calendar),
                to: try date(2026, 11, 3, hour: 0, in: calendar),
                isAllDay: true
            ),
            makeEvent(
                "Today",
                from: try date(2026, 11, 2, hour: 10, in: calendar),
                to: try date(2026, 11, 2, hour: 11, in: calendar)
            ),
            makeEvent(
                "Ends at midnight",
                from: try date(2026, 11, 1, hour: 23, in: calendar),
                to: try date(2026, 11, 2, hour: 0, in: calendar)
            ),
        ]

        let layout = timedItems(events, on: try date(2026, 11, 2, in: calendar), calendar: calendar)

        #expect(layout.map(\.item.title) == ["Today"])
    }

    @Test func splitsOverlappingEventsIntoColumns() throws {
        let calendar = try makeCalendar()
        let events = [
            makeEvent(
                "Forum",
                from: try date(2026, 11, 4, hour: 11, in: calendar),
                to: try date(2026, 11, 4, hour: 12, in: calendar)
            ),
            makeEvent(
                "Design review",
                from: try date(2026, 11, 4, hour: 11, minute: 30, in: calendar),
                to: try date(2026, 11, 4, hour: 12, minute: 30, in: calendar)
            ),
        ]

        let layout = timedItems(events, on: try date(2026, 11, 4, in: calendar), calendar: calendar)

        #expect(layout.map(\.item.title) == ["Forum", "Design review"])
        #expect(layout.map(\.column) == [0, 1])
        #expect(layout.map(\.columnSpan) == [1, 1])
        #expect(layout.map(\.columnCount) == [2, 2])
    }

    @Test func widensAnEventIntoColumnsThatAreFreeDuringItsTime() throws {
        let calendar = try makeCalendar()
        let events = [
            makeEvent(
                "Workshop",
                from: try date(2026, 11, 2, hour: 9, in: calendar),
                to: try date(2026, 11, 2, hour: 12, in: calendar)
            ),
            makeEvent(
                "Planning",
                from: try date(2026, 11, 2, hour: 9, in: calendar),
                to: try date(2026, 11, 2, hour: 10, in: calendar)
            ),
            makeEvent(
                "Daily",
                from: try date(2026, 11, 2, hour: 9, in: calendar),
                to: try date(2026, 11, 2, hour: 9, minute: 30, in: calendar)
            ),
            makeEvent(
                "Review",
                from: try date(2026, 11, 2, hour: 10, in: calendar),
                to: try date(2026, 11, 2, hour: 11, in: calendar)
            ),
        ]

        let layout = timedItems(events, on: try date(2026, 11, 2, in: calendar), calendar: calendar)

        #expect(layout.map(\.item.title) == ["Workshop", "Planning", "Daily", "Review"])
        #expect(layout.map(\.column) == [0, 1, 2, 1])
        #expect(layout.map(\.columnSpan) == [1, 1, 1, 2])
        #expect(layout.map(\.columnCount) == [3, 3, 3, 3])
    }

    @Test func keepsBackToBackEventsInASingleColumn() throws {
        let calendar = try makeCalendar()
        let events = [
            makeEvent(
                "Payments",
                from: try date(2026, 11, 3, hour: 16, in: calendar),
                to: try date(2026, 11, 3, hour: 17, in: calendar)
            ),
            makeEvent(
                "Leadership",
                from: try date(2026, 11, 3, hour: 17, in: calendar),
                to: try date(2026, 11, 3, hour: 18, in: calendar)
            ),
        ]

        let layout = timedItems(events, on: try date(2026, 11, 3, in: calendar), calendar: calendar)

        #expect(layout.map(\.column) == [0, 0])
        #expect(layout.map(\.columnCount) == [1, 1])
    }

    @Test func reusesAFreedColumnWithinAChainOfOverlaps() throws {
        let calendar = try makeCalendar()
        let events = [
            makeEvent(
                "A",
                from: try date(2026, 11, 5, hour: 9, in: calendar),
                to: try date(2026, 11, 5, hour: 10, in: calendar)
            ),
            makeEvent(
                "B",
                from: try date(2026, 11, 5, hour: 9, minute: 30, in: calendar),
                to: try date(2026, 11, 5, hour: 11, in: calendar)
            ),
            makeEvent(
                "C",
                from: try date(2026, 11, 5, hour: 10, in: calendar),
                to: try date(2026, 11, 5, hour: 10, minute: 30, in: calendar)
            ),
            makeEvent(
                "D",
                from: try date(2026, 11, 5, hour: 14, in: calendar),
                to: try date(2026, 11, 5, hour: 15, in: calendar)
            ),
        ]

        let layout = timedItems(events, on: try date(2026, 11, 5, in: calendar), calendar: calendar)

        #expect(layout.map(\.item.title) == ["A", "B", "C", "D"])
        #expect(layout.map(\.column) == [0, 1, 0, 0])
        #expect(layout.map(\.columnSpan) == [1, 1, 1, 1])
        #expect(layout.map(\.columnCount) == [2, 2, 2, 1])
    }

    @Test func clipsEventsThatCrossMidnightToEachDay() throws {
        let calendar = try makeCalendar()
        let event = makeEvent(
            "Deploy",
            from: try date(2026, 11, 6, hour: 22, in: calendar),
            to: try date(2026, 11, 7, hour: 2, in: calendar)
        )

        let friday = timedItems([event], on: try date(2026, 11, 6, in: calendar), calendar: calendar)
        let saturday = timedItems([event], on: try date(2026, 11, 7, in: calendar), calendar: calendar)

        #expect(friday.map(\.startMinute) == [1320])
        #expect(friday.map(\.endMinute) == [1440])
        #expect(saturday.map(\.startMinute) == [0])
        #expect(saturday.map(\.endMinute) == [120])
    }

    @Test func givesVeryShortEventsAMinimumDuration() throws {
        let calendar = try makeCalendar()
        let start = try date(2026, 11, 2, hour: 9, minute: 30, in: calendar)
        let events = [
            makeEvent("Reminder", from: start, to: start),
            makeEvent("Check-in", from: start.addingTimeInterval(20 * 60), to: start.addingTimeInterval(25 * 60)),
        ]

        let layout = timedItems(events, on: start, calendar: calendar)

        #expect(layout.map(\.startMinute) == [570, 590])
        #expect(layout.map(\.endMinute) == [585, 605])
        #expect(layout.map(\.columnCount) == [1, 1])
    }

    @Test func showsAMultiDayAllDayEventOnEveryDayItCovers() throws {
        let calendar = try makeCalendar()
        let trip = makeEvent(
            "Trip",
            from: try date(2026, 11, 5, hour: 0, in: calendar),
            to: try date(2026, 11, 7, hour: 0, in: calendar),
            isAllDay: true
        )

        let days = try [4, 5, 6, 7].map { day in
            DayLayout.allDayEvents([trip], on: try date(2026, 11, day, in: calendar), calendar: calendar).count
        }

        #expect(days == [0, 1, 1, 0])
    }

    @Test func leavesTimedEventsOutOfTheAllDayRow() throws {
        let calendar = try makeCalendar()
        let meeting = makeEvent(
            "Meeting",
            from: try date(2026, 11, 2, hour: 10, in: calendar),
            to: try date(2026, 11, 2, hour: 11, in: calendar)
        )

        let allDay = DayLayout.allDayEvents([meeting], on: try date(2026, 11, 2, in: calendar), calendar: calendar)

        #expect(allDay.isEmpty)
    }

    @Test func placesAScheduledTaskForThirtyMinutes() throws {
        let calendar = try makeCalendar()
        let task = makeTask("Renovar CNH", scheduledAt: try date(2026, 11, 4, hour: 14, in: calendar))

        let layout = timedItems([], tasks: [task], on: try date(2026, 11, 4, in: calendar), calendar: calendar)

        #expect(layout.map(\.item) == [.task(task)])
        #expect(layout.map(\.startMinute) == [840])
        #expect(layout.map(\.endMinute) == [870])
        #expect(layout.map(\.columnCount) == [1])
    }

    @Test func putsATaskNextToAMeetingAtTheSameTime() throws {
        let calendar = try makeCalendar()
        let start = try date(2026, 11, 2, hour: 15, in: calendar)
        let meeting = makeEvent("Acompanhamento squad", from: start, to: start.addingTimeInterval(30 * 60))
        let task = makeTask("Revisar contrato", scheduledAt: start)

        let layout = timedItems([meeting], tasks: [task], on: start, calendar: calendar)

        #expect(Set(layout.map(\.item)) == [.event(meeting), .task(task)])
        #expect(Set(layout.map(\.column)) == [0, 1])
        #expect(layout.map(\.columnSpan) == [1, 1])
        #expect(layout.map(\.columnCount) == [2, 2])
    }

    @Test func putsATaskBesideTheMeetingItOverlaps() throws {
        let calendar = try makeCalendar()
        let meeting = makeEvent(
            "Planejamento",
            from: try date(2026, 11, 2, hour: 11, in: calendar),
            to: try date(2026, 11, 2, hour: 12, in: calendar)
        )
        let task = makeTask("Pagar boleto", scheduledAt: try date(2026, 11, 2, hour: 11, minute: 45, in: calendar))

        let layout = timedItems([meeting], tasks: [task], on: try date(2026, 11, 2, in: calendar), calendar: calendar)

        #expect(layout.map(\.item) == [.event(meeting), .task(task)])
        #expect(layout.map(\.column) == [0, 1])
        #expect(layout.map(\.columnCount) == [2, 2])
    }

    @Test func leavesOutTasksFromOtherDaysAndUnscheduledTasks() throws {
        let calendar = try makeCalendar()
        let tasks = [
            makeTask("Yesterday", scheduledAt: try date(2026, 11, 1, hour: 10, in: calendar)),
            makeTask("Backlog", scheduledAt: nil),
            makeTask("Today", scheduledAt: try date(2026, 11, 2, hour: 10, in: calendar)),
        ]

        let layout = timedItems([], tasks: tasks, on: try date(2026, 11, 2, in: calendar), calendar: calendar)

        #expect(layout.map(\.item.title) == ["Today"])
    }

    @Test func keepsATaskAtTheEndOfTheDayInsideTheDay() throws {
        let calendar = try makeCalendar()
        let task = makeTask("Planejar amanhã", scheduledAt: try date(2026, 11, 2, hour: 23, minute: 30, in: calendar))

        let monday = timedItems([], tasks: [task], on: try date(2026, 11, 2, in: calendar), calendar: calendar)
        let tuesday = timedItems([], tasks: [task], on: try date(2026, 11, 3, in: calendar), calendar: calendar)

        #expect(monday.map(\.startMinute) == [1410])
        #expect(monday.map(\.endMinute) == [1440])
        #expect(tuesday.isEmpty)
    }

    private func timedItems(
        _ events: [CalendarEvent],
        tasks: [TaskItem] = [],
        on day: Date,
        calendar: Calendar
    ) -> [PositionedItem] {
        DayLayout.timedItems(events: events, tasks: tasks, on: day, calendar: calendar)
    }
}
