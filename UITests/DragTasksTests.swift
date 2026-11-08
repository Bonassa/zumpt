import XCTest

final class DragTasksTests: ZumptTestCase {
    @MainActor
    func testSchedulesABacklogTaskByDraggingItIntoTheWeek() {
        let app = launchApp(taskFixture: "backlog")
        XCTAssertTrue(element("backlog-task-Pagar conta de luz", in: app).waitForExistence(timeout: 5))

        drag("backlog-task-Pagar conta de luz", toDay: "2026-11-04", hour: 14, in: app)

        assertTask("Pagar conta de luz", isOn: "2026-11-04", at: "14:00 – 14:30", in: app)
        let task = element("task-Pagar conta de luz", in: app)
        XCTAssertEqual(task.frame.minY, element("hour-label-14", in: app).frame.midY, accuracy: 3, "It starts at 14:00")
        XCTAssertTrue(element("backlog-task-Pagar conta de luz", in: app).waitForNonExistence(timeout: 2))
        waitForText("2 tarefas", of: element("backlog-count", in: app))
        attachWindowScreenshot(of: app)
    }

    @MainActor
    func testMovesATaskToAnotherDayAndTime() {
        let app = launchApp(taskFixture: "week")
        assertTask("Ligar para o banco", isOn: "2026-11-06", at: "14:00 – 14:30", in: app)

        drag("task-Ligar para o banco", toDay: "2026-11-05", hour: 10, in: app)

        assertTask("Ligar para o banco", isOn: "2026-11-05", at: "10:00 – 10:30", in: app)
        XCTAssertEqual(count(of: "task-Ligar para o banco", in: app), 1)
        attachWindowScreenshot(of: app)
    }

    @MainActor
    func testMovesATaskFromTheWeekBackToTheBacklog() {
        let app = launchApp(taskFixture: "week")
        let task = element("task-Revisar contrato", in: app)
        XCTAssertTrue(task.waitForExistence(timeout: 5))
        let backlog = element("backlog", in: app).frame

        drag("task-Revisar contrato", to: CGPoint(x: backlog.midX, y: backlog.midY), in: app)

        XCTAssertTrue(element("backlog-task-Revisar contrato", in: app).waitForExistence(timeout: 3))
        XCTAssertTrue(task.waitForNonExistence(timeout: 2))
        attachWindowScreenshot(of: app)
    }

    @MainActor
    func testUndoesAndRedoesAMove() {
        let app = launchApp(taskFixture: "week")
        assertTask("Ligar para o banco", isOn: "2026-11-06", at: "14:00 – 14:30", in: app)
        drag("task-Ligar para o banco", toDay: "2026-11-05", hour: 10, in: app)
        assertTask("Ligar para o banco", isOn: "2026-11-05", at: "10:00 – 10:30", in: app)

        app.typeKey("z", modifierFlags: .command)

        assertTask("Ligar para o banco", isOn: "2026-11-06", at: "14:00 – 14:30", in: app)
        attachWindowScreenshot(of: app)

        app.typeKey("z", modifierFlags: [.command, .shift])

        assertTask("Ligar para o banco", isOn: "2026-11-05", at: "10:00 – 10:30", in: app)
    }
}
