import Foundation
import Testing
import ZumptKit

struct EventFilterTests {
    @Test func hidesDeclinedAndCanceledEventsAndEventsFromHiddenCalendars() throws {
        let (start, end) = try meetingTimes()
        let events = [
            makeEvent("Planning", from: start, to: end, calendarID: "work"),
            makeEvent("Happy hour", from: start, to: end, calendarID: "work", isDeclined: true),
            makeEvent("Cancelado: Retro", from: start, to: end, calendarID: "work", isCanceled: true),
            makeEvent("Holiday", from: start, to: end, calendarID: "holidays"),
            makeEvent("Gym", from: start, to: end, calendarID: "personal"),
        ]

        let visible = EventFilter.visible(events, hiddenCalendarIDs: ["holidays"], calendarOrder: [])

        #expect(visible.map(\.title) == ["Planning", "Gym"])
    }

    @Test func showsAMeetingFromSeveralCalendarsOnceUsingTheFirstListedCalendar() throws {
        let (start, end) = try meetingTimes()
        let events = [
            makeEvent("Daily", from: start, to: end, calendarID: "google"),
            makeEvent("Daily", from: start, to: end, calendarID: "exchange"),
        ]

        let visible = EventFilter.visible(events, hiddenCalendarIDs: [], calendarOrder: ["exchange", "google"])

        #expect(visible.map(\.calendarID) == ["exchange"])
    }

    @Test func treatsAForwardedCopyAsTheSameMeeting() throws {
        let (start, end) = try meetingTimes()
        let events = [
            makeEvent("Alinhamento", from: start, to: end, calendarID: "exchange"),
            makeEvent("ENC: Alinhamento", from: start, to: end, calendarID: "google"),
            makeEvent("FW: fwd:  alinhamento ", from: start, to: end, calendarID: "icloud"),
        ]

        let visible = EventFilter.visible(
            events,
            hiddenCalendarIDs: [],
            calendarOrder: ["exchange", "google", "icloud"]
        )

        #expect(visible.map(\.title) == ["Alinhamento"])
    }

    @Test func keepsTheCopyFromAVisibleCalendarWhenTheFirstOneIsHidden() throws {
        let (start, end) = try meetingTimes()
        let events = [
            makeEvent("Daily", from: start, to: end, calendarID: "exchange"),
            makeEvent("Daily", from: start, to: end, calendarID: "google"),
        ]

        let visible = EventFilter.visible(
            events,
            hiddenCalendarIDs: ["exchange"],
            calendarOrder: ["exchange", "google"]
        )

        #expect(visible.map(\.calendarID) == ["google"])
    }

    @Test func keepsSameTitledEventsAtDifferentTimes() throws {
        let calendar = try makeCalendar()
        let (start, end) = try meetingTimes()
        let tomorrow = try #require(calendar.date(byAdding: .day, value: 1, to: start))
        let events = [
            makeEvent("Daily", from: start, to: end, calendarID: "exchange"),
            makeEvent("Daily", from: tomorrow, to: tomorrow.addingTimeInterval(15 * 60), calendarID: "google"),
        ]

        let visible = EventFilter.visible(events, hiddenCalendarIDs: [], calendarOrder: ["exchange", "google"])

        #expect(visible.count == 2)
    }

    @Test func showsRepeatedInvitesInTheSameCalendarOnce() throws {
        let (start, end) = try meetingTimes()
        let events = [
            makeEvent("Daily do squad", from: start, to: end, calendarID: "exchange"),
            makeEvent("Daily do squad", from: start, to: end, calendarID: "exchange"),
            makeEvent("[Acompanhamento] 1:1", from: start, to: end, calendarID: "exchange"),
        ]

        let visible = EventFilter.visible(events, hiddenCalendarIDs: [], calendarOrder: ["exchange"])

        #expect(visible.map(\.title) == ["Daily do squad", "[Acompanhamento] 1:1"])
    }

    @Test func showsAHolidayFromTwoHolidayCalendarsOnce() throws {
        let calendar = try makeCalendar()
        let day = try date(2026, 11, 2, hour: 0, in: calendar)
        let nextDay = try date(2026, 11, 3, hour: 0, in: calendar)
        let events = [
            makeEvent("Finados", from: day, to: nextDay, isAllDay: true, calendarID: "google-holidays"),
            makeEvent("Finados", from: day, to: nextDay, isAllDay: true, calendarID: "subscribed-holidays"),
        ]

        let visible = EventFilter.visible(
            events,
            hiddenCalendarIDs: [],
            calendarOrder: ["google-holidays", "subscribed-holidays"]
        )

        #expect(visible.map(\.calendarID) == ["google-holidays"])
    }

    private func meetingTimes() throws -> (Date, Date) {
        let calendar = try makeCalendar()
        return (
            try date(2026, 11, 2, hour: 10, in: calendar),
            try date(2026, 11, 2, hour: 10, minute: 30, in: calendar)
        )
    }
}
