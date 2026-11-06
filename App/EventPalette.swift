import SwiftUI
import ZumptKit

struct EventPalette {
    let base: Color
    let colorScheme: ColorScheme

    var fill: Color {
        colorScheme == .dark ? base.mix(with: .black, by: 0.62) : base.mix(with: .white, by: 0.86)
    }

    var text: Color {
        colorScheme == .dark ? base.mix(with: .white, by: 0.5) : base.mix(with: .black, by: 0.42)
    }
}

extension CalendarColor {
    var color: Color {
        Color(.sRGB, red: red, green: green, blue: blue)
    }
}

extension Color {
    static let today = Color(.sRGB, red: 217 / 255, green: 58 / 255, blue: 63 / 255)
    static let gridLine = Color.primary.opacity(0.08)
    static let strongGridLine = Color.primary.opacity(0.13)
    static let weekendFill = Color.primary.opacity(0.02)
    static let unknownCalendar = Color.gray
}
