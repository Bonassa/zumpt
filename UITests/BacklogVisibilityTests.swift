import XCTest

final class BacklogVisibilityTests: ZumptTestCase {
    @MainActor
    func testHidesAndShowsTheBacklogFromTheToolbarAndTheKeyboard() {
        let app = launchApp(taskFixture: "backlog")
        let backlog = element("backlog", in: app)
        XCTAssertTrue(backlog.waitForExistence(timeout: 5))
        let friday = element("day-column-2026-11-06", in: app)
        let fridayEdge = friday.frame.maxX

        click("backlog-toggle", in: app)

        XCTAssertTrue(backlog.waitForNonExistence(timeout: 2))
        XCTAssertGreaterThan(friday.frame.maxX, fridayEdge + 200, "The week takes the backlog's place")
        attachWindowScreenshot(of: app)

        click("backlog-toggle", in: app)

        XCTAssertTrue(backlog.waitForExistence(timeout: 2))

        app.typeKey("b", modifierFlags: [.command, .option])

        XCTAssertTrue(backlog.waitForNonExistence(timeout: 2))

        app.typeKey("b", modifierFlags: [.command, .option])

        XCTAssertTrue(backlog.waitForExistence(timeout: 2))
    }

    @MainActor
    func testCommandNShowsAHiddenBacklog() {
        let app = launchApp()
        XCTAssertTrue(element("backlog", in: app).waitForExistence(timeout: 5))
        click("backlog-toggle", in: app)
        XCTAssertTrue(element("backlog", in: app).waitForNonExistence(timeout: 2))

        addTask("Renovar CNH", in: app)

        XCTAssertTrue(element("backlog-task-Renovar CNH", in: app).waitForExistence(timeout: 2))
    }

    @MainActor
    func testPickingAFilterShowsAHiddenBacklog() {
        let app = launchApp(taskFixture: "backlog,overdue")
        XCTAssertTrue(element("backlog", in: app).waitForExistence(timeout: 5))
        click("backlog-toggle", in: app)
        XCTAssertTrue(element("backlog", in: app).waitForNonExistence(timeout: 2))
        showSidebarTab("Backlog", in: app)

        click("backlog-filter-overdue", in: app)

        XCTAssertTrue(element("backlog-task-Enviar NF de outubro", in: app).waitForExistence(timeout: 2))
        XCTAssertFalse(element("backlog-task-Pagar conta de luz", in: app).exists)
    }

    @MainActor
    func testPickingTheSelectedFilterShowsAHiddenBacklog() {
        let app = launchApp(taskFixture: "backlog")
        XCTAssertTrue(element("backlog", in: app).waitForExistence(timeout: 5))
        click("backlog-toggle", in: app)
        XCTAssertTrue(element("backlog", in: app).waitForNonExistence(timeout: 2))
        showSidebarTab("Backlog", in: app)

        click("backlog-filter-all", in: app)

        XCTAssertTrue(element("backlog", in: app).waitForExistence(timeout: 2))
        XCTAssertTrue(element("backlog-task-Marcar dentista", in: app).exists)
    }

    @MainActor
    func testKeepsTheLayoutAfterQuittingAndOpeningAgain() {
        let app = launchApp(taskFixture: "backlog", preferences: "zumpt-ui-tests-layout")
        XCTAssertTrue(element("backlog", in: app).waitForExistence(timeout: 5))
        showSidebarTab("Backlog", in: app)
        XCTAssertTrue(element("backlog-filter-all", in: app).waitForExistence(timeout: 2))
        click("backlog-toggle", in: app)
        XCTAssertTrue(element("backlog", in: app).waitForNonExistence(timeout: 2))

        app.typeKey("q", modifierFlags: .command)
        XCTAssertTrue(app.wait(for: .notRunning, timeout: 5))
        app.launchArguments.removeAll { $0 == "--reset-preferences" }
        app.launch()

        XCTAssertTrue(element("backlog-filter-all", in: app).waitForExistence(timeout: 5))
        XCTAssertFalse(element("calendar-toggle-fixture-agenda", in: app).exists)
        XCTAssertFalse(element("backlog", in: app).exists)
        attachWindowScreenshot(of: app)
    }
}
