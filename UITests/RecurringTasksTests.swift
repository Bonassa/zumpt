import XCTest

final class RecurringTasksTests: ZumptTestCase {
    @MainActor
    func testCreatesAnAllDaySeriesValidatesIntervalAndUndoesRuleChange() {
        let app = launchApp(language: "en", locale: "en_US")
        addTask("Routine", in: app)
        openRepetition(for: element("backlog-task-Routine", in: app), in: app)
        let save = element("recurrence-save", in: app)
        setInterval("0", in: app)
        XCTAssertFalse(save.isEnabled)
        setInterval("1", in: app)
        XCTAssertTrue(save.isEnabled)
        save.click()

        let backlogTask = element("backlog-task-Routine", in: app)
        XCTAssertTrue(backlogTask.waitForNonExistence(timeout: 3))
        let first = occurrence("Routine", day: "2026-11-04", in: app)
        let next = occurrence("Routine", day: "2026-11-05", in: app)
        XCTAssertTrue(first.waitForExistence(timeout: 3))
        XCTAssertTrue(next.exists)

        openRepetition(for: first, in: app)
        setInterval("2", in: app)
        save.click()
        XCTAssertTrue(next.waitForNonExistence(timeout: 3))
        XCTAssertTrue(occurrence("Routine", day: "2026-11-06", in: app).exists)

        app.typeKey("z", modifierFlags: .command)
        XCTAssertTrue(next.waitForExistence(timeout: 3))
        XCTAssertTrue(first.exists)
        click("next-week", in: app)
        XCTAssertTrue(occurrence("Routine", day: "2026-11-11", in: app).waitForExistence(timeout: 3))
    }

    @MainActor
    func testSeriesAndOccurrenceRenameSurviveReopeningWithoutBacklogEntries() {
        let store = "recurrence-\(UUID().uuidString).store"
        let app = launchApp(language: "en", locale: "en_US", tasksStore: store)
        addTask("Routine", in: app)
        addTask("One-off", in: app)
        openRepetition(for: element("backlog-task-Routine", in: app), in: app)
        click("recurrence-save", in: app)

        let wednesday = occurrence("Routine", day: "2026-11-04", in: app)
        XCTAssertTrue(wednesday.waitForExistence(timeout: 3))
        wednesday.click()
        XCTAssertTrue(element("task-details", in: app).waitForExistence(timeout: 3))
        click("task-details-rename", in: app)
        let title = element("occurrence-title", in: app)
        XCTAssertTrue(title.waitForExistence(timeout: 3))
        title.click()
        app.typeKey("a", modifierFlags: .command)
        app.typeText("Exception")
        click("occurrence-scope-apply", in: app)
        XCTAssertTrue(occurrence("Exception", day: "2026-11-04", in: app).waitForExistence(timeout: 3))
        app.terminate()

        for _ in 0..<2 {
            let reopened = launchApp(
                language: "en", locale: "en_US", tasksStore: store, now: "2026-11-06T15:00:00Z"
            )
            let exception = occurrence("Exception", day: "2026-11-04", in: reopened)
            XCTAssertTrue(exception.waitForExistence(timeout: 3))
            XCTAssertTrue(exception.label.contains("Overdue"))
            XCTAssertEqual(count(of: "task-Exception", in: reopened), 1)
            XCTAssertTrue(occurrence("Routine", day: "2026-11-05", in: reopened).exists)
            XCTAssertTrue(occurrence("Routine", day: "2026-11-06", in: reopened).exists)
            XCTAssertFalse(element("backlog-task-Routine", in: reopened).exists)
            XCTAssertFalse(element("backlog-task-Exception", in: reopened).exists)
            XCTAssertTrue(element("backlog-task-One-off", in: reopened).exists)
            reopened.terminate()
        }
    }

    @MainActor
    private func occurrence(_ title: String, day: String, in app: XCUIApplication) -> XCUIElement {
        element("all-day-\(day)", in: app).descendants(matching: .any)["task-\(title)"].firstMatch
    }

    @MainActor
    private func openRepetition(for task: XCUIElement, in app: XCUIApplication) {
        XCTAssertTrue(task.waitForExistence(timeout: 3))
        task.click()
        XCTAssertTrue(element("task-details", in: app).waitForExistence(timeout: 3))
        click("task-details-repetition", in: app)
        XCTAssertTrue(element("recurrence-save", in: app).waitForExistence(timeout: 3))
    }

    @MainActor
    private func setInterval(_ value: String, in app: XCUIApplication) {
        element("recurrence-interval", in: app).click()
        app.typeKey("a", modifierFlags: .command)
        app.typeText(value)
    }
}
