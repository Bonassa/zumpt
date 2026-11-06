import AppKit
import SwiftUI
import ZumptKit

struct RootView: View {
    let model: CalendarModel

    var body: some View {
        content
            .frame(minWidth: 1000, minHeight: 640)
            .toolbar(removing: .title)
            .task {
                await model.observeStoreChanges()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                model.refresh()
            }
    }

    @ViewBuilder
    private var content: some View {
        switch model.access {
        case .granted:
            CalendarScreen(model: model)
        case .notDetermined, .denied:
            CalendarAccessView(access: model.access) {
                Task {
                    await model.requestAccess()
                }
            }
        }
    }
}
