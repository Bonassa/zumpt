import SwiftUI

@main
struct ZumptApp: App {
    private let launchOptions = LaunchOptions()

    var body: some Scene {
        Window(Text(verbatim: "Zumpt"), id: "main") {
            RootView(now: launchOptions.now)
                .environment(\.locale, .app)
        }
        .defaultSize(width: 1280, height: 800)
    }
}
