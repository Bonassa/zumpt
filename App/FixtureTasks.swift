#if DEBUG
    import Foundation
    import ZumptKit

    enum FixtureTasks {
        static func tasks(named names: String, now: Date, calendar: Calendar) -> [TaskItem] {
            let builder = Builder(now: now, week: Week(containing: now, calendar: calendar), calendar: calendar)
            return names.split(separator: ",").flatMap { name in
                switch name {
                case "backlog":
                    [
                        builder.backlog("Pagar conta de luz", createdHoursAgo: 1),
                        builder.backlog("Marcar dentista", createdHoursAgo: 2),
                        builder.backlog("Comprar presente da Ana", createdHoursAgo: 3),
                    ]
                case "week":
                    [
                        builder.scheduled("Revisar contrato", day: 5, at: (11, 0)),
                        builder.scheduled("Ligar para o banco", day: 5, at: (14, 0)),
                    ]
                default:
                    preconditionFailure("Unknown task fixture \(name)")
                }
            }
        }

        private struct Builder {
            let now: Date
            let week: Week
            let calendar: Calendar

            func backlog(_ title: String, createdHoursAgo hours: Int) -> TaskItem {
                TaskItem(id: UUID(), title: title, createdAt: now.addingTimeInterval(-Double(hours) * 3600))
            }

            func scheduled(_ title: String, day: Int, at time: (hour: Int, minute: Int)) -> TaskItem {
                let day = week.days[day]
                guard let start = calendar.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: day)
                else {
                    preconditionFailure("Calendar could not set \(time) on \(day)")
                }
                return TaskItem(
                    id: UUID(),
                    title: title,
                    createdAt: now.addingTimeInterval(-86_400),
                    scheduledStart: start
                )
            }
        }
    }
#endif
