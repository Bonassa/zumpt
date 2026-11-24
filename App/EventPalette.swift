import SwiftUI
import ZumptKit

struct EventPalette {
    let base: CalendarColor
    let colorScheme: ColorScheme

    var fill: Color {
        colorScheme == .dark ? base.color.mix(with: .black, by: 0.62) : base.color.mix(with: .white, by: 0.86)
    }

    var text: Color {
        colorScheme == .dark ? base.color.mix(with: .white, by: 0.5) : base.color.mix(with: .black, by: 0.42)
    }

    var selectedFill: Color {
        isLight ? base.color : base.color.mix(with: .black, by: 0.2)
    }

    var selectedText: Color {
        isLight ? .black : .white
    }

    private var isLight: Bool {
        base.relativeLuminance > 0.5
    }
}

extension CalendarColor {
    static let unknown = CalendarColor(red: 0.56, green: 0.56, blue: 0.58)

    var color: Color {
        Color(.sRGB, red: red, green: green, blue: blue)
    }

    var relativeLuminance: Double {
        func linear(_ component: Double) -> Double {
            component <= 0.04045 ? component / 12.92 : pow((component + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }
}

extension Color {
    static let today = Color(.sRGB, red: 217 / 255, green: 58 / 255, blue: 63 / 255)
    static let gridLine = Color.primary.opacity(0.08)
    static let strongGridLine = Color.primary.opacity(0.13)
}
