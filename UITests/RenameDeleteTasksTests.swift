import XCTest

final class RenameDeleteTasksTests: ZumptTestCase {
    @MainActor
    func testRenamesABacklogTaskByDoubleClickingIt() {
        let app = launchApp(taskFixture: "backlog")
        let task = element("backlog-task-Marcar dentista", in: app)
        XCTAssertTrue(task.waitForExistence(timeout: 5))

        task.doubleClick()
        XCTAssertTrue(element("rename-field", in: app).waitForExistence(timeout: 2))
        app.typeKey("a", modifierFlags: .command)
        app.typeText("Renovar passaporte")
        app.typeKey(.return, modifierFlags: [])

        XCTAssertTrue(element("backlog-task-Renovar passaporte", in: app).waitForExistence(timeout: 2))
        XCTAssertFalse(task.exists)
        XCTAssertFalse(element("rename-field", in: app).exists)
        attachWindowScreenshot(of: app)
    }

    @MainActor
    func testKeepsTheTitleWhenRenamingIsCanceledOrBlank() {
        let app = launchApp(taskFixture: "backlog")
        let task = element("backlog-task-Marcar dentista", in: app)
        XCTAssertTrue(task.waitForExistence(timeout: 5))

        task.rightClick()
        app.menuItems["Renomear"].click()
        XCTAssertTrue(element("rename-field", in: app).waitForExistence(timeout: 2))
        app.typeKey("a", modifierFlags: .command)
        app.typeText("Rascunho")
        app.typeKey(.escape, modifierFlags: [])

        XCTAssertTrue(element("rename-field", in: app).waitForNonExistence(timeout: 2))
        XCTAssertTrue(task.exists)

        task.doubleClick()
        XCTAssertTrue(element("rename-field", in: app).waitForExistence(timeout: 2))
        app.typeKey("a", modifierFlags: .command)
        app.typeKey(.delete, modifierFlags: [])
        app.typeKey(.return, modifierFlags: [])

        XCTAssertTrue(element("rename-field", in: app).waitForNonExistence(timeout: 2))
        XCTAssertTrue(task.exists, "A blank title keeps the old one")
    }

    @MainActor
    func testRenamesATaskInTheWeek() {
        let app = launchApp(taskFixture: "week")
        assertTask("Ligar para o banco", isOn: "2026-11-06", at: "14:00 – 14:30", in: app)

        element("task-Ligar para o banco", in: app).doubleClick()
        XCTAssertTrue(element("rename-field", in: app).waitForExistence(timeout: 2))
        app.typeKey("a", modifierFlags: .command)
        app.typeText("Ligar para a operadora")
        app.typeKey(.return, modifierFlags: [])

        assertTask("Ligar para a operadora", isOn: "2026-11-06", at: "14:00 – 14:30", in: app)
        attachWindowScreenshot(of: app)
    }

    @MainActor
    func testDeletesASelectedBacklogTaskWithTheDeleteKey() {
        let app = launchApp(taskFixture: "backlog")
        let task = element("backlog-task-Marcar dentista", in: app)
        XCTAssertTrue(task.waitForExistence(timeout: 5))

        click("backlog-task-Marcar dentista", in: app)
        XCTAssertTrue(task.wait(for: \.isSelected, toEqual: true, timeout: 2))
        app.typeKey(.delete, modifierFlags: [])

        XCTAssertTrue(task.waitForNonExistence(timeout: 2))
        waitForText("2 tarefas", of: element("backlog-count", in: app))
        attachWindowScreenshot(of: app)
    }

    @MainActor
    func testDeletesATaskInTheWeekFromItsMenuAndUndoes() {
        let app = launchApp(taskFixture: "week")
        let task = element("task-Revisar contrato", in: app)
        XCTAssertTrue(task.waitForExistence(timeout: 5))

        task.rightClick()
        app.menuItems["Excluir"].click()

        XCTAssertTrue(task.waitForNonExistence(timeout: 2))
        XCTAssertFalse(element("backlog-task-Revisar contrato", in: app).exists)

        app.typeKey("z", modifierFlags: .command)

        assertTask("Revisar contrato", isOn: "2026-11-06", at: "11:00 – 11:30", in: app)
    }

    @MainActor
    func testUndoesDeletingABacklogTask() {
        let app = launchApp(taskFixture: "backlog")
        let task = element("backlog-task-Marcar dentista", in: app)
        XCTAssertTrue(task.waitForExistence(timeout: 5))
        let position = task.frame.minY
        click("backlog-task-Marcar dentista", in: app)
        app.typeKey(.delete, modifierFlags: [])
        XCTAssertTrue(task.waitForNonExistence(timeout: 2))

        app.typeKey("z", modifierFlags: .command)

        XCTAssertTrue(task.waitForExistence(timeout: 2))
        XCTAssertEqual(task.frame.minY, position, accuracy: 1, "It is back where it was")
    }
}
