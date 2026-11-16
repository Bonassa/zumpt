import SwiftUI
import ZumptKit

struct AppSidebar: View {
    let calendarModel: CalendarModel
    let taskModel: TaskModel
    @Bindable var workspace: Workspace

    var body: some View {
        content
            .safeAreaInset(edge: .top, spacing: 0) {
                Picker("View", selection: $workspace.sidebarTab) {
                    ForEach(SidebarTab.allCases) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .controlSize(.large)
                .padding(.horizontal, 10)
                .padding(.top, 4)
                .padding(.bottom, 8)
                .accessibilityIdentifier("sidebar-tabs")
            }
    }

    @ViewBuilder
    private var content: some View {
        switch workspace.sidebarTab {
        case .calendar:
            CalendarSidebar(model: calendarModel)
        case .backlog:
            BacklogFilterSidebar(taskModel: taskModel, workspace: workspace)
        }
    }
}

private struct BacklogFilterSidebar: View {
    let taskModel: TaskModel
    let workspace: Workspace

    var body: some View {
        let backlog = taskModel.backlog
        List(selection: selection) {
            Section("Filters") {
                ForEach(BacklogFilter.allCases) { filter in
                    Label(filter.title, systemImage: filter.systemImage)
                        .badge(filter.tasks(in: backlog).count)
                        .tag(filter)
                        .simultaneousGesture(
                            TapGesture().onEnded {
                                workspace.showBacklog(filter: filter)
                            }
                        )
                        .accessibilityIdentifier("backlog-filter-\(filter.rawValue)")
                }
            }
        }
        .listStyle(.sidebar)
    }

    private var selection: Binding<BacklogFilter?> {
        Binding(
            get: { workspace.backlogFilter },
            set: { filter in
                if let filter {
                    workspace.showBacklog(filter: filter)
                }
            }
        )
    }
}

extension SidebarTab {
    var title: LocalizedStringResource {
        switch self {
        case .calendar: "Calendar"
        case .backlog: "Backlog"
        }
    }
}

extension BacklogFilter {
    var title: LocalizedStringResource {
        switch self {
        case .all: "All Tasks"
        case .overdue: "Overdue"
        }
    }

    var systemImage: String {
        switch self {
        case .all: "tray"
        case .overdue: "exclamationmark.circle"
        }
    }
}
