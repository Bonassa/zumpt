import Foundation
import Observation
import ZumptKit

@Observable
final class CalendarModel {
    private(set) var access: CalendarAccess
    private(set) var accounts: [CalendarAccount] = []
    private(set) var week: Week
    private(set) var hiddenCalendarIDs: Set<String>
    private var events: [CalendarEvent] = []

    let calendar: Calendar
    let now: () -> Date

    private let store: any CalendarStore
    private let defaults: UserDefaults

    private static let hiddenCalendarIDsKey = "hiddenCalendarIDs"

    init(store: any CalendarStore, calendar: Calendar, defaults: UserDefaults, now: @escaping () -> Date) {
        self.store = store
        self.calendar = calendar
        self.defaults = defaults
        self.now = now
        access = store.access
        week = Week(containing: now(), calendar: calendar)
        hiddenCalendarIDs = Set(defaults.stringArray(forKey: Self.hiddenCalendarIDsKey) ?? [])
        reload()
    }

    var visibleEvents: [CalendarEvent] {
        EventFilter.visible(
            events,
            hiddenCalendarIDs: hiddenCalendarIDs,
            calendarOrder: accounts.flatMap(\.calendars).map(\.id)
        )
    }

    var calendarColors: [String: CalendarColor] {
        Dictionary(
            accounts.flatMap(\.calendars).map { ($0.id, $0.color) },
            uniquingKeysWith: { first, _ in first }
        )
    }

    func requestAccess() async {
        access = await store.requestAccess()
        reload()
    }

    func refresh() {
        reload()
    }

    func observeStoreChanges() async {
        for await _ in store.changes {
            reload()
        }
    }

    func showPreviousWeek() {
        show(week.adding(weeks: -1, calendar: calendar))
    }

    func showNextWeek() {
        show(week.adding(weeks: 1, calendar: calendar))
    }

    func showToday() {
        show(Week(containing: now(), calendar: calendar))
    }

    func isVisible(calendarID: String) -> Bool {
        !hiddenCalendarIDs.contains(calendarID)
    }

    func setVisible(_ isVisible: Bool, calendarID: String) {
        if isVisible {
            hiddenCalendarIDs.remove(calendarID)
        } else {
            hiddenCalendarIDs.insert(calendarID)
        }
        defaults.set(hiddenCalendarIDs.sorted(), forKey: Self.hiddenCalendarIDsKey)
    }

    private func show(_ newWeek: Week) {
        guard newWeek != week else {
            return
        }
        week = newWeek
        reloadEvents()
    }

    private func reload() {
        access = store.access
        guard access == .granted else {
            accounts = []
            events = []
            return
        }
        accounts = store.accounts()
        reloadEvents()
    }

    private func reloadEvents() {
        events = store.events(in: week.interval(in: calendar))
    }
}

extension CalendarModel {
    static func make(options: LaunchOptions) -> CalendarModel {
        let calendar = Calendar.autoupdatingCurrent
        let now: () -> Date
        if let fixedNow = options.fixedNow {
            now = { fixedNow }
        } else {
            now = { Date() }
        }

        #if DEBUG
            if let fixtureAccess = options.calendarFixtureAccess {
                return CalendarModel(
                    store: FixtureCalendarStore(
                        access: fixtureAccess,
                        week: Week(containing: now(), calendar: calendar),
                        calendar: calendar
                    ),
                    calendar: calendar,
                    defaults: fixtureDefaults(),
                    now: now
                )
            }
        #endif

        return CalendarModel(store: EventKitCalendarStore(), calendar: calendar, defaults: .standard, now: now)
    }

    #if DEBUG
        private static func fixtureDefaults() -> UserDefaults {
            let suiteName = "com.renanbonassa.zumpt.fixture"
            guard let defaults = UserDefaults(suiteName: suiteName) else {
                preconditionFailure("Could not open the \(suiteName) defaults suite")
            }
            defaults.removePersistentDomain(forName: suiteName)
            return defaults
        }
    #endif
}
