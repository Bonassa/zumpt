import AppKit
import SwiftUI
import ZumptKit

struct RootView: View {
    let calendarModel: CalendarModel
    let taskModel: TaskModel

    var body: some View {
        content
            .frame(minWidth: 1180, minHeight: 640)
            .toolbar(removing: .title)
            .task {
                await calendarModel.observeStoreChanges()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                calendarModel.refresh()
            }
    }

    @ViewBuilder
    private var content: some View {
        switch calendarModel.access {
        case .granted:
            CalendarScreen(model: calendarModel, taskModel: taskModel)
        case .notDetermined, .denied:
            CalendarAccessView(access: calendarModel.access) {
                Task {
                    await calendarModel.requestAccess()
                }
            }
        }
    }
}
