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
                        builder.scheduled("Pagar fatura do cartão", day: 0, at: (8, 30), isDone: true),
                        builder.scheduled("Revisar contrato", day: 4, at: (11, 0)),
                        builder.scheduled("Ligar para o banco", day: 4, at: (14, 0)),
                    ]
                case "overdue":
                    [
                        builder.scheduled("Enviar NF de outubro", daysFromToday: -1, at: (10, 0)),
                        builder.scheduled("Pagar boleto", daysFromToday: 0, at: (9, 0)),
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

            func scheduled(
                _ title: String,
                daysFromToday: Int,
                at time: (hour: Int, minute: Int)
            ) -> TaskItem {
                guard let day = calendar.date(byAdding: .day, value: daysFromToday, to: calendar.startOfDay(for: now))
                else {
                    preconditionFailure("Calendar could not add \(daysFromToday) days to \(now)")
                }
                return scheduled(title, on: day, at: time, isDone: false)
            }

            func scheduled(
                _ title: String,
                day: Int,
                at time: (hour: Int, minute: Int),
                isDone: Bool = false
            ) -> TaskItem {
                scheduled(title, on: week.days[day], at: time, isDone: isDone)
            }

            private func scheduled(
                _ title: String,
                on day: Date,
                at time: (hour: Int, minute: Int),
                isDone: Bool
            ) -> TaskItem {
                guard let start = calendar.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: day)
                else {
                    preconditionFailure("Calendar could not set \(time) on \(day)")
                }
                return TaskItem(
                    id: UUID(),
                    title: title,
                    createdAt: now.addingTimeInterval(-86_400),
                    scheduledStart: start,
                    completedAt: isDone ? start.addingTimeInterval(1800) : nil
                )
            }
        }
    }
#endif
