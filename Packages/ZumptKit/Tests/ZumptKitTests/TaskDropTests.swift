import Foundation
import Testing
import ZumptKit

struct TaskDropTests {
    @Test(arguments: [
        (840.0, 840),
        (847.0, 840),
        (848.0, 855),
        (833.0, 840),
        (600.4, 600),
    ])
    func snapsTheDropToTheNearestQuarterHour(minute: Double, expected: Int) {
        #expect(TaskDrop.startMinute(at: minute) == expected)
    }

    @Test(arguments: [1410.0, 1425.0, 1439.0, 1500.0])
    func keepsTheTaskInsideItsDay(minute: Double) {
        #expect(TaskDrop.startMinute(at: minute) == 1410)
    }

    @Test func neverStartsBeforeMidnight() {
        #expect(TaskDrop.startMinute(at: -20) == 0)
    }

    @Test func turnsTheMinuteIntoATimeOnThatDay() throws {
        let calendar = try makeCalendar()

        let start = TaskDrop.start(atMinute: 840, on: try date(2026, 11, 4, hour: 0, in: calendar), calendar: calendar)

        #expect(start == (try date(2026, 11, 4, hour: 14, in: calendar)))
    }

    @Test func keepsTheWallClockTimeOnADaylightSavingDay() throws {
        let calendar = try makeCalendar(timeZone: "America/New_York")
        let day = try date(2026, 3, 8, hour: 12, in: calendar)

        let start = TaskDrop.start(atMinute: 600, on: day, calendar: calendar)

        #expect(
            calendar.dateComponents([.day, .hour, .minute], from: start) == DateComponents(day: 8, hour: 10, minute: 0))
    }
}
