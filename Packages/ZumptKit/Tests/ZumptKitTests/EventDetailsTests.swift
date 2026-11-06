import Foundation
import Testing
import ZumptKit

struct EventDetailsTests {
    @Test func findsATeamsLinkInTheNotesOfAnOutlookInvite() throws {
        let notes = """
            Pauta da semana

            ________________________________________________________________________________
            Reunião do Microsoft Teams
            Ingressar: <https://teams.microsoft.com/l/meetup-join/19%3ameeting_NjA%40thread.v2/0?context=%7b%22Tid%22%7d>
            ID da Reunião: 123 456 789
            ________________________________________________________________________________
            """

        let link = try #require(details(notes: notes).meetingLink)

        #expect(link.provider == .teams)
        #expect(link.url.absoluteString.hasPrefix("https://teams.microsoft.com/l/meetup-join/19%3ameeting_NjA"))
    }

    @Test func prefersTheEventURLOverLinksInTheNotes() throws {
        let link = try #require(
            details(
                notes: "Backup: https://teams.microsoft.com/l/meetup-join/abc",
                url: URL(string: "https://example.zoom.us/j/123456789")
            )
            .meetingLink
        )

        #expect(link.provider == .zoom)
    }

    @Test func findsAGoogleMeetLinkInTheLocation() throws {
        let link = try #require(details(location: "https://meet.google.com/abc-defg-hij").meetingLink)

        #expect(link.provider == .googleMeet)
        #expect(link.url.absoluteString == "https://meet.google.com/abc-defg-hij")
    }

    @Test func unwrapsOutlookSafeLinks() throws {
        let wrapped =
            "https://nam12.safelinks.protection.outlook.com/?url=https%3A%2F%2Fmeet.google.com%2Fabc-defg-hij&data=05"

        let link = try #require(details(notes: "Entrar: \(wrapped)").meetingLink)

        #expect(link.provider == .googleMeet)
        #expect(link.url.absoluteString == "https://meet.google.com/abc-defg-hij")
    }

    @Test func recognizesWebexAndFaceTimeLinks() throws {
        let webex = try #require(details(notes: "https://example.webex.com/meet/pedro").meetingLink)
        let faceTime = try #require(details(notes: "https://facetime.apple.com/join#v=1&p=abc").meetingLink)

        #expect(webex.provider == .webex)
        #expect(faceTime.provider == .faceTime)
    }

    @Test func ignoresLinksThatAreNotMeetings() {
        let details = details(
            location: "Sala Júpiter",
            notes: "Docs: https://example.com/docs e https://teams.microsoft.com/l/channel/abc",
            url: URL(string: "https://zoom.us/pricing")
        )

        #expect(details.meetingLink == nil)
    }

    @Test func summarizesResponsesAndFindsTheCurrentUserResponse() {
        let details = details(participants: [
            participant("Ana", .accepted, isOrganizer: true),
            participant("Pedro", .tentative, isCurrentUser: true),
            participant("Beatriz", .accepted),
            participant("Felipe", .declined),
            participant("Diego", .pending),
        ])

        #expect(details.responseSummary == ResponseSummary(accepted: 2, tentative: 1, declined: 1, pending: 1))
        #expect(details.responseSummary.total == 5)
        #expect(details.currentUserResponse == .tentative)
    }

    @Test func hasNoCurrentUserResponseWhenTheUserIsNotInvited() {
        #expect(details(participants: [participant("Ana", .accepted, isOrganizer: true)]).currentUserResponse == nil)
    }

    @Test func recognizesARecurrenceOnEveryWeekday() {
        #expect(Recurrence(frequency: .weekly, interval: 1, weekdays: [6, 2, 3, 4, 5]).isEveryWeekday)
        #expect(!Recurrence(frequency: .weekly, interval: 2, weekdays: [2, 3, 4, 5, 6]).isEveryWeekday)
        #expect(!Recurrence(frequency: .weekly, interval: 1, weekdays: [2, 4]).isEveryWeekday)
        #expect(!Recurrence(frequency: .daily, interval: 1, weekdays: []).isEveryWeekday)
    }

    private func details(
        location: String? = nil,
        notes: String? = nil,
        url: URL? = nil,
        participants: [Participant] = []
    ) -> EventDetails {
        EventDetails(location: location, notes: notes, url: url, participants: participants, recurrence: nil)
    }

    private func participant(
        _ name: String,
        _ response: ResponseStatus,
        isOrganizer: Bool = false,
        isCurrentUser: Bool = false
    ) -> Participant {
        Participant(
            name: name,
            email: nil,
            response: response,
            isOrganizer: isOrganizer,
            isCurrentUser: isCurrentUser
        )
    }
}
