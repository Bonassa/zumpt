#if DEBUG
    import Foundation
    import ZumptKit

    final class FixtureCalendarStore: CalendarStore {
        private(set) var access: CalendarAccess
        let changes = AsyncStream<Void> { _ in }

        private let fixtureEvents: [CalendarEvent]

        init(access: CalendarAccess, week: Week, calendar: Calendar) {
            self.access = access
            fixtureEvents = FixtureData.events(in: week, calendar: calendar)
        }

        func requestAccess() async -> CalendarAccess {
            if access == .notDetermined {
                access = .granted
            }
            return access
        }

        func accounts() -> [CalendarAccount] {
            FixtureData.accounts
        }

        func events(in interval: DateInterval) -> [CalendarEvent] {
            fixtureEvents.filter { $0.start < interval.end && $0.end > interval.start }
        }

        func details(of event: CalendarEvent) -> EventDetails? {
            FixtureData.details[event.title]
        }

        func calendarAppURL(for event: CalendarEvent) -> URL? {
            URL(string: "ical://ekevent/\(event.id)")
        }
    }

    private enum FixtureData {
        static let agenda = calendar("fixture-agenda", "Agenda", 19, 130, 124)
        static let holidays = calendar("fixture-holidays", "Feriados no Brasil", 61, 139, 55)
        static let work = calendar("fixture-work", "Calendar", 208, 104, 26)
        static let birthdays = calendar("fixture-birthdays", "Birthdays", 139, 63, 198)

        static let accounts = [
            CalendarAccount(id: "fixture-google", title: "Google · Trabalho", calendars: [agenda, holidays]),
            CalendarAccount(id: "fixture-exchange", title: "Outlook · Exchange", calendars: [work, birthdays]),
        ]

        static let details: [String: EventDetails] = [
            "Planejamento": EventDetails(
                location: "Sala Júpiter",
                notes: """
                    Pauta:
                    - Prioridades da sprint
                    - Riscos e dependências

                    Reunião do Microsoft Teams
                    Ingressar: https://teams.microsoft.com/l/meetup-join/19%3ameeting_zumpt%40thread.v2/0
                    Documento da sprint: https://example.com/sprints/45
                    """,
                url: nil,
                participants: [
                    person("Ana Souza", .accepted, isOrganizer: true),
                    person("Pedro Alves", .accepted, isCurrentUser: true),
                    person("Carla Mendes", .declined),
                    person("Diego Rocha", .pending),
                    person("Beatriz Lima", .accepted),
                    person("Felipe Nunes", .tentative),
                ],
                recurrence: Recurrence(frequency: .weekly, interval: 1, weekdays: [2])
            ),
            "Fórum de produto": EventDetails(
                location: nil,
                notes: nil,
                url: URL(string: "https://meet.google.com/abc-defg-hij"),
                participants: [
                    person("Beatriz Lima", .accepted, isOrganizer: true),
                    person("Pedro Alves", .pending, isCurrentUser: true),
                    person("Ana Souza", .accepted),
                ],
                recurrence: Recurrence(frequency: .weekly, interval: 2, weekdays: [4])
            ),
            "App Móvel · Daily": EventDetails(
                location: "https://example.zoom.us/j/123456789",
                notes: nil,
                url: nil,
                participants: [],
                recurrence: Recurrence(frequency: .weekly, interval: 1, weekdays: [2, 3, 4, 5, 6])
            ),
        ]

        private static func person(
            _ name: String,
            _ response: ResponseStatus,
            isOrganizer: Bool = false,
            isCurrentUser: Bool = false
        ) -> Participant {
            Participant(
                name: name,
                email: "\(name.lowercased().replacingOccurrences(of: " ", with: "."))@example.com",
                response: response,
                isOrganizer: isOrganizer,
                isCurrentUser: isCurrentUser
            )
        }

        static func events(in week: Week, calendar: Calendar) -> [CalendarEvent] {
            let builder = Builder(week: week, calendar: calendar)
            return [
                builder.allDay("Finados", day: 1, in: holidays),
                builder.allDay("Ponto facultativo", day: 1, in: holidays),
                builder.allDay("Aniversário da Ana", day: 5, in: birthdays),

                builder.timed("App Móvel · Daily", day: 1, from: (9, 30), to: (9, 45), in: work),
                builder.timed("Planejamento", day: 1, from: (11, 0), to: (12, 0), in: work),
                builder.timed("Planejamento", day: 1, from: (11, 0), to: (12, 0), in: agenda),
                builder.timed("Acompanhamento squad", day: 1, from: (15, 0), to: (15, 30), in: agenda),

                builder.timed("App Móvel · Daily", day: 2, from: (9, 30), to: (9, 45), in: work),
                builder.timed("Status do site", day: 2, from: (10, 45), to: (11, 30), in: agenda),
                builder.timed("Pagamentos no app", day: 2, from: (16, 0), to: (17, 0), in: agenda),
                builder.timed("Reunião de liderança", day: 2, from: (17, 0), to: (18, 0), in: agenda),

                builder.timed("App Móvel · Daily", day: 3, from: (9, 30), to: (9, 45), in: work),
                builder.timed("Daily do squad", day: 3, from: (10, 0), to: (10, 15), in: work),
                builder.timed("Fórum de produto", day: 3, from: (11, 0), to: (12, 0), in: agenda),
                builder.timed("ENC: Fórum de produto", day: 3, from: (11, 0), to: (12, 0), in: work),
                builder.timed("Revisão de design", day: 3, from: (11, 30), to: (12, 30), in: work),
                builder.timed("Revisão de design", day: 3, from: (11, 30), to: (12, 30), in: work, copy: 2),
                builder.timed("Fundação / Setup", day: 3, from: (13, 0), to: (14, 0), in: agenda),
                builder.timed("Daily técnica [Suporte]", day: 3, from: (16, 0), to: (16, 15), in: agenda),

                builder.timed("App Móvel · Daily", day: 4, from: (9, 30), to: (9, 45), in: work),
                builder.timed(
                    "Cancelado: Retrospectiva",
                    day: 4,
                    from: (10, 0),
                    to: (11, 0),
                    in: work,
                    isCanceled: true
                ),
                builder.timed("Design system · Follow up", day: 4, from: (14, 30), to: (15, 30), in: agenda),
                builder.timed("Reunião de alinhamento", day: 4, from: (16, 0), to: (17, 0), in: work),
                builder.timed("Happy hour", day: 4, from: (18, 0), to: (19, 0), in: agenda, isDeclined: true),

                builder.timed("App Móvel · Daily", day: 5, from: (9, 30), to: (9, 45), in: work),
                builder.timed("Daily do squad", day: 5, from: (10, 0), to: (10, 15), in: work),
                builder.timed("[Acompanhamento] Squad", day: 5, from: (11, 0), to: (11, 30), in: agenda),
                builder.timed("Daily técnica [Suporte]", day: 5, from: (16, 0), to: (16, 15), in: agenda),
                builder.timed("Plataforma de cursos · V2", day: 5, from: (17, 0), to: (18, 0), in: agenda),
            ]
        }

        private static func calendar(
            _ id: String,
            _ title: String,
            _ red: Double,
            _ green: Double,
            _ blue: Double
        ) -> EventCalendar {
            EventCalendar(
                id: id,
                title: title,
                color: CalendarColor(red: red / 255, green: green / 255, blue: blue / 255)
            )
        }

        private struct Builder {
            let week: Week
            let calendar: Calendar

            func timed(
                _ title: String,
                day: Int,
                from start: (hour: Int, minute: Int),
                to end: (hour: Int, minute: Int),
                in eventCalendar: EventCalendar,
                isDeclined: Bool = false,
                isCanceled: Bool = false,
                copy: Int = 1
            ) -> CalendarEvent {
                CalendarEvent(
                    id: "\(eventCalendar.id)-\(title)-\(day)-\(copy)",
                    title: title,
                    start: time(start, on: week.days[day]),
                    end: time(end, on: week.days[day]),
                    isAllDay: false,
                    calendarID: eventCalendar.id,
                    isDeclined: isDeclined,
                    isCanceled: isCanceled
                )
            }

            func allDay(_ title: String, day: Int, in eventCalendar: EventCalendar) -> CalendarEvent {
                let start = week.days[day]
                guard let end = calendar.date(byAdding: .day, value: 1, to: start) else {
                    preconditionFailure("Calendar could not add a day to \(start)")
                }
                return CalendarEvent(
                    id: "\(eventCalendar.id)-\(title)-\(day)",
                    title: title,
                    start: start,
                    end: end,
                    isAllDay: true,
                    calendarID: eventCalendar.id,
                    isDeclined: false,
                    isCanceled: false
                )
            }

            private func time(_ time: (hour: Int, minute: Int), on day: Date) -> Date {
                guard let date = calendar.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: day) else {
                    preconditionFailure("Calendar could not set \(time) on \(day)")
                }
                return date
            }
        }
    }
#endif
