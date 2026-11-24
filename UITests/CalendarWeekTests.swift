import XCTest

final class CalendarWeekTests: ZumptTestCase {
    @MainActor
    func testShowsTheWeekWithEventsFromTheConnectedCalendars() {
        let app = launchApp()

        assertWeekHeader(in: app, title: "Novembro 2026", number: "Semana 45")
        XCTAssertTrue(element("event-Planejamento", in: app).exists)
        XCTAssertTrue(element("event-Fórum de produto", in: app).exists)
        XCTAssertTrue(element("event-Revisão de design", in: app).exists)
        XCTAssertTrue(element("event-Finados", in: app).exists)
        XCTAssertTrue(element("now-indicator", in: app).exists)
        XCTAssertFalse(element("event-Happy hour", in: app).exists, "Declined events stay hidden")
        attachWindowScreenshot(of: app)
    }

    @MainActor
    func testShowsMondayToFridayInEvenlySizedColumns() {
        let app = launchApp()
        XCTAssertTrue(element("event-Planejamento", in: app).waitForExistence(timeout: 5))

        let workingDays = ["2026-11-02", "2026-11-03", "2026-11-04", "2026-11-05", "2026-11-06"]
        XCTAssertTrue(workingDays.allSatisfy { element("day-column-\($0)", in: app).exists })
        XCTAssertFalse(element("day-column-2026-11-01", in: app).exists, "Sunday is left out")
        XCTAssertFalse(element("day-column-2026-11-07", in: app).exists, "Saturday is left out")
        XCTAssertEqual(count(of: "event-Aniversário da Ana", in: app), 1, "Friday's all-day event stays")

        click("next-week", in: app)

        let nextWorkingDays = ["2026-11-09", "2026-11-10", "2026-11-11", "2026-11-12", "2026-11-13"]
        let columns = nextWorkingDays.map { element("day-column-\($0)", in: app) }
        XCTAssertTrue(columns[0].waitForExistence(timeout: 2))
        XCTAssertTrue(columns.allSatisfy(\.exists), "Every working day has a column")
        let widths = columns.map(\.frame.width)
        for width in widths {
            XCTAssertEqual(width, widths[0], accuracy: 1, "Columns share the width evenly: \(widths)")
        }
        for (left, right) in zip(columns, columns.dropFirst()) {
            XCTAssertEqual(right.frame.minX, left.frame.maxX, accuracy: 1, "Columns sit side by side in order")
        }
    }

    @MainActor
    func testShowsTheComingWeekOnTheWeekend() {
        let app = launchApp(now: "2026-11-07T15:00:00Z")

        assertWeekHeader(in: app, title: "Novembro 2026", number: "Semana 46")
        XCTAssertTrue(element("day-column-2026-11-09", in: app).exists)
        XCTAssertFalse(element("day-column-2026-11-07", in: app).exists)
        XCTAssertFalse(element("now-indicator", in: app).exists, "Today is not in the week")
        attachWindowScreenshot(of: app)

        click("previous-week", in: app)

        assertWeekHeader(in: app, title: "Novembro 2026", number: "Semana 45")
        XCTAssertTrue(element("event-Planejamento", in: app).waitForNonExistence(timeout: 2))
        XCTAssertFalse(element("now-indicator", in: app).exists, "Saturday is past Friday's column")

        click("today", in: app)

        assertWeekHeader(in: app, title: "Novembro 2026", number: "Semana 46")
        XCTAssertTrue(element("event-Planejamento", in: app).waitForExistence(timeout: 2))
    }

    @MainActor
    func testShowsTheWeekInTheSystemLanguage() {
        let app = launchApp(language: "en-BR", locale: "en_BR")

        assertWeekHeader(in: app, title: "November 2026", number: "Week 45")
        attachWindowScreenshot(of: app)
    }

    @MainActor
    func testMovesBetweenWeeks() {
        let app = launchApp()
        assertWeekHeader(in: app, title: "Novembro 2026", number: "Semana 45")

        click("next-week", in: app)

        assertWeekHeader(in: app, title: "Novembro 2026", number: "Semana 46")
        XCTAssertTrue(element("event-Planejamento", in: app).waitForNonExistence(timeout: 2))
        XCTAssertFalse(element("now-indicator", in: app).exists)

        click("today", in: app)

        assertWeekHeader(in: app, title: "Novembro 2026", number: "Semana 45")
        XCTAssertTrue(element("event-Planejamento", in: app).waitForExistence(timeout: 2))

        click("previous-week", in: app)

        assertWeekHeader(in: app, title: "Outubro 2026", number: "Semana 44")
    }

    @MainActor
    func testHidingACalendarHidesItsEvents() {
        let app = launchApp()
        let holiday = element("event-Finados", in: app)
        XCTAssertTrue(holiday.waitForExistence(timeout: 5))

        click("calendar-toggle-fixture-holidays", in: app)

        XCTAssertTrue(holiday.waitForNonExistence(timeout: 2))
        XCTAssertTrue(element("event-Planejamento", in: app).exists)
        attachWindowScreenshot(of: app)

        click("calendar-toggle-fixture-holidays", in: app)

        XCTAssertTrue(holiday.waitForExistence(timeout: 2))
    }

    @MainActor
    func testShowsAMeetingFromSeveralCalendarsOnce() {
        let app = launchApp()
        XCTAssertTrue(element("event-Planejamento", in: app).waitForExistence(timeout: 5))
        XCTAssertEqual(count(of: "event-Planejamento", in: app), 1)
        XCTAssertTrue(element("event-Fórum de produto", in: app).exists)
        XCTAssertFalse(element("event-ENC: Fórum de produto", in: app).exists, "A forwarded copy is the same meeting")

        click("calendar-toggle-fixture-agenda", in: app)

        XCTAssertTrue(element("event-ENC: Fórum de produto", in: app).waitForExistence(timeout: 2))
        XCTAssertEqual(count(of: "event-Planejamento", in: app), 1, "The copy from the other calendar takes over")
    }

    @MainActor
    func testShowsRepeatedInvitesOnceAndHidesCanceledMeetings() {
        let app = launchApp()
        XCTAssertTrue(element("event-Revisão de design", in: app).waitForExistence(timeout: 5))

        XCTAssertEqual(
            count(of: "event-Revisão de design", in: app),
            1,
            "Copies of an invite in the same calendar are the same meeting"
        )
        XCTAssertFalse(element("event-Cancelado: Retrospectiva", in: app).exists, "Canceled meetings stay hidden")
    }

    @MainActor
    func testKeepsTheWorkdayStartAtTheTopWhenTheAllDayRowChangesHeight() {
        let app = launchApp()
        XCTAssertTrue(element("hour-label-8", in: app).waitForExistence(timeout: 5))
        assertWorkdayStartsAtTheTop(in: app)

        click("calendar-toggle-fixture-holidays", in: app)
        XCTAssertTrue(element("event-Finados", in: app).waitForNonExistence(timeout: 2))
        assertWorkdayStartsAtTheTop(in: app)

        click("calendar-toggle-fixture-holidays", in: app)
        XCTAssertTrue(element("event-Finados", in: app).waitForExistence(timeout: 2))
        assertWorkdayStartsAtTheTop(in: app)

        click("next-week", in: app)
        assertWeekHeader(in: app, title: "Novembro 2026", number: "Semana 46")
        assertWorkdayStartsAtTheTop(in: app)
    }
}
