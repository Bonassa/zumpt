import AppKit
import EventKit
import OSLog
import ZumptKit

final class EventKitCalendarStore: CalendarStore {
    let changes: AsyncStream<Void>

    private let eventStore = EKEventStore()
    private let changesContinuation: AsyncStream<Void>.Continuation
    private var changeObserver: (any NSObjectProtocol)?
    private var fetchedEvents: [String: EKEvent] = [:]
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
        let matched = eventStore.events(matching: predicate).map { (Self.calendarEvent(from: $0), $0) }
        fetchedEvents = Dictionary(matched.map { ($0.0.id, $0.1) }, uniquingKeysWith: { first, _ in first })
        return matched.map(\.0)
    }

    func details(of event: CalendarEvent) -> EventDetails? {
        fetchedEvents[event.id].map { Self.eventDetails(from: $0) }
    }

    func calendarAppURL(for event: CalendarEvent) -> URL? {
        guard let calendarItemIdentifier = fetchedEvents[event.id]?.calendarItemIdentifier else {
            return nil
        }
        var components = URLComponents()
        components.scheme = "ical"
        components.host = "ekevent"
        components.path = "/\(calendarItemIdentifier)"
        components.queryItems = [
            URLQueryItem(name: "method", value: "show"),
            URLQueryItem(name: "options", value: "more"),
        ]
        return components.url
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
            isDeclined: event.attendees?.contains { $0.isCurrentUser && $0.participantStatus == .declined } ?? false,
            isCanceled: event.status == .canceled
        )
    }

    nonisolated private static func eventDetails(from event: EKEvent) -> EventDetails {
        EventDetails(
            location: nonBlank(event.location),
            notes: nonBlank(event.notes),
            url: event.url,
            participants: participants(of: event),
            recurrence: event.recurrenceRules?.first.map { recurrence(from: $0) }
        )
    }

    nonisolated private static func participants(of event: EKEvent) -> [Participant] {
        let organizerAddress = event.organizer.map { address(of: $0) }
        var participants = (event.attendees ?? [])
            .filter { $0.participantType != .room && $0.participantType != .resource }
            .map { participant(from: $0, isOrganizer: address(of: $0) == organizerAddress) }
        if let organizer = event.organizer, !participants.contains(where: \.isOrganizer) {
            participants.append(participant(from: organizer, isOrganizer: true))
        }
        return participants.sorted { lhs, rhs in
            if lhs.isOrganizer != rhs.isOrganizer {
                return lhs.isOrganizer
            }
            if lhs.isCurrentUser != rhs.isCurrentUser {
                return lhs.isCurrentUser
            }
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }

    nonisolated private static func participant(from participant: EKParticipant, isOrganizer: Bool) -> Participant {
        let address = address(of: participant)
        let email = address.hasPrefix("mailto:") ? String(address.dropFirst("mailto:".count)) : nil
        let response = response(from: participant.participantStatus)
        return Participant(
            name: nonBlank(participant.name) ?? email ?? address,
            email: email,
            response: isOrganizer && response == .pending ? .accepted : response,
            isOrganizer: isOrganizer,
            isCurrentUser: participant.isCurrentUser
        )
    }

    nonisolated private static func address(of participant: EKParticipant) -> String {
        participant.url.absoluteString.lowercased()
    }

    nonisolated private static func response(from status: EKParticipantStatus) -> ResponseStatus {
        switch status {
        case .accepted: .accepted
        case .declined: .declined
        case .tentative: .tentative
        default: .pending
        }
    }

    nonisolated private static func recurrence(from rule: EKRecurrenceRule) -> Recurrence {
        let frequency: Recurrence.Frequency =
            switch rule.frequency {
            case .daily: .daily
            case .weekly: .weekly
            case .monthly: .monthly
            case .yearly: .yearly
            @unknown default: .weekly
            }
        return Recurrence(
            frequency: frequency,
            interval: rule.interval,
            weekdays: rule.daysOfTheWeek?.map(\.dayOfTheWeek.rawValue) ?? []
        )
    }

    nonisolated private static func nonBlank(_ text: String?) -> String? {
        guard let text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return text
    }
}
