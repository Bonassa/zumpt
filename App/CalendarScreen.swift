import SwiftUI
import ZumptKit

struct CalendarScreen: View {
    let model: CalendarModel
    let taskModel: TaskModel
    @Bindable var workspace: Workspace

    @State private var selection = TaskSelection()
    @Environment(\.undoManager) private var undoManager
    @Environment(\.locale) private var locale

    var body: some View {
        @Bindable var selection = selection
        NavigationSplitView {
            AppSidebar(calendarModel: model, taskModel: taskModel, workspace: workspace)
                .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 320)
        } detail: {
            TimelineView(.everyMinute) { _ in
                let now = model.now()
                WeekGrid(
                    week: model.week,
                    events: model.visibleEvents,
                    tasks: taskModel.tasks(in: model.week, now: now),
                    colors: model.calendarColors,
                    calendar: model.calendar,
                    now: now
                )
            }
            .environment(model)
            .background(Color(nsColor: .textBackgroundColor))
            .inspector(isPresented: $workspace.isBacklogVisible) {
                BacklogPanel(model: taskModel, workspace: workspace)
                    .inspectorColumnWidth(BacklogPanel.width)
            }
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    WeekHeader(week: model.week)
                }
                .sharedBackgroundVisibility(.hidden)
                ToolbarSpacer(.flexible)
                WeekNavigation(model: model)
                ToolbarSpacer(.fixed)
                ToolbarItem {
                    BacklogToggle(isVisible: $workspace.isBacklogVisible)
                }
            }
        }
        .environment(taskModel)
        .environment(selection)
        .sheet(item: $selection.editor) { request in
            RecurringTaskEditor(request: request, model: taskModel, undoManager: undoManager)
                .environment(\.locale, locale)
                .environment(\.calendar, taskModel.calendar)
                .environment(\.timeZone, taskModel.calendar.timeZone)
        }
        .focusedSceneValue(\.newTask, workspace.beginNewTask)
        .focusedSceneValue(\.backlogVisibility, $workspace.isBacklogVisible)
    }
}

private struct BacklogToggle: View {
    @Binding var isVisible: Bool

    var body: some View {
        Button {
            isVisible.toggle()
        } label: {
            Label(isVisible ? "Hide Backlog" : "Show Backlog", systemImage: "sidebar.trailing")
        }
        .help(isVisible ? Text("Hide Backlog") : Text("Show Backlog"))
        .accessibilityIdentifier("backlog-toggle")
    }
}

struct BacklogVisibilityCommand: View {
    @FocusedBinding(\.backlogVisibility) private var isVisible

    var body: some View {
        Button(isVisible == true ? "Hide Backlog" : "Show Backlog") {
            isVisible?.toggle()
        }
        .keyboardShortcut("b", modifiers: [.command, .option])
        .disabled(isVisible == nil)
    }
}

extension FocusedValues {
    @Entry var backlogVisibility: Binding<Bool>?
}

private struct WeekNavigation: ToolbarContent {
    let model: CalendarModel

    var body: some ToolbarContent {
        ToolbarItemGroup {
            Button("Previous week", systemImage: "chevron.left") {
                model.showPreviousWeek()
            }
            .help(Text("Previous week"))
            .keyboardShortcut(.leftArrow, modifiers: .command)
            .accessibilityIdentifier("previous-week")

            Button("Today") {
                model.showToday()
            }
            .keyboardShortcut("t", modifiers: .command)
            .accessibilityIdentifier("today")

            Button("Next week", systemImage: "chevron.right") {
                model.showNextWeek()
            }
            .help(Text("Next week"))
            .keyboardShortcut(.rightArrow, modifiers: .command)
            .accessibilityIdentifier("next-week")
        }
    }
}
