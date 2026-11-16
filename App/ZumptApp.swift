import SwiftUI

@main
struct ZumptApp: App {
    private static let options = LaunchOptions()

    @State private var calendarModel = CalendarModel.make(options: options)
    @State private var taskModel = TaskModel.make(options: options, calendar: .autoupdatingCurrent)
    @State private var workspace = Workspace.make(options: options)

    var body: some Scene {
        Window(Text(verbatim: "Zumpt"), id: "main") {
            RootView(calendarModel: calendarModel, taskModel: taskModel, workspace: workspace)
                .environment(\.locale, .app)
                .preferredColorScheme(Self.options.colorScheme)
        }
        .defaultSize(width: 1440, height: 900)
        .commands {
            CommandGroup(replacing: .newItem) {
                NewTaskCommand()
            }
            CommandGroup(after: .sidebar) {
                BacklogVisibilityCommand()
            }
        }
    }
}
