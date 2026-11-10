import XCTest

final class WeekTasksTests: ZumptTestCase {
    @MainActor
    func testShowsATaskNextToAMeetingAtTheSameTime() {
        let app = launchApp(taskFixture: "week")
        let task = element("task-Revisar contrato", in: app)
        let meeting = element("event-[Acompanhamento] Squad", in: app)
        XCTAssertTrue(task.waitForExistence(timeout: 5))
        XCTAssertTrue(meeting.exists)

        XCTAssertEqual(task.frame.minY, meeting.frame.minY, accuracy: 1, "Both start at 11:00")
        XCTAssertEqual(task.frame.height, meeting.frame.height, accuracy: 1, "Both last 30 minutes")
        XCTAssertTrue(task.frame.intersection(meeting.frame).width < 1, "The task sits beside the meeting")
        XCTAssertEqual(displayedText(of: task), "Revisar contrato, 11:00 – 11:30")
        XCTAssertEqual(meeting.elementType, .button)
        XCTAssertNotEqual(task.elementType, .button)
        XCTAssertFalse(element("backlog-task-Revisar contrato", in: app).exists, "A scheduled task leaves the backlog")
        attachWindowScreenshot(of: app)
    }
}
