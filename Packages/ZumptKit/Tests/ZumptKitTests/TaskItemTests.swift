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

    @Test func renamesToTheCleanedUpTitle() {
        #expect(TaskTitle.renamed("Renovar CNH", to: "  Renovar passaporte ") == "Renovar passaporte")
    }

    @Test func keepsTheOldTitleWhenTheNewOneIsBlank() {
        #expect(TaskTitle.renamed("Renovar CNH", to: "   ") == "Renovar CNH")
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

    @Test func leavesScheduledTasksOutOfTheBacklog() throws {
        let calendar = try makeCalendar()
        let tasks = [
            makeTask("Renovar CNH"),
            makeTask("Revisar contrato", scheduledAt: try date(2026, 11, 4, hour: 14, in: calendar)),
        ]

        #expect(Backlog.tasks(tasks).map(\.title) == ["Renovar CNH"])
    }

    @Test func leavesDoneTasksOutOfTheBacklog() throws {
        let doneAt = try date(2026, 11, 4, hour: 9, in: try makeCalendar())
        let tasks = [makeTask("Renovar CNH"), makeTask("Marcar dentista", completedAt: doneAt)]

        #expect(Backlog.tasks(tasks).map(\.title) == ["Renovar CNH"])
        #expect(tasks.map(\.isDone) == [false, true])
    }

    @Test func putsOverdueTasksFirstWithTheOldestOnTop() throws {
        let calendar = try makeCalendar()
        let tasks = [
            makeTask("Renovar CNH", createdAt: try date(2026, 11, 4, hour: 9, in: calendar)),
            makeTask("Enviar NF", missedAt: try date(2026, 11, 3, hour: 10, in: calendar)),
            makeTask("Pagar IPVA", missedAt: try date(2026, 11, 2, hour: 16, in: calendar)),
            makeTask("Marcar dentista", createdAt: try date(2026, 11, 1, hour: 9, in: calendar)),
        ]

        #expect(Backlog.tasks(tasks).map(\.title) == ["Pagar IPVA", "Enviar NF", "Renovar CNH", "Marcar dentista"])
        #expect(Backlog.tasks(tasks).map(\.isOverdue) == [true, true, false, false])
    }

    @Test func endsAScheduledTaskThirtyMinutesAfterItStarts() throws {
        let calendar = try makeCalendar()
        let task = makeTask("Revisar contrato", scheduledAt: try date(2026, 11, 4, hour: 14, in: calendar))

        #expect(task.scheduledEnd == (try date(2026, 11, 4, hour: 14, minute: 30, in: calendar)))
        #expect(makeTask("Renovar CNH").scheduledEnd == nil)
    }

    @Test func ordersTasksCreatedAtTheSameMomentTheSameWayEveryTime() throws {
        let createdAt = try date(2026, 11, 4, hour: 9, in: try makeCalendar())
        let tasks = (0..<5).map { makeTask("Task \($0)", createdAt: createdAt) }

        #expect(Backlog.tasks(tasks) == Backlog.tasks(tasks.reversed()))
    }
}

struct BacklogFilterTests {
    @Test func showsTheWholeBacklogInItsOrder() throws {
        let backlog = try sampleBacklog()

        #expect(BacklogFilter.all.tasks(in: backlog).map(\.title) == ["Pagar IPVA", "Enviar NF", "Renovar CNH"])
    }

    @Test func showsOnlyOverdueTasksWithTheOldestOnTop() throws {
        let backlog = try sampleBacklog()

        #expect(BacklogFilter.overdue.tasks(in: backlog).map(\.title) == ["Pagar IPVA", "Enviar NF"])
    }

    @Test func showsNoOverdueTasksWhenNoneWereMissed() {
        #expect(BacklogFilter.overdue.tasks(in: Backlog.tasks([makeTask("Renovar CNH")])).isEmpty)
    }

    private func sampleBacklog() throws -> [TaskItem] {
        let calendar = try makeCalendar()
        return Backlog.tasks([
            makeTask("Renovar CNH", createdAt: try date(2026, 11, 4, hour: 9, in: calendar)),
            makeTask("Enviar NF", missedAt: try date(2026, 11, 3, hour: 10, in: calendar)),
            makeTask("Pagar IPVA", missedAt: try date(2026, 11, 2, hour: 16, in: calendar)),
        ])
    }
}
