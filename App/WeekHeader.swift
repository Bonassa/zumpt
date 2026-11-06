import SwiftUI
import ZumptKit

struct WeekHeader: View {
    let week: Week

    @Environment(\.locale) private var locale

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(title)
                .tracking(-0.48)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("week-header-title")
            Text("Week \(week.number)")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("week-header-number")
        }
        .fixedSize()
        .padding(.leading, 4)
    }

    private var title: AttributedString {
        let monthName = week.midweekDay.formatted(Date.FormatStyle(locale: locale).month(.wide))
        let year = week.midweekDay.formatted(Date.FormatStyle(locale: locale).year())

        var month = AttributedString(monthName.capitalized(with: locale))
        month.font = .system(size: 24, weight: .bold)
        var rest = AttributedString(" \(year)")
        rest.font = .system(size: 24, weight: .regular)
        return month + rest
    }
}
