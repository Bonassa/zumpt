import Foundation
import Testing
import ZumptKit

struct EventFilterTests {
    @Test func hidesDeclinedEventsAndEventsFromHiddenCalendars() throws {
        let calendar = try makeCalendar()
        let start = try date(2026, 11, 2, hour: 10, in: calendar)
        let end = try date(2026, 11, 2, hour: 11, in: calendar)
        let events = [
            makeEvent("Planning", from: start, to: end, calendarID: "work"),
            makeEvent("Happy hour", from: start, to: end, calendarID: "work", isDeclined: true),
            makeEvent("Holiday", from: start, to: end, calendarID: "holidays"),
            makeEvent("Gym", from: start, to: end, calendarID: "personal"),
        ]

        let visible = EventFilter.visible(events, hiddenCalendarIDs: ["holidays"])

        #expect(visible.map(\.title) == ["Planning", "Gym"])
    }
}
