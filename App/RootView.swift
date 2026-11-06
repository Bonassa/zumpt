import SwiftUI
import ZumptKit

struct RootView: View {
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            WeekHeader(week: Week(containing: now, calendar: .current))
            Divider()
            Spacer(minLength: 0)
        }
        .frame(minWidth: 960, minHeight: 600)
    }
}
