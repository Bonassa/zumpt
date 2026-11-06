import AppKit
import EventKit
import OSLog
import ZumptKit

final class EventKitCalendarStore: CalendarStore {
    let changes: AsyncStream<Void>

    private let eventStore = EKEventStore()
    private let changesContinuation: AsyncStream<Void>.Continuation
    private var changeObserver: (any NSObjectProtocol)?
    private let logger = Logger(subsystem: "com.renanbonassa.zumpt", category: "calendar")

    init() {
        let (stream, continuation) = AsyncStream.makeStream(of: Void.self, bufferingPolicy: .bufferingNewest(1))
        changes = stream
        changesContinuation = continuation
        changeObserver = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: eventStore,
            queue: .main
        ) { _ in
            continuation.yield()
        }
    }

    isolated deinit {
        if let changeObserver {
            NotificationCenter.default.removeObserver(changeObserver)
        }
        changesContinuation.finish()
    }

    var access: CalendarAccess {
        Self.access(from: EKEventStore.authorizationStatus(for: .event))
    }

    func requestAccess() async -> CalendarAccess {
        do {
            _ = try await eventStore.requestFullAccessToEvents()
        } catch {
            logger.error("Calendar access request failed: \(error.localizedDescription, privacy: .public)")
        }
        return access
    }

    func accounts() -> [CalendarAccount] {
        let calendarsBySource = Dictionary(grouping: eventStore.calendars(for: .event)) {
            $0.source?.sourceIdentifier ?? ""
        }
        return
            calendarsBySource
            .map { sourceID, calendars in
                CalendarAccount(
                    id: sourceID,
                    title: calendars.first?.source?.title ?? "",
                    calendars: calendars.map { Self.eventCalendar(from: $0) }.sorted(by: Self.isOrderedByTitle)
                )
            }
            .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }

    func events(in interval: DateInterval) -> [CalendarEvent] {
        let predicate = eventStore.predicateForEvents(withStart: interval.start, end: interval.end, calendars: nil)
        return eventStore.events(matching: predicate).map { Self.calendarEvent(from: $0) }
    }

    nonisolated private static func access(from status: EKAuthorizationStatus) -> CalendarAccess {
        switch status {
        case .fullAccess: .granted
        case .notDetermined: .notDetermined
        default: .denied
        }
    }

    nonisolated private static func eventCalendar(from calendar: EKCalendar) -> EventCalendar {
        let color = calendar.color?.usingColorSpace(.sRGB)
        return EventCalendar(
            id: calendar.calendarIdentifier,
            title: calendar.title,
            color: CalendarColor(
                red: Double(color?.redComponent ?? 0.5),
                green: Double(color?.greenComponent ?? 0.5),
                blue: Double(color?.blueComponent ?? 0.5)
            )
        )
    }

    nonisolated private static func isOrderedByTitle(_ lhs: EventCalendar, _ rhs: EventCalendar) -> Bool {
        lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
    }

    nonisolated private static func calendarEvent(from event: EKEvent) -> CalendarEvent {
        CalendarEvent(
            id: "\(event.calendarItemIdentifier)@\(event.startDate.timeIntervalSinceReferenceDate)",
            title: event.title ?? "",
            start: event.startDate,
            end: event.endDate,
            isAllDay: event.isAllDay,
            calendarID: event.calendar?.calendarIdentifier ?? "",
            isDeclined: event.attendees?.contains { $0.isCurrentUser && $0.participantStatus == .declined } ?? false
        )
    }
}
