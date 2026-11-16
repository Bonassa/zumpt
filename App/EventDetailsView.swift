import SwiftUI
import ZumptKit

struct EventDetailsView: View {
    let event: CalendarEvent

    @Environment(CalendarModel.self) private var model
    @Environment(\.locale) private var locale
    @Environment(\.openURL) private var openURL

    var body: some View {
        let details = model.details(of: event)
        let placement = model.placement(ofCalendar: event.calendarID)
        let meetingLink = details?.meetingLink
        VStack(alignment: .leading, spacing: 14) {
            header(color: placement?.calendar.color ?? .unknown, recurrence: details?.recurrence)

            if let meetingLink {
                Button {
                    openURL(meetingLink.url)
                } label: {
                    Label {
                        Text("Join \(Self.name(of: meetingLink.provider))")
                    } icon: {
                        Image(systemName: "video.fill")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityIdentifier("join-meeting")
            }

            VStack(alignment: .leading, spacing: 8) {
                if let location = details?.location {
                    DetailRow(systemImage: "mappin.and.ellipse") {
                        Text(verbatim: location)
                            .textSelection(.enabled)
                    }
                    .accessibilityIdentifier("event-details-location")
                }
                if let placement {
                    DetailRow(systemImage: "circle.fill", iconColor: placement.calendar.color.color) {
                        Text(verbatim: "\(placement.calendar.title) · \(placement.account.title)")
                    }
                    .accessibilityIdentifier("event-details-calendar")
                }
                if let response = details?.currentUserResponse {
                    DetailRow(
                        systemImage: ResponseIcon.symbol(for: response),
                        iconColor: ResponseIcon.color(for: response)
                    ) {
                        Text(Self.currentUserText(for: response))
                    }
                    .accessibilityIdentifier("event-details-response")
                }
                if let url = details?.url, url != meetingLink?.url {
                    DetailRow(systemImage: "link") {
                        Link(url.host() ?? url.absoluteString, destination: url)
                            .lineLimit(1)
                    }
                }
            }

            if let details, !details.participants.isEmpty {
                Divider()
                GuestList(details: details)
            }

            if let notes = details?.notes {
                Divider()
                NotesView(notes: notes)
            }

            if let calendarAppURL = model.calendarAppURL(for: event) {
                Divider()
                Button {
                    openURL(calendarAppURL)
                } label: {
                    Label("Open in Calendar", systemImage: "calendar")
                }
                .buttonStyle(.borderless)
                .accessibilityIdentifier("open-in-calendar")
            }
        }
        .font(.system(size: 12.5))
        .padding(16)
        .frame(width: 340, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("event-details")
    }

    private func header(color: CalendarColor, recurrence: Recurrence?) -> some View {
        HStack(alignment: .top, spacing: 10) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color.color)
                .frame(width: 10, height: 10)
                .padding(.top, 5)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                EventTitle(event: event)
                    .font(.system(size: 15, weight: .semibold))
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
                    .accessibilityIdentifier("event-details-title")
                Text(timeText)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("event-details-time")
                if let recurrence {
                    Label {
                        RecurrenceText(recurrence: recurrence)
                    } icon: {
                        Image(systemName: "repeat")
                    }
                    .foregroundStyle(.secondary)
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("event-details-recurrence")
                }
            }
        }
    }

    private var timeText: String {
        let calendar = model.calendar
        let dayStyle = Date.FormatStyle(locale: locale, calendar: calendar).weekday(.wide).day().month(.wide)
        if event.isAllDay {
            let lastDay = event.end.addingTimeInterval(-1)
            guard calendar.isDate(event.start, inSameDayAs: lastDay) else {
                return (event.start..<lastDay).formatted(
                    Date.IntervalFormatStyle(date: .long, time: .omitted, locale: locale)
                )
            }
            let day = Self.capitalizingFirstLetter(of: event.start.formatted(dayStyle), locale: locale)
            return "\(day) · \(String(localized: "All day"))"
        }
        guard calendar.isDate(event.start, inSameDayAs: event.end.addingTimeInterval(-1)) else {
            return (event.start..<event.end).formatted(
                Date.IntervalFormatStyle(date: .abbreviated, time: .shortened, locale: locale)
            )
        }
        let day = Self.capitalizingFirstLetter(of: event.start.formatted(dayStyle), locale: locale)
        let hours = (event.start..<event.end).formatted(
            Date.IntervalFormatStyle(date: .omitted, time: .shortened, locale: locale)
        )
        return "\(day) · \(hours)"
    }

    static func capitalizingFirstLetter(of text: String, locale: Locale) -> String {
        text.prefix(1).uppercased(with: locale) + text.dropFirst()
    }

    private static func name(of provider: MeetingLink.Provider) -> String {
        switch provider {
        case .teams: "Microsoft Teams"
        case .googleMeet: "Google Meet"
        case .zoom: "Zoom"
        case .webex: "Webex"
        case .faceTime: "FaceTime"
        }
    }

