import SwiftUI
import ZumptKit

struct CalendarAccessView: View {
    let access: CalendarAccess
    let requestAccess: () -> Void

    @Environment(\.openURL) private var openURL

    private static let privacySettingsURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars"
    )

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text(title)
                .font(.title2.weight(.semibold))
                .padding(.top, 4)
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)
            actionButton
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .textBackgroundColor))
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
    }

    private var title: LocalizedStringKey {
        access == .denied ? "Calendar access is off" : "Connect your calendar"
    }

    private var message: LocalizedStringKey {
        access == .denied
            ? "To see your events, turn on full access for Zumpt in System Settings > Privacy & Security > Calendars."
            : "Zumpt shows the events from the Calendar app next to your tasks. It only reads them and never changes anything."
    }

    @ViewBuilder
    private var actionButton: some View {
        if access == .denied {
            Button("Open System Settings") {
                if let url = Self.privacySettingsURL {
                    openURL(url)
                }
            }
            .accessibilityIdentifier("open-system-settings")
        } else {
            Button("Allow Access", action: requestAccess)
                .accessibilityIdentifier("allow-calendar-access")
        }
    }
}
