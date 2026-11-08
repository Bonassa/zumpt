import SwiftUI
import ZumptKit

struct CalendarScreen: View {
    let model: CalendarModel
    let taskModel: TaskModel

    @Environment(\.undoManager) private var undoManager

    var body: some View {
        NavigationSplitView {
            CalendarSidebar(model: model)
                .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 320)
        } detail: {
            HStack(spacing: 0) {
                TimelineView(.everyMinute) { _ in
                    WeekGrid(
                        week: model.week,
                        events: model.visibleEvents,
                        tasks: taskModel.tasks,
                        colors: model.calendarColors,
                        calendar: model.calendar,
                        now: model.now(),
                        dropTask: { id, start in
                            taskModel.move(id, to: start, undoManager: undoManager)
                        }
                    )
                }
                .environment(model)
                Rectangle().fill(Color.gridLine).frame(width: 1)
                BacklogPanel(model: taskModel)
            }
            .background(Color(nsColor: .textBackgroundColor))
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    WeekHeader(week: model.week)
                }
                .sharedBackgroundVisibility(.hidden)
                ToolbarSpacer(.flexible)
                WeekNavigation(model: model)
            }
        }
    }
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