    private static func currentUserText(for response: ResponseStatus) -> LocalizedStringKey {
        switch response {
        case .accepted: "You accepted"
        case .tentative: "You said maybe"
        case .declined: "You declined"
        case .pending: "You haven't responded"
        }
    }
}

struct DetailRow<Content: View>: View {
    let systemImage: String
    var iconColor: Color = .secondary
    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: systemImage == "circle.fill" ? 8 : 12))
                .foregroundStyle(iconColor)
                .frame(width: 16)
                .accessibilityHidden(true)
            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct RecurrenceText: View {
    let recurrence: Recurrence

    @Environment(\.locale) private var locale

    var body: some View {
        switch recurrence.frequency {
        case .daily:
            recurrence.interval == 1 ? Text("Every day") : Text("Every \(recurrence.interval) days")
        case .weekly:
            weekly
        case .monthly:
            recurrence.interval == 1 ? Text("Every month") : Text("Every \(recurrence.interval) months")
        case .yearly:
            recurrence.interval == 1 ? Text("Every year") : Text("Every \(recurrence.interval) years")
        }
    }

    private var weekly: Text {
        if recurrence.isEveryWeekday {
            return Text("Every weekday")
        }
        if recurrence.interval > 1 {
            return Text("Every \(recurrence.interval) weeks")
        }
        if recurrence.weekdays.isEmpty {
            return Text("Every week")
        }
        return Text("Every week on \(weekdayList)")
    }

    private var weekdayList: String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        let symbols = calendar.shortWeekdaySymbols
        return recurrence.weekdays
            .sorted()
            .compactMap { symbols.indices.contains($0 - 1) ? symbols[$0 - 1] : nil }
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: ".")).lowercased(with: locale) }
            .formatted(.list(type: .and).locale(locale))
    }
}

private struct GuestList: View {
    let details: EventDetails

    @Environment(\.locale) private var locale

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            DetailRow(systemImage: "person.2") {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(details.participants.count) guests")
                        .fontWeight(.medium)
                    Text(summary)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityIdentifier("event-details-guests")
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(details.participants.enumerated()), id: \.offset) { _, participant in
                        ParticipantRow(participant: participant)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 168)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.leading, 24)
        }
    }

    private var summary: String {
        let counts = details.responseSummary
        return [
            counts.accepted > 0 ? String(localized: "\(counts.accepted) yes") : nil,
            counts.tentative > 0 ? String(localized: "\(counts.tentative) maybe") : nil,
            counts.declined > 0 ? String(localized: "\(counts.declined) no") : nil,
            counts.pending > 0 ? String(localized: "\(counts.pending) awaiting") : nil,
        ]
        .compactMap(\.self)
        .formatted(.list(type: .and).locale(locale))
    }
}

private struct ParticipantRow: View {
    let participant: Participant

    var body: some View {
        HStack(spacing: 8) {
            ResponseIcon(status: participant.response)
            Text(verbatim: participant.name)
                .lineLimit(1)
                .truncationMode(.tail)
                .help(participant.email ?? participant.name)
            if participant.isOrganizer {
                Text("Organizer")
                    .foregroundStyle(.secondary)
            } else if participant.isCurrentUser {
                Text("You")
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct ResponseIcon: View {
    let status: ResponseStatus

    var body: some View {
        Image(systemName: Self.symbol(for: status))
            .font(.system(size: 11))
            .foregroundStyle(Self.color(for: status))
            .frame(width: 14)
            .accessibilityLabel(Self.label(for: status))
    }

    static func symbol(for status: ResponseStatus) -> String {
        switch status {
        case .accepted: "checkmark.circle.fill"
        case .tentative: "questionmark.circle.fill"
        case .declined: "xmark.circle.fill"
        case .pending: "circle.dashed"
        }
    }

    static func color(for status: ResponseStatus) -> Color {
        switch status {
        case .accepted: .green
        case .tentative: .orange
        case .declined: .red
        case .pending: .secondary
        }
    }

    private static func label(for status: ResponseStatus) -> LocalizedStringKey {
        switch status {
        case .accepted: "Accepted"
        case .tentative: "Maybe"
        case .declined: "Declined"
        case .pending: "Awaiting response"
        }
    }
}

private struct NotesView: View {
    let notes: String

    var body: some View {
        ScrollView {
            Text(linkified)
                .font(.system(size: 12))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: 180)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityIdentifier("event-details-notes")
    }

    private var linkified: AttributedString {
        let text = notes.trimmingCharacters(in: .whitespacesAndNewlines).replacing(/\n{3,}/, with: "\n\n")
        var attributed = AttributedString(text)
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return attributed
        }
        for match in detector.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
            if let url = match.url, let range = Range(match.range, in: attributed) {
                attributed[range].link = url
            }
        }
        return attributed
    }
}
