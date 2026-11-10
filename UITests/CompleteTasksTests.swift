import XCTest

final class CompleteTasksTests: ZumptTestCase {
    @MainActor
    func testTicksATaskInTheWeekAsDoneAndBack() {
        let app = launchApp(taskFixture: "week")
        let circle = element("complete-Revisar contrato", in: app)
        XCTAssertTrue(circle.waitForExistence(timeout: 5))
        XCTAssertEqual(circle.label, "Concluir Revisar contrato")
        let frame = element("task-Revisar contrato", in: app).frame

        click("complete-Revisar contrato", in: app)

        waitForLabel("Reabrir Revisar contrato", of: circle)
        XCTAssertEqual(element("task-Revisar contrato", in: app).frame, frame, "A done task stays where it was")
        XCTAssertFalse(element("event-details", in: app).exists)
        attachWindowScreenshot(of: app)

        click("complete-Revisar contrato", in: app)

        waitForLabel("Concluir Revisar contrato", of: circle)
    }

    @MainActor
    func testTickingABacklogTaskTakesItOutOfTheBacklog() {
        let app = launchApp(taskFixture: "backlog")
        let task = element("backlog-task-Marcar dentista", in: app)
        XCTAssertTrue(task.waitForExistence(timeout: 5))

        click("complete-Marcar dentista", in: app)

        XCTAssertTrue(task.waitForNonExistence(timeout: 2))
        waitForText("2 tarefas", of: element("backlog-count", in: app))
        attachWindowScreenshot(of: app)
    }

    @MainActor
    func testUndoesTickingATask() {
        let app = launchApp(taskFixture: "week")
        let circle = element("complete-Revisar contrato", in: app)
        XCTAssertTrue(circle.waitForExistence(timeout: 5))
        click("complete-Revisar contrato", in: app)
        waitForLabel("Reabrir Revisar contrato", of: circle)

        app.typeKey("z", modifierFlags: .command)

        waitForLabel("Concluir Revisar contrato", of: circle)
    }

    @MainActor
    private func waitForLabel(_ expected: String, of element: XCUIElement, line: UInt = #line) {
        XCTAssertTrue(
            element.wait(for: \.label, toEqual: expected, timeout: 3), "Label is \(element.label)", line: line)
    }
}
