import SwiftUI

@main
struct ZumptApp: App {
    private static let options = LaunchOptions()

    @State private var calendarModel = CalendarModel.make(options: options)
    @State private var taskModel = TaskModel.make(options: options, calendar: .autoupdatingCurrent)

    var body: some Scene {
        Window(Text(verbatim: "Zumpt"), id: "main") {
            RootView(calendarModel: calendarModel, taskModel: taskModel)
                .environment(\.locale, .app)
        }
        .defaultSize(width: 1440, height: 900)
        .commands {
            CommandGroup(replacing: .newItem) {
                NewTaskCommand()
            }
        }
    }
}
