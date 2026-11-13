import Foundation
import Observation
import ZumptKit

enum SidebarTab: String, CaseIterable, Identifiable {
    case calendar
    case backlog

    var id: Self {
        self
    }
}

@Observable
final class Workspace {
    var sidebarTab: SidebarTab {
        didSet { defaults?.set(sidebarTab.rawValue, forKey: Key.sidebarTab) }
    }

    var backlogFilter: BacklogFilter {
        didSet { defaults?.set(backlogFilter.rawValue, forKey: Key.backlogFilter) }
    }

    var isBacklogVisible: Bool {
        didSet { defaults?.set(isBacklogVisible, forKey: Key.isBacklogVisible) }
    }

    var isAddingTask = false
    private(set) var newTaskRequests = 0

    @ObservationIgnored private let defaults: UserDefaults?

    init(defaults: UserDefaults?) {
        self.defaults = defaults
        sidebarTab = defaults?.string(forKey: Key.sidebarTab).flatMap(SidebarTab.init(rawValue:)) ?? .calendar
        backlogFilter = defaults?.string(forKey: Key.backlogFilter).flatMap(BacklogFilter.init(rawValue:)) ?? .all
        isBacklogVisible = defaults?.object(forKey: Key.isBacklogVisible) as? Bool ?? true
    }

    func beginNewTask() {
        isBacklogVisible = true
        backlogFilter = .all
        isAddingTask = true
        newTaskRequests += 1
    }

    func endNewTask() {
        isAddingTask = false
    }

    func showBacklog(filter: BacklogFilter) {
        backlogFilter = filter
        isBacklogVisible = true
    }

    private enum Key {
        static let sidebarTab = "sidebarTab"
        static let backlogFilter = "backlogFilter"
        static let isBacklogVisible = "isBacklogVisible"
    }
}

extension Workspace {
    static func make(options: LaunchOptions) -> Workspace {
        switch options.preferences {
        case .standard:
            Workspace(defaults: .standard)
        case .memory:
            Workspace(defaults: nil)
        case .suite(let name):
            Workspace(defaults: UserDefaults(suiteName: name))
        }
    }
}
