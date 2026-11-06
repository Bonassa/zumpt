import Foundation
import ZumptKit

protocol CalendarStore: AnyObject {
    var access: CalendarAccess { get }
    var changes: AsyncStream<Void> { get }

    func requestAccess() async -> CalendarAccess
    func accounts() -> [CalendarAccount]
    func events(in interval: DateInterval) -> [CalendarEvent]
}
