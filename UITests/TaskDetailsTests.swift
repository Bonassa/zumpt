import XCTest

final class TaskDetailsTests: ZumptTestCase {
    @MainActor
    func testShowsTheDetailsOfATaskInTheWeekWhenItIsClicked() {
        let app = launchApp(taskFixture: "week")
        XCTAssertTrue(element("task-Revisar contrato", in: app).waitForExistence(timeout: 5))

        click("task-Revisar contrato", in: app)

        let details = element("task-details", in: app)
        XCTAssertTrue(details.waitForExistence(timeout: 3))
        waitForText("Revisar contrato", of: element("task-details-title", in: app))
        waitForText("Sexta-feira, 6 de novembro · 11:00 – 11:30", of: element("task-details-time", in: app))
        XCTAssertTrue(displayedText(of: element("task-details-created", in: app)).hasPrefix("Criada em"))
        XCTAssertFalse(element("task-details-status", in: app).exists)
        attachWindowScreenshot(of: app)

        app.typeKey(.escape, modifierFlags: [])

        XCTAssertTrue(details.waitForNonExistence(timeout: 2))
        XCTAssertTrue(element("task-Revisar contrato", in: app).isSelected, "Closing the details keeps the selection")
    }

    @MainActor
    func testShowsTheDetailsOfAnOverdueBacklogTask() {
        let app = launchApp(taskFixture: "overdue")
        XCTAssertTrue(element("backlog-task-Enviar NF de outubro", in: app).waitForExistence(timeout: 5))

        click("backlog-task-Enviar NF de outubro", in: app)

        XCTAssertTrue(element("task-details", in: app).waitForExistence(timeout: 3))
        waitForText("Sem horário · No backlog", of: element("task-details-time", in: app))
        XCTAssertTrue(displayedText(of: element("task-details-status", in: app)).hasPrefix("Atrasada desde"))
        attachWindowScreenshot(of: app)
    }

    @MainActor
    func testCompletesATaskFromItsDetails() {
        let app = launchApp(taskFixture: "week")
        XCTAssertTrue(element("task-Revisar contrato", in: app).waitForExistence(timeout: 5))
        click("task-Revisar contrato", in: app)
        let details = element("task-details", in: app)
        XCTAssertTrue(details.waitForExistence(timeout: 3))

        details.descendants(matching: .any)["complete-Revisar contrato"].firstMatch.click()

        let status = element("task-details-status", in: app)
        XCTAssertTrue(status.waitForExistence(timeout: 2))
        XCTAssertTrue(displayedText(of: status).hasPrefix("Concluída em"))
        attachWindowScreenshot(of: app)
    }

    @MainActor
    func testDeletesATaskFromItsDetailsAndUndoes() {
        let app = launchApp(taskFixture: "week")
        let task = element("task-Revisar contrato", in: app)
        XCTAssertTrue(task.waitForExistence(timeout: 5))
        click("task-Revisar contrato", in: app)
        XCTAssertTrue(element("task-details", in: app).waitForExistence(timeout: 3))

        click("task-details-delete", in: app)

        XCTAssertTrue(task.waitForNonExistence(timeout: 2))
        XCTAssertFalse(element("task-details", in: app).exists)

        app.typeKey("z", modifierFlags: .command)

        assertTask("Revisar contrato", isOn: "2026-11-06", at: "11:00 – 11:30", in: app)
    }

    @MainActor
    func testDeletesATaskWithTheDeleteKeyWhileItsDetailsAreOpen() {
        let app = launchApp(taskFixture: "backlog")
        let task = element("backlog-task-Marcar dentista", in: app)
        XCTAssertTrue(task.waitForExistence(timeout: 5))
        click("backlog-task-Marcar dentista", in: app)
        XCTAssertTrue(element("task-details", in: app).waitForExistence(timeout: 3))

        app.typeKey(.delete, modifierFlags: [])

        XCTAssertTrue(task.waitForNonExistence(timeout: 2))
        waitForText("2 tarefas", of: element("backlog-count", in: app))
    }

    @MainActor
    func testRenamesFromTheDetails() {
        let app = launchApp(taskFixture: "backlog")
        XCTAssertTrue(element("backlog-task-Marcar dentista", in: app).waitForExistence(timeout: 5))
        click("backlog-task-Marcar dentista", in: app)
        XCTAssertTrue(element("task-details", in: app).waitForExistence(timeout: 3))

        click("task-details-rename", in: app)

        XCTAssertTrue(element("rename-field", in: app).waitForExistence(timeout: 2))
        XCTAssertTrue(element("task-details", in: app).waitForNonExistence(timeout: 2))
        app.typeKey("a", modifierFlags: .command)
        app.typeText("Ligar para o dentista")
        app.typeKey(.return, modifierFlags: [])

        XCTAssertTrue(element("backlog-task-Ligar para o dentista", in: app).waitForExistence(timeout: 2))
    }

    @MainActor
    func testDoubleClickingRenamesWithoutOpeningTheDetails() {
        let app = launchApp(taskFixture: "week")
        let task = element("task-Ligar para o banco", in: app)
        XCTAssertTrue(task.waitForExistence(timeout: 5))

        task.doubleClick()

        XCTAssertTrue(element("rename-field", in: app).waitForExistence(timeout: 2))
        XCTAssertFalse(element("task-details", in: app).waitForExistence(timeout: 1))
        app.typeKey(.escape, modifierFlags: [])
    }
}
