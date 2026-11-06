import SwiftUI
import ZumptKit

struct CalendarSidebar: View {
    let model: CalendarModel

    var body: some View {
        List {
            ForEach(model.accounts) { account in
                Section(account.title) {
                    ForEach(account.calendars) { eventCalendar in
                        Toggle(eventCalendar.title, isOn: visibility(of: eventCalendar))
                            .toggleStyle(CalendarCheckboxStyle(color: eventCalendar.color.color))
                            .accessibilityIdentifier("calendar-toggle-\(eventCalendar.id)")
                    }
                }
            }
        }
        .listStyle(.sidebar)
    }

    private func visibility(of eventCalendar: EventCalendar) -> Binding<Bool> {
        Binding(
            get: { model.isVisible(calendarID: eventCalendar.id) },
            set: { model.setVisible($0, calendarID: eventCalendar.id) }
        )
    }
}

private struct CalendarCheckboxStyle: ToggleStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(configuration.isOn ? color : Color.clear)
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(configuration.isOn ? color : Color.secondary.opacity(0.6), lineWidth: 1.5)
                    if configuration.isOn {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 15, height: 15)
                configuration.label
                    .foregroundStyle(configuration.isOn ? .primary : .secondary)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) {
                configuration.label
            }
        }
    }
}
