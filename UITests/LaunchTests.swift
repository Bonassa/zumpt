import XCTest

final class LaunchTests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    @MainActor
    func testShowsTheWeekOfTheGivenDateInPortuguese() {
        let app = launch(language: "pt-BR", locale: "pt_BR")

        assertHeader(in: app, title: "Novembro 2026", number: "Semana 45")
    }

    @MainActor
    func testShowsTheWeekOfTheGivenDateInEnglish() {
        let app = launch(language: "en-BR", locale: "en_BR")

        assertHeader(in: app, title: "November 2026", number: "Week 45")
    }

    @MainActor
    private func launch(language: String, locale: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "--now", "2026-11-04T15:00:00Z",
            "-AppleLanguages", "(\(language))",
            "-AppleLocale", locale,
        ]
        app.launch()
        addTeardownBlock { @MainActor in app.terminate() }
        return app
    }

    @MainActor
    private func assertHeader(in app: XCUIApplication, title: String, number: String) {
        let titleElement = app.staticTexts["week-header-title"]
        XCTAssertTrue(titleElement.waitForExistence(timeout: 5))
        XCTAssertEqual(displayedText(of: titleElement), title)
        XCTAssertEqual(displayedText(of: app.staticTexts["week-header-number"]), number)
        attachWindowScreenshot(of: app)
    }

    @MainActor
    private func attachWindowScreenshot(of app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.windows.firstMatch.screenshot())
        attachment.name = "\(name) window"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    private func displayedText(of element: XCUIElement) -> String {
        let value = element.value as? String ?? ""
        return value.isEmpty ? element.label : value
    }
}
