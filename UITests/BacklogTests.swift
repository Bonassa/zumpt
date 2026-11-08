import XCTest

final class BacklogTests: ZumptTestCase {
    @MainActor
    func testAddsATaskWithCommandN() {
        let app = launchApp()
        XCTAssertTrue(element("backlog-empty", in: app).waitForExistence(timeout: 5))
        attachWindowScreenshot(of: app)

        app.typeKey("n", modifierFlags: .command)
        XCTAssertTrue(element("new-task-field", in: app).waitForExistence(timeout: 2))
        app.typeText("Renovar CNH")
        app.typeKey(.return, modifierFlags: [])

        XCTAssertTrue(element("backlog-task-Renovar CNH", in: app).waitForExistence(timeout: 2))
        XCTAssertFalse(element("new-task-field", in: app).exists)
        XCTAssertFalse(element("backlog-empty", in: app).exists)
        waitForText("1 tarefa", of: element("backlog-count", in: app))
        attachWindowScreenshot(of: app)
    }

    @MainActor
    func testShowsTheNewestTaskAtTheTop() {
        let app = launchApp(taskFixture: "backlog")
        let oldest = element("backlog-task-Comprar presente da Ana", in: app)
        let newest = element("backlog-task-Pagar conta de luz", in: app)
        XCTAssertTrue(oldest.waitForExistence(timeout: 5))
        XCTAssertLessThan(newest.frame.minY, oldest.frame.minY)

        addTask(" Renovar CNH ", in: app)

        let added = element("backlog-task-Renovar CNH", in: app)
        XCTAssertTrue(added.waitForExistence(timeout: 2), "Surrounding spaces are trimmed")
        XCTAssertLessThan(added.frame.minY, newest.frame.minY)
        waitForText("4 tarefas", of: element("backlog-count", in: app))
        attachWindowScreenshot(of: app)
    }

    @MainActor
    func testCreatesNothingForABlankTitleOrWhenCanceled() {
        let app = launchApp()
        XCTAssertTrue(element("backlog-empty", in: app).waitForExistence(timeout: 5))

        addTask("   ", in: app)

        XCTAssertTrue(element("new-task-field", in: app).waitForNonExistence(timeout: 2))
        XCTAssertTrue(element("backlog-empty", in: app).exists)

        click("new-task-button", in: app)
        XCTAssertTrue(element("new-task-field", in: app).waitForExistence(timeout: 2))
        app.typeText("Rascunho")
        app.typeKey(.escape, modifierFlags: [])

        XCTAssertTrue(element("new-task-field", in: app).waitForNonExistence(timeout: 2))
        XCTAssertFalse(element("backlog-task-Rascunho", in: app).exists)
        XCTAssertTrue(element("backlog-empty", in: app).exists)
    }

    @MainActor
    func testUndoesAndRedoesCreatingATask() {
        let app = launchApp()
        XCTAssertTrue(element("backlog-empty", in: app).waitForExistence(timeout: 5))
        addTask("Renovar CNH", in: app)
        let task = element("backlog-task-Renovar CNH", in: app)
        XCTAssertTrue(task.waitForExistence(timeout: 2))

        app.typeKey("z", modifierFlags: .command)

        XCTAssertTrue(task.waitForNonExistence(timeout: 2))
        XCTAssertTrue(element("backlog-empty", in: app).exists)
        attachWindowScreenshot(of: app)

        app.typeKey("z", modifierFlags: [.command, .shift])

        XCTAssertTrue(task.waitForExistence(timeout: 2))
    }

    @MainActor
    func testKeepsTasksAfterQuittingAndOpeningAgain() {
        let app = launchApp(tasksStore: "zumpt-ui-tests-\(UUID().uuidString).store")
        XCTAssertTrue(element("backlog-empty", in: app).waitForExistence(timeout: 5))
        addTask("Renovar CNH", in: app)
        XCTAssertTrue(element("backlog-task-Renovar CNH", in: app).waitForExistence(timeout: 2))

        app.typeKey("q", modifierFlags: .command)
        XCTAssertTrue(app.wait(for: .notRunning, timeout: 5))
        app.launch()

        XCTAssertTrue(element("backlog-task-Renovar CNH", in: app).waitForExistence(timeout: 5))
        attachWindowScreenshot(of: app)
    }
}
