import XCTest

final class CalendarAccessTests: ZumptTestCase {
    @MainActor
    func testAsksForAccessBeforeShowingTheWeek() {
        let app = launchApp(calendarAccess: "notDetermined")
        let allowButton = element("allow-calendar-access", in: app)
        XCTAssertTrue(allowButton.waitForExistence(timeout: 5))
        attachWindowScreenshot(of: app)

        allowButton.click()

        assertWeekHeader(in: app, title: "Novembro 2026", number: "Semana 45")
        XCTAssertTrue(element("event-Planejamento", in: app).exists)
        assertWorkdayStartsAtTheTop(in: app)
        attachWindowScreenshot(of: app)
    }

    @MainActor
    func testExplainsHowToTurnOnAccessWhenItIsOff() {
        let app = launchApp(calendarAccess: "denied")

        XCTAssertTrue(element("open-system-settings", in: app).waitForExistence(timeout: 5))
        XCTAssertFalse(element("week-header-title", in: app).exists)
        attachWindowScreenshot(of: app)
    }
}
