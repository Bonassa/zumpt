#if DEBUG
    import Foundation
    import ZumptKit

    enum FixtureTasks {
        static func tasks(named name: String, now: Date) -> [TaskItem] {
            switch name {
            case "backlog":
                [
                    backlog("Pagar conta de luz", createdHoursAgo: 1, now: now),
                    backlog("Marcar dentista", createdHoursAgo: 2, now: now),
                    backlog("Comprar presente da Ana", createdHoursAgo: 3, now: now),
                ]
            default:
                preconditionFailure("Unknown task fixture \(name)")
            }
        }

        private static func backlog(_ title: String, createdHoursAgo hours: Int, now: Date) -> TaskItem {
            TaskItem(id: UUID(), title: title, createdAt: now.addingTimeInterval(-Double(hours) * 3600))
        }
    }
#endif
