import Foundation

public enum CalendarAccess: Sendable, Equatable {
    case notDetermined
    case granted
    case denied
}

public struct CalendarColor: Hashable, Sendable {
    public let red: Double
    public let green: Double
    public let blue: Double

    public init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }
}

public struct EventCalendar: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let color: CalendarColor

    public init(id: String, title: String, color: CalendarColor) {
        self.id = id
        self.title = title
        self.color = color
    }
}

public struct CalendarAccount: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let calendars: [EventCalendar]

    public init(id: String, title: String, calendars: [EventCalendar]) {
        self.id = id
        self.title = title
        self.calendars = calendars
    }
}

public struct CalendarEvent: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let start: Date
    public let end: Date
    public let isAllDay: Bool
    public let calendarID: String
    public let isDeclined: Bool

    public init(
        id: String,
        title: String,
        start: Date,
        end: Date,
        isAllDay: Bool,
        calendarID: String,
        isDeclined: Bool
    ) {
        self.id = id
        self.title = title
        self.start = start
        self.end = end
        self.isAllDay = isAllDay
        self.calendarID = calendarID
        self.isDeclined = isDeclined
    }
}
