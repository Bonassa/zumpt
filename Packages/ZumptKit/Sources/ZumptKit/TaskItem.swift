import Foundation

public struct TaskItem: Identifiable, Hashable, Sendable {
    public static let durationInMinutes = 30

    public let id: UUID
    public var title: String
    public var createdAt: Date
    public var scheduledStart: Date?
    public var completedAt: Date?
    public var missedStart: Date?

    public init(
        id: UUID,
        title: String,
        createdAt: Date,
        scheduledStart: Date? = nil,
        completedAt: Date? = nil,
        missedStart: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.scheduledStart = scheduledStart
        self.completedAt = completedAt
        self.missedStart = missedStart
    }

    public var isDone: Bool {
        completedAt != nil
    }

    public var isOverdue: Bool {
        missedStart != nil && scheduledStart == nil && !isDone
    }

    public var scheduledEnd: Date? {
        scheduledStart?.addingTimeInterval(TimeInterval(Self.durationInMinutes * 60))
    }
}

public enum TaskTitle {
    public static func normalized(_ text: String) -> String? {
        let title =
            text
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return title.isEmpty ? nil : title
    }
}

public enum Backlog {
    public static func tasks(_ tasks: [TaskItem]) -> [TaskItem] {
        let waiting = tasks.filter { $0.scheduledStart == nil && !$0.isDone }
        let overdue =
            waiting
            .compactMap { task in task.missedStart.map { (task, $0) } }
            .sorted { ($0.1, $0.0.id.uuidString) < ($1.1, $1.0.id.uuidString) }
            .map(\.0)
        let unscheduled =
            waiting
            .filter { $0.missedStart == nil }
            .sorted { ($0.createdAt, $0.id.uuidString) > ($1.createdAt, $1.id.uuidString) }
        return overdue + unscheduled
    }
}

public enum OverdueTasks {
    public static func returned(from tasks: [TaskItem], now: Date, calendar: Calendar) -> [TaskItem] {
        let startOfToday = calendar.startOfDay(for: now)
        return tasks.compactMap { task in
            guard let start = task.scheduledStart, !task.isDone, start < startOfToday else {
                return nil
            }
            var overdue = task
            overdue.scheduledStart = nil
            overdue.missedStart = start
            return overdue
        }
    }
}
