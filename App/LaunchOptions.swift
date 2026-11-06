import Foundation
import ZumptKit

struct LaunchOptions {
    let fixedNow: Date?
    let calendarFixtureAccess: CalendarAccess?

    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        #if DEBUG
            fixedNow = Self.value(after: "--now", in: arguments).flatMap { try? Date($0, strategy: .iso8601) }
            calendarFixtureAccess = Self.value(after: "--calendar-fixture", in: arguments).flatMap(Self.access(named:))
        #else
            fixedNow = nil
            calendarFixtureAccess = nil
        #endif
    }

    private static func value(after flag: String, in arguments: [String]) -> String? {
        guard let flagIndex = arguments.firstIndex(of: flag), arguments.indices.contains(flagIndex + 1) else {
            return nil
        }
        return arguments[flagIndex + 1]
    }

    private static func access(named name: String) -> CalendarAccess? {
        switch name {
        case "granted": .granted
        case "denied": .denied
        case "notDetermined": .notDetermined
        default: nil
        }
    }
}
