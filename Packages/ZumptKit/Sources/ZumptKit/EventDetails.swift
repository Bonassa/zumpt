import Foundation

public enum ResponseStatus: Hashable, Sendable {
    case accepted
    case tentative
    case declined
    case pending
}

public struct Participant: Hashable, Sendable {
    public let name: String
    public let email: String?
    public let response: ResponseStatus
    public let isOrganizer: Bool
    public let isCurrentUser: Bool

    public init(name: String, email: String?, response: ResponseStatus, isOrganizer: Bool, isCurrentUser: Bool) {
        self.name = name
        self.email = email
        self.response = response
        self.isOrganizer = isOrganizer
        self.isCurrentUser = isCurrentUser
    }
}

public struct Recurrence: Hashable, Sendable {
    public enum Frequency: Hashable, Sendable {
        case daily
        case weekly
        case monthly
        case yearly
    }

    public let frequency: Frequency
    public let interval: Int
    public let weekdays: [Int]

    public init(frequency: Frequency, interval: Int, weekdays: [Int]) {
        self.frequency = frequency
        self.interval = interval
        self.weekdays = weekdays
    }

    public var isEveryWeekday: Bool {
        frequency == .weekly && interval == 1 && Set(weekdays) == Set(2...6)
    }
}

public struct ResponseSummary: Hashable, Sendable {
    public let accepted: Int
    public let tentative: Int
    public let declined: Int
    public let pending: Int

    public init(accepted: Int, tentative: Int, declined: Int, pending: Int) {
        self.accepted = accepted
        self.tentative = tentative
        self.declined = declined
        self.pending = pending
    }

    public var total: Int {
        accepted + tentative + declined + pending
    }
}

public struct EventDetails: Hashable, Sendable {
    public let location: String?
    public let notes: String?
    public let url: URL?
    public let participants: [Participant]
    public let recurrence: Recurrence?

    public init(location: String?, notes: String?, url: URL?, participants: [Participant], recurrence: Recurrence?) {
        self.location = location
        self.notes = notes
        self.url = url
        self.participants = participants
        self.recurrence = recurrence
    }

    public var currentUserResponse: ResponseStatus? {
        participants.first(where: \.isCurrentUser)?.response
    }

    public var meetingLink: MeetingLink? {
        MeetingLink.find(in: [url?.absoluteString, location, notes])
    }

    public var responseSummary: ResponseSummary {
        ResponseSummary(
            accepted: participants.count { $0.response == .accepted },
            tentative: participants.count { $0.response == .tentative },
            declined: participants.count { $0.response == .declined },
            pending: participants.count { $0.response == .pending }
        )
    }
}

public struct MeetingLink: Hashable, Sendable {
    public enum Provider: Hashable, Sendable {
        case teams
        case googleMeet
        case zoom
        case webex
        case faceTime
    }

    public let provider: Provider
    public let url: URL

    public static func find(in texts: [String?]) -> MeetingLink? {
        for text in texts.compactMap(\.self) {
            for url in links(in: text) {
                let target = unwrappingSafeLink(url)
                if let provider = provider(of: target) {
                    return MeetingLink(provider: provider, url: target)
                }
            }
        }
        return nil
    }

    private static func links(in text: String) -> [URL] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return []
        }
        return detector.matches(in: text, range: NSRange(text.startIndex..., in: text)).compactMap(\.url)
    }

    private static func unwrappingSafeLink(_ url: URL) -> URL {
        guard
            let host = url.host()?.lowercased(),
            host.hasSuffix("safelinks.protection.outlook.com"),
            let target = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?
                .first(where: { $0.name == "url" })?
                .value,
            let targetURL = URL(string: target)
        else {
            return url
        }
        return targetURL
    }

    private static func provider(of url: URL) -> Provider? {
        guard
            let scheme = url.scheme?.lowercased(),
            scheme == "https" || scheme == "http",
            let host = url.host()?.lowercased()
        else {
            return nil
        }
        let path = url.path().lowercased()

        if host == "teams.microsoft.com" || host == "teams.live.com" {
            return path.hasPrefix("/l/meetup-join") || path.hasPrefix("/meet/") ? .teams : nil
        }
        if host == "meet.google.com" {
            return path.count > 1 ? .googleMeet : nil
        }
        if host == "zoom.us" || host.hasSuffix(".zoom.us") {
            return ["/j/", "/my/", "/w/"].contains(where: path.hasPrefix) ? .zoom : nil
        }
        if host == "webex.com" || host.hasSuffix(".webex.com") {
            return path.contains("/meet/") || path.contains("/j.php") || path.contains("/join") ? .webex : nil
        }
        if host == "facetime.apple.com" {
            return path.hasPrefix("/join") ? .faceTime : nil
        }
        return nil
    }
}
