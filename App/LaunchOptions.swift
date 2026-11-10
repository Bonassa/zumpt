import Foundation
import SwiftUI
import ZumptKit

struct LaunchOptions {
    enum TasksStore: Equatable {
        case memory
        case file(URL)
    }

    let now: () -> Date
    let calendarFixtureAccess: CalendarAccess?
    let tasksStore: TasksStore?
    let taskFixture: String?
    let colorScheme: ColorScheme?

    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        #if DEBUG
            let clockStart = Self.value(after: "--now", in: arguments).flatMap { try? Date($0, strategy: .iso8601) }
            now = Self.clock(startingAt: clockStart)
            calendarFixtureAccess = Self.value(after: "--calendar-fixture", in: arguments).flatMap(Self.access(named:))
            tasksStore =
                Self.value(after: "--tasks-store", in: arguments).map(Self.tasksStore(named:))
                ?? (calendarFixtureAccess == nil ? nil : .memory)
            taskFixture = Self.value(after: "--task-fixture", in: arguments)
            colorScheme = Self.value(after: "--appearance", in: arguments).flatMap(Self.colorScheme(named:))
        #else
            now = { Date() }
            calendarFixtureAccess = nil
            tasksStore = nil
            taskFixture = nil
            colorScheme = nil
        #endif
    }

    private static func clock(startingAt start: Date?) -> () -> Date {
        guard let start else {
            return { Date() }
        }
        let launch = Date()
        return { start.addingTimeInterval(Date().timeIntervalSince(launch)) }
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

    private static func colorScheme(named name: String) -> ColorScheme? {
        switch name {
        case "light": .light
        case "dark": .dark
        default: nil
        }
    }

    private static func tasksStore(named name: String) -> TasksStore {
        guard name != "memory" else {
            return .memory
        }
        return .file(URL(filePath: name, relativeTo: FileManager.default.temporaryDirectory).absoluteURL)
    }
}
