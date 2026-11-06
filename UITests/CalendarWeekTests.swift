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
    func testShowsTheWeekInTheSystemLanguage() {
        let app = launchApp(language: "en-BR", locale: "en_BR")

        assertWeekHeader(in: app, title: "November 2026", number: "Week 45")
        attachWindowScreenshot(of: app)
    }

    @MainActor
    func testMovesBetweenWeeks() {
        let app = launchApp()
        assertWeekHeader(in: app, title: "Novembro 2026", number: "Semana 45")

        element("next-week", in: app).click()

        assertWeekHeader(in: app, title: "Novembro 2026", number: "Semana 46")
        XCTAssertTrue(element("event-Planejamento", in: app).waitForNonExistence(timeout: 2))
        XCTAssertFalse(element("now-indicator", in: app).exists)

        element("today", in: app).click()

        assertWeekHeader(in: app, title: "Novembro 2026", number: "Semana 45")
        XCTAssertTrue(element("event-Planejamento", in: app).waitForExistence(timeout: 2))

        element("previous-week", in: app).click()

        assertWeekHeader(in: app, title: "Outubro 2026", number: "Semana 44")
    }

    @MainActor
    func testHidingACalendarHidesItsEvents() {
        let app = launchApp()
        let holiday = element("event-Finados", in: app)
        XCTAssertTrue(holiday.waitForExistence(timeout: 5))

        element("calendar-toggle-fixture-holidays", in: app).click()

        XCTAssertTrue(holiday.waitForNonExistence(timeout: 2))
        XCTAssertTrue(element("event-Planejamento", in: app).exists)
        attachWindowScreenshot(of: app)

        element("calendar-toggle-fixture-holidays", in: app).click()

        XCTAssertTrue(holiday.waitForExistence(timeout: 2))
    }

    @MainActor
    func testKeepsTheWorkdayStartAtTheTopWhenTheAllDayRowChangesHeight() {
        let app = launchApp()
        XCTAssertTrue(element("hour-label-8", in: app).waitForExistence(timeout: 5))
        assertWorkdayStartsAtTheTop(in: app)

        element("calendar-toggle-fixture-holidays", in: app).click()
        XCTAssertTrue(element("event-Finados", in: app).waitForNonExistence(timeout: 2))
        assertWorkdayStartsAtTheTop(in: app)

        element("calendar-toggle-fixture-holidays", in: app).click()
        XCTAssertTrue(element("event-Finados", in: app).waitForExistence(timeout: 2))
        assertWorkdayStartsAtTheTop(in: app)

        element("next-week", in: app).click()
        assertWeekHeader(in: app, title: "Novembro 2026", number: "Semana 46")
        assertWorkdayStartsAtTheTop(in: app)
    }
}
