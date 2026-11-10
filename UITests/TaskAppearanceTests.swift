import XCTest

final class TaskAppearanceTests: ZumptTestCase {
    @MainActor
    func testShowsTasksInLightMode() {
        showEveryKindOfTask(isDark: false)
    }

    @MainActor
    func testShowsTasksInDarkMode() {
        showEveryKindOfTask(isDark: true)
    }

    @MainActor
    private func showEveryKindOfTask(isDark: Bool) {
        let app = launchApp(taskFixture: "backlog,week,overdue", isDark: isDark)
        XCTAssertTrue(element("backlog-overdue-header", in: app).waitForExistence(timeout: 5))
        XCTAssertTrue(element("task-Pagar fatura do cartão", in: app).exists)
        click("task-Ligar para o banco", in: app)
        XCTAssertTrue(element("task-Ligar para o banco", in: app).wait(for: \.isSelected, toEqual: true, timeout: 2))
        attachWindowScreenshot(of: app)
    }
}
