import XCTest

final class TimeFormatTests: ZumptTestCase {
    @MainActor
    func testUsesTheTwentyFourHourClockOfTheRegionWhenTheAppIsInEnglish() {
        let app = launchApp(language: "en-BR", locale: "en_BR")
        XCTAssertTrue(element("hour-label-8", in: app).waitForExistence(timeout: 5))

        XCTAssertEqual(displayedText(of: element("hour-label-8", in: app)), "08:00")

        click("event-Planejamento", in: app)

        XCTAssertTrue(element("event-details", in: app).waitForExistence(timeout: 3))
        XCTAssertTrue(displayedText(of: element("event-details-time", in: app)).contains("11:00"))
        XCTAssertFalse(displayedText(of: element("event-details-time", in: app)).contains("AM"))
    }

    @MainActor
    func testUsesTheTwelveHourClockWhereTheRegionDoes() {
        let app = launchApp(language: "en-US", locale: "en_US")
        XCTAssertTrue(element("hour-label-8", in: app).waitForExistence(timeout: 5))

        XCTAssertEqual(displayedText(of: element("hour-label-8", in: app)), "8 AM")

        click("event-Planejamento", in: app)

        XCTAssertTrue(element("event-details", in: app).waitForExistence(timeout: 3))
        XCTAssertTrue(displayedText(of: element("event-details-time", in: app)).contains("PM"))
    }
}
