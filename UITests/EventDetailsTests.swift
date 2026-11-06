import XCTest

final class EventDetailsTests: ZumptTestCase {
    @MainActor
    func testShowsTheDetailsOfAMeetingWhenItIsClicked() {
        let app = launchApp()
        XCTAssertTrue(element("event-Planejamento", in: app).waitForExistence(timeout: 5))

        click("event-Planejamento", in: app)

        let details = element("event-details", in: app)
        XCTAssertTrue(details.waitForExistence(timeout: 3))
        XCTAssertEqual(text(of: "event-details-title", in: app), "Planejamento")
        XCTAssertTrue(text(of: "event-details-time", in: app).hasPrefix("Segunda-feira, 2 de novembro · 11:00"))
        XCTAssertTrue(text(of: "event-details-recurrence", in: app).contains("Toda semana: seg"))
        XCTAssertEqual(element("join-meeting", in: app).label, "Entrar no Microsoft Teams")
        XCTAssertTrue(text(of: "event-details-location", in: app).contains("Sala Júpiter"))
        XCTAssertTrue(text(of: "event-details-response", in: app).contains("Você aceitou"))
        XCTAssertEqual(text(of: "event-details-guests", in: app), "6 convidados, 3 sim, 1 talvez, 1 não e 1 aguardando")
        XCTAssertTrue(element("event-details-notes", in: app).exists)
        XCTAssertTrue(element("open-in-calendar", in: app).exists)
        attachWindowScreenshot(of: app)

        app.typeKey(.escape, modifierFlags: [])

        XCTAssertTrue(details.waitForNonExistence(timeout: 2))
    }

    @MainActor
    func testShowsAnUnansweredInviteWithAGoogleMeetLink() {
        let app = launchApp()
        XCTAssertTrue(element("event-Fórum de produto", in: app).waitForExistence(timeout: 5))

        click("event-Fórum de produto", in: app)

        XCTAssertTrue(element("event-details", in: app).waitForExistence(timeout: 3))
        XCTAssertEqual(element("join-meeting", in: app).label, "Entrar no Google Meet")
        XCTAssertTrue(text(of: "event-details-response", in: app).contains("Você ainda não respondeu"))
        XCTAssertTrue(text(of: "event-details-recurrence", in: app).contains("A cada 2 semanas"))
        XCTAssertTrue(text(of: "event-details-guests", in: app).hasPrefix("3 convidados"))
    }

    @MainActor
    func testShowsAZoomLinkAndAWeekdayRepeat() {
        let app = launchApp(language: "en-BR", locale: "en_BR")
        XCTAssertTrue(element("event-App Móvel · Daily", in: app).waitForExistence(timeout: 5))

        click("event-App Móvel · Daily", in: app)

        XCTAssertTrue(element("event-details", in: app).waitForExistence(timeout: 3))
        XCTAssertEqual(element("join-meeting", in: app).label, "Join Zoom")
        XCTAssertTrue(text(of: "event-details-recurrence", in: app).contains("Every weekday"))
        XCTAssertFalse(element("event-details-guests", in: app).exists)
        attachWindowScreenshot(of: app)
    }

    @MainActor
    func testShowsAnAllDayEventWithItsCalendar() {
        let app = launchApp()
        XCTAssertTrue(element("event-Finados", in: app).waitForExistence(timeout: 5))

        click("event-Finados", in: app)

        XCTAssertTrue(element("event-details", in: app).waitForExistence(timeout: 3))
        XCTAssertEqual(text(of: "event-details-time", in: app), "Segunda-feira, 2 de novembro · Dia inteiro")
        XCTAssertTrue(text(of: "event-details-calendar", in: app).contains("Feriados no Brasil · Google · Trabalho"))
        XCTAssertFalse(element("join-meeting", in: app).exists)
        XCTAssertFalse(element("event-details-guests", in: app).exists)
    }

    @MainActor
    private func text(of identifier: String, in app: XCUIApplication) -> String {
        displayedText(of: element(identifier, in: app))
    }
}
