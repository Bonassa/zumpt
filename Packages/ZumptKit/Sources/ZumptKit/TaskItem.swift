import Foundation

public struct TaskItem: Identifiable, Hashable, Sendable {
    public static let durationInMinutes = 30

    public let id: UUID
    public var title: String
    public var createdAt: Date
    public var scheduledStart: Date?

    public init(id: UUID, title: String, createdAt: Date, scheduledStart: Date? = nil) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.scheduledStart = scheduledStart
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
        tasks
            .filter { $0.scheduledStart == nil }
            .sorted { ($0.createdAt, $0.id.uuidString) > ($1.createdAt, $1.id.uuidString) }
    }
}
