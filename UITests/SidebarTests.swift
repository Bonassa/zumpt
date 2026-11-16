import XCTest

final class SidebarTests: ZumptTestCase {
    @MainActor
    func testSwitchesTheSidebarBetweenCalendarsAndBacklogFilters() {
        let app = launchApp(taskFixture: "backlog")
        let calendarToggle = element("calendar-toggle-fixture-agenda", in: app)
        XCTAssertTrue(calendarToggle.waitForExistence(timeout: 5))
        XCTAssertFalse(element("backlog-filter-all", in: app).exists)

        showSidebarTab("Backlog", in: app)

        XCTAssertTrue(element("backlog-filter-all", in: app).waitForExistence(timeout: 2))
        XCTAssertTrue(element("backlog-filter-overdue", in: app).exists)
        XCTAssertFalse(calendarToggle.exists)
        XCTAssertTrue(element("day-column-2026-11-04", in: app).exists, "The week stays in the middle")
        XCTAssertTrue(element("backlog", in: app).exists)
        attachWindowScreenshot(of: app)

        showSidebarTab("Calendário", in: app)

        XCTAssertTrue(calendarToggle.waitForExistence(timeout: 2))
        XCTAssertFalse(element("backlog-filter-all", in: app).exists)
    }

    @MainActor
    func testFiltersTheBacklogToOverdueTasksAndBack() {
        let app = launchApp(taskFixture: "backlog,overdue")
        XCTAssertTrue(element("backlog-task-Enviar NF de outubro", in: app).waitForExistence(timeout: 5))
        waitForText("4 tarefas", of: element("backlog-count", in: app))
        showSidebarTab("Backlog", in: app)

        click("backlog-filter-overdue", in: app)

        XCTAssertTrue(element("backlog-task-Pagar conta de luz", in: app).waitForNonExistence(timeout: 2))
        XCTAssertTrue(element("backlog-task-Enviar NF de outubro", in: app).exists)
        XCTAssertFalse(element("backlog-overdue-header", in: app).exists)
        XCTAssertTrue(element("backlog-filter-chip", in: app).exists)
        waitForText("1 tarefa", of: element("backlog-count", in: app))
        attachWindowScreenshot(of: app)

        click("backlog-filter-clear", in: app)

        XCTAssertTrue(element("backlog-task-Pagar conta de luz", in: app).waitForExistence(timeout: 2))
        XCTAssertFalse(element("backlog-filter-chip", in: app).exists)
        XCTAssertTrue(element("backlog-overdue-header", in: app).exists)
        waitForText("4 tarefas", of: element("backlog-count", in: app))
    }

    @MainActor
    func testSaysWhenNoTaskIsOverdue() {
        let app = launchApp(taskFixture: "backlog")
        XCTAssertTrue(element("backlog-task-Marcar dentista", in: app).waitForExistence(timeout: 5))
        showSidebarTab("Backlog", in: app)

        click("backlog-filter-overdue", in: app)

        let empty = element("backlog-empty", in: app)
        XCTAssertTrue(empty.waitForExistence(timeout: 2))
        waitForText("Nenhuma tarefa atrasada.", of: empty)
        attachWindowScreenshot(of: app)
    }

    @MainActor
    func testAddingATaskShowsTheWholeBacklog() {
        let app = launchApp(taskFixture: "backlog,overdue")
        XCTAssertTrue(element("backlog-task-Enviar NF de outubro", in: app).waitForExistence(timeout: 5))
        showSidebarTab("Backlog", in: app)
        click("backlog-filter-overdue", in: app)
        XCTAssertTrue(element("backlog-filter-chip", in: app).waitForExistence(timeout: 2))

        addTask("Renovar CNH", in: app)

        XCTAssertTrue(element("backlog-task-Renovar CNH", in: app).waitForExistence(timeout: 2))
        XCTAssertTrue(element("backlog-task-Pagar conta de luz", in: app).exists)
        XCTAssertFalse(element("backlog-filter-chip", in: app).exists)
    }
}
