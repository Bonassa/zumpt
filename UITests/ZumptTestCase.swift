import XCTest

class ZumptTestCase: XCTestCase {
    static let fixedNow = "2026-11-04T15:00:00Z"

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    @MainActor
    func launchApp(
        calendarAccess: String = "granted",
        language: String = "pt-BR",
        locale: String = "pt_BR",
        tasksStore: String = "memory",
        taskFixture: String? = nil,
        now: String = fixedNow,
        isDark: Bool = false,
        preferences: String? = nil
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "--now", now,
            "--calendar-fixture", calendarAccess,
            "--tasks-store", tasksStore,
            "-AppleLanguages", "(\(language))",
            "-AppleLocale", locale,
        ]
        if let taskFixture {
            app.launchArguments += ["--task-fixture", taskFixture]
        }
        if isDark {
            app.launchArguments += ["--appearance", "dark"]
        }
        if let preferences {
            app.launchArguments += ["--preferences", preferences, "--reset-preferences"]
        }
        app.launch()
        addTeardownBlock { @MainActor in app.terminate() }
        return app
    }

    @MainActor
    func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)[identifier].firstMatch
    }

    @MainActor
    func click(_ identifier: String, in app: XCUIApplication) {
        app.activate()
        element(identifier, in: app).click()
    }

    @MainActor
    func addTask(_ title: String, in app: XCUIApplication) {
        app.typeKey("n", modifierFlags: .command)
        XCTAssertTrue(element("new-task-field", in: app).waitForExistence(timeout: 2))
        app.typeText(title)
        app.typeKey(.return, modifierFlags: [])
    }

    @MainActor
    func drag(_ identifier: String, toDay day: String, hour: Int, in app: XCUIApplication) {
        waitForWorkdayStartAtTheTop(in: app)
        let column = element("day-column-\(day)", in: app)
        let hourLabel = element("hour-label-\(hour)", in: app)
        XCTAssertTrue(column.exists && hourLabel.exists, "Day \(day) and hour \(hour) should be on screen")
        drag(identifier, to: CGPoint(x: column.frame.midX, y: hourLabel.frame.midY), in: app)
    }

    @MainActor
    func drag(_ identifier: String, to point: CGPoint, in app: XCUIApplication) {
        app.activate()
        let window = app.windows.firstMatch
        let source = element(identifier, in: app).coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let target = window.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: point.x - window.frame.minX, dy: point.y - window.frame.minY))
        source.click(forDuration: 0.3, thenDragTo: target, withVelocity: .slow, thenHoldForDuration: 0.3)
    }

    @MainActor
    func assertTask(
        _ title: String,
        isOn day: String,
        at timeRange: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let task = element("task-\(title)", in: app)
        XCTAssertTrue(task.waitForExistence(timeout: 3), "\(title) should be in the week", file: file, line: line)
        waitForText("\(title), \(timeRange)", of: task, file: file, line: line)
        let column = element("day-column-\(day)", in: app).frame
        XCTAssertTrue(
            column.minX <= task.frame.midX && task.frame.midX <= column.maxX,
            "\(title) should be on \(day)",
            file: file,
            line: line
        )
    }

    @MainActor
    func showSidebarTab(_ title: String, in app: XCUIApplication) {
        app.activate()
        element("sidebar-tabs", in: app).radioButtons[title].click()
    }

    @MainActor
    func count(of identifier: String, in app: XCUIApplication) -> Int {
        app.descendants(matching: .any).matching(identifier: identifier).count
    }

    @MainActor
    func displayedText(of element: XCUIElement) -> String {
        let value = element.value as? String ?? ""
        let text = value.isEmpty ? element.label : value
        return text.replacing(/[\u{2009}\u{202F}\u{00A0}]/, with: " ")
    }

    @MainActor
    func waitForText(
        _ expected: String,
        of element: XCUIElement,
        timeout: TimeInterval = 3,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let deadline = Date.now.addingTimeInterval(timeout)
        while displayedText(of: element) != expected, Date.now < deadline {
            RunLoop.current.run(until: Date.now.addingTimeInterval(0.1))
        }
        XCTAssertEqual(displayedText(of: element), expected, file: file, line: line)
    }

    @MainActor
    func assertWeekHeader(
        in app: XCUIApplication,
        title: String,
        number: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let titleElement = element("week-header-title", in: app)
        XCTAssertTrue(titleElement.waitForExistence(timeout: 5), file: file, line: line)
        waitForText(title, of: titleElement, file: file, line: line)
        waitForText(number, of: element("week-header-number", in: app), file: file, line: line)
    }

    @MainActor
    func assertWorkdayStartsAtTheTop(
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let gap = waitForWorkdayStartAtTheTop(in: app)
        let layout = abs(gap - Self.workdayStartGap) > 2 ? layoutDescription(of: app) : ""
        XCTAssertEqual(
            gap,
            Self.workdayStartGap,
            accuracy: 2,
            "08:00 should sit right below the all-day row. \(layout)",
            file: file,
            line: line
        )
    }

    static let workdayStartGap: CGFloat = 10.5

    /// The week scrolls to 08:00 once it is laid out, which can land a moment after the window shows up.
    @MainActor
    @discardableResult
    func waitForWorkdayStartAtTheTop(in app: XCUIApplication, timeout: TimeInterval = 3) -> CGFloat {
        let deadline = Date.now.addingTimeInterval(timeout)
        var gap = workdayStartGap(in: app)
        while abs(gap - Self.workdayStartGap) > 2, Date.now < deadline {
            RunLoop.current.run(until: Date.now.addingTimeInterval(0.1))
            gap = workdayStartGap(in: app)
        }
        return gap
    }

    @MainActor
    private func layoutDescription(of app: XCUIApplication) -> String {
        let weekScroll = element("week-scroll", in: app)
        let scrollValue = (weekScroll.value as? String) ?? "no value"
        let scrollState = weekScroll.exists ? "\(weekScroll.frame) \(scrollValue)" : "missing"
        let elements = [
            ("window", app.windows.firstMatch),
            ("all-day row", element("all-day-row", in: app)),
            ("01:00", element("hour-label-1", in: app)),
            ("08:00", element("hour-label-8", in: app)),
            ("23:00", element("hour-label-23", in: app)),
        ]
        let frames = elements.map { "\($0.0): \($0.1.exists ? "\($0.1.frame)" : "missing")" }
        return (frames + ["week scroll: \(scrollState)"]).joined(separator: "; ")
    }

    @MainActor
    private func workdayStartGap(in app: XCUIApplication) -> CGFloat {
        element("hour-label-8", in: app).frame.midY - element("all-day-row", in: app).frame.maxY
    }

    @MainActor
    func attachWindowScreenshot(of app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.windows.firstMatch.screenshot())
        attachment.name = "\(name) window"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
