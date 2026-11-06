import XCTest

class ZumptTestCase: XCTestCase {
    static let fixedNow = "2026-11-04T15:00:00Z"

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    @MainActor
    func launchApp(
        calendarAccess: String = "granted",
        language: String = "pt-BR",
        locale: String = "pt_BR"
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "--now", Self.fixedNow,
            "--calendar-fixture", calendarAccess,
            "-AppleLanguages", "(\(language))",
            "-AppleLocale", locale,
        ]
        app.launch()
        addTeardownBlock { @MainActor in app.terminate() }
        return app
    }

    @MainActor
    func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)[identifier].firstMatch
    }

    @MainActor
    func click(_ identifier: String, in app: XCUIApplication) {
        app.activate()
        element(identifier, in: app).click()
    }

    @MainActor
    func count(of identifier: String, in app: XCUIApplication) -> Int {
        app.descendants(matching: .any).matching(identifier: identifier).count
    }

    @MainActor
    func displayedText(of element: XCUIElement) -> String {
        let value = element.value as? String ?? ""
        return value.isEmpty ? element.label : value
    }

    @MainActor
    func assertWeekHeader(in app: XCUIApplication, title: String, number: String) {
        let titleElement = element("week-header-title", in: app)
        XCTAssertTrue(titleElement.waitForExistence(timeout: 5))
        XCTAssertEqual(displayedText(of: titleElement), title)
        XCTAssertEqual(displayedText(of: element("week-header-number", in: app)), number)
    }

    @MainActor
    func assertWorkdayStartsAtTheTop(
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let gap = element("hour-label-8", in: app).frame.midY - element("all-day-row", in: app).frame.maxY
        XCTAssertEqual(gap, 10.5, accuracy: 2, "08:00 should sit right below the all-day row", file: file, line: line)
    }

    @MainActor
    func attachWindowScreenshot(of app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.windows.firstMatch.screenshot())
        attachment.name = "\(name) window"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
