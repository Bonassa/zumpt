import Foundation

@MainActor
public final class DayChangeObserver {
    private let center: NotificationCenter
    private var observer: (any NSObjectProtocol)?

    public init(center: NotificationCenter = .default, onDayChange: @escaping @MainActor () -> Void) {
        self.center = center
        observer = center.addObserver(forName: .NSCalendarDayChanged, object: nil, queue: .main) { _ in
            MainActor.assumeIsolated {
                onDayChange()
            }
        }
    }

    isolated deinit {
        if let observer {
            center.removeObserver(observer)
        }
    }
}
