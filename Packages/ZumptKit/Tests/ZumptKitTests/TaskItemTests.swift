import Foundation
import Testing
import ZumptKit

struct TaskTitleTests {
    @Test func keepsATitleThatIsAlreadyClean() {
        #expect(TaskTitle.normalized("Renovar CNH") == "Renovar CNH")
    }

    @Test func trimsSurroundingSpaces() {
        #expect(TaskTitle.normalized("  Renovar CNH \t") == "Renovar CNH")
    }

    @Test func keepsSpacesInsideTheTitle() {
        #expect(TaskTitle.normalized("Pagar  conta de luz") == "Pagar  conta de luz")
    }

    @Test func joinsPastedLinesIntoOne() {
        #expect(TaskTitle.normalized("Comprar pão\n\n  e leite \r\n") == "Comprar pão e leite")
    }

    @Test(arguments: ["", "   ", "\n", " \t\n\u{00A0}"])
    func rejectsABlankTitle(_ text: String) {
        #expect(TaskTitle.normalized(text) == nil)
    }
}

struct BacklogTests {
    @Test func showsTheNewestTaskFirst() throws {
        let calendar = try makeCalendar()
        let tasks = [
            makeTask("Marcar dentista", createdAt: try date(2026, 11, 2, hour: 9, in: calendar)),
            makeTask("Renovar CNH", createdAt: try date(2026, 11, 4, hour: 9, in: calendar)),
            makeTask("Pagar conta de luz", createdAt: try date(2026, 11, 3, hour: 9, in: calendar)),
        ]

        #expect(Backlog.tasks(tasks).map(\.title) == ["Renovar CNH", "Pagar conta de luz", "Marcar dentista"])
    }

    @Test func ordersTasksCreatedAtTheSameMomentTheSameWayEveryTime() throws {
        let createdAt = try date(2026, 11, 4, hour: 9, in: try makeCalendar())
        let tasks = (0..<5).map { makeTask("Task \($0)", createdAt: createdAt) }

        #expect(Backlog.tasks(tasks) == Backlog.tasks(tasks.reversed()))
    }
}
