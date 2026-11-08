import Foundation

public enum TaskDrop {
    public static let snapInMinutes = 15
    public static let latestStartMinute = DayLayout.minutesPerDay - TaskItem.durationInMinutes

    public static func startMinute(at minute: Double) -> Int {
        let snapped = Int((minute / Double(snapInMinutes)).rounded()) * snapInMinutes
        return min(max(snapped, 0), latestStartMinute)
    }

    public static func start(atMinute minute: Int, on day: Date, calendar: Calendar) -> Date {
        guard let start = calendar.date(bySettingHour: minute / 60, minute: minute % 60, second: 0, of: day) else {
            preconditionFailure("Calendar could not set minute \(minute) on \(day)")
        }
        return start
    }
}
