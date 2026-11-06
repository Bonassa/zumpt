import SwiftUI

@main
struct ZumptApp: App {
    @State private var model = CalendarModel.make(options: LaunchOptions())

    var body: some Scene {
        Window(Text(verbatim: "Zumpt"), id: "main") {
            RootView(model: model)
                .environment(\.locale, .app)
        }
        .defaultSize(width: 1440, height: 900)
    }
}
