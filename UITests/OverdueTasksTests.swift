import XCTest

final class OverdueTasksTests: ZumptTestCase {
    private static let afternoon = "2026-11-04T18:00:00Z"

    @MainActor
    func testKeepsATaskFromEarlierTodayInTheWeek() {
        let app = launchApp(taskFixture: "overdue", now: Self.afternoon)

        assertTask("Pagar boleto", isOn: "2026-11-04", at: "09:00 – 09:30", in: app)
        XCTAssertFalse(element("backlog-task-Pagar boleto", in: app).exists)
        attachWindowScreenshot(of: app)
    }

    @MainActor
    func testReturnsATaskFromYesterdayToTheTopOfTheBacklog() {
        let app = launchApp(taskFixture: "backlog,overdue")
        let overdue = element("backlog-task-Enviar NF de outubro", in: app)
        XCTAssertTrue(overdue.waitForExistence(timeout: 5))

        XCTAssertFalse(element("task-Enviar NF de outubro", in: app).exists, "It left the week")
        XCTAssertTrue(element("backlog-overdue-header", in: app).exists)
        XCTAssertEqual(
            displayedText(of: element("backlog-task-due-Enviar NF de outubro", in: app)), "Venceu ter., 3 de nov.")
        XCTAssertLessThan(overdue.frame.minY, element("backlog-task-Pagar conta de luz", in: app).frame.minY)
        waitForText("4 tarefas", of: element("backlog-count", in: app))
        attachWindowScreenshot(of: app)
    }

    @MainActor
    func testReopeningADoneTaskFromAnEarlierDayReturnsItToTheBacklog() {
        let app = launchApp(taskFixture: "week")
        XCTAssertTrue(element("complete-Pagar fatura do cartão", in: app).waitForExistence(timeout: 5))

        click("complete-Pagar fatura do cartão", in: app)

        let overdue = element("backlog-task-Pagar fatura do cartão", in: app)
        XCTAssertTrue(overdue.waitForExistence(timeout: 3))
        XCTAssertFalse(element("task-Pagar fatura do cartão", in: app).exists, "It left the week")
        XCTAssertEqual(
            displayedText(of: element("backlog-task-due-Pagar fatura do cartão", in: app)), "Venceu seg., 2 de nov.")
        attachWindowScreenshot(of: app)

        app.typeKey("z", modifierFlags: .command)

        assertTask("Pagar fatura do cartão", isOn: "2026-11-02", at: "08:30 – 09:00", in: app)
        XCTAssertTrue(overdue.waitForNonExistence(timeout: 2))

        app.typeKey("z", modifierFlags: [.command, .shift])

        XCTAssertTrue(overdue.waitForExistence(timeout: 3))
        XCTAssertTrue(element("task-Pagar fatura do cartão", in: app).waitForNonExistence(timeout: 2))
    }

    @MainActor
    func testSchedulingAnOverdueTaskAgainClearsTheOverdueMark() {
        let app = launchApp(taskFixture: "overdue")
        XCTAssertTrue(element("backlog-task-Enviar NF de outubro", in: app).waitForExistence(timeout: 5))

        drag("backlog-task-Enviar NF de outubro", toDay: "2026-11-05", hour: 10, in: app)

        assertTask("Enviar NF de outubro", isOn: "2026-11-05", at: "10:00 – 10:30", in: app)
        XCTAssertTrue(element("backlog-overdue-header", in: app).waitForNonExistence(timeout: 2))

        let backlog = element("backlog", in: app).frame
        drag("task-Enviar NF de outubro", to: CGPoint(x: backlog.midX, y: backlog.midY), in: app)

        XCTAssertTrue(element("backlog-task-Enviar NF de outubro", in: app).waitForExistence(timeout: 3))
        XCTAssertFalse(element("backlog-task-due-Enviar NF de outubro", in: app).exists)
        XCTAssertFalse(element("backlog-overdue-header", in: app).exists)
    }
}
