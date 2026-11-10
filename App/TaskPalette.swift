import AppKit
import SwiftUI

extension Color {
    static let task = Color(
        light: NSColor(srgbRed: 45 / 255, green: 100 / 255, blue: 216 / 255, alpha: 1),
        dark: NSColor(srgbRed: 102 / 255, green: 148 / 255, blue: 240 / 255, alpha: 1)
    )
    static let taskBlockFill = Color(
        light: .white,
        dark: NSColor(white: 0.17, alpha: 1)
    )
    static let overdue = Color(
        light: NSColor(srgbRed: 163 / 255, green: 39 / 255, blue: 31 / 255, alpha: 1),
        dark: NSColor(srgbRed: 255 / 255, green: 123 / 255, blue: 114 / 255, alpha: 1)
    )
    static let selectedTaskFill = Color(
        light: NSColor(srgbRed: 220 / 255, green: 231 / 255, blue: 251 / 255, alpha: 1),
        dark: NSColor(srgbRed: 31 / 255, green: 47 / 255, blue: 77 / 255, alpha: 1)
    )
    static let doneTaskFill = Color(
        light: NSColor(srgbRed: 246 / 255, green: 246 / 255, blue: 248 / 255, alpha: 1),
        dark: NSColor(white: 0.15, alpha: 1)
    )
    static let doneTaskBorder = Color(
        light: NSColor(srgbRed: 207 / 255, green: 206 / 255, blue: 214 / 255, alpha: 1),
        dark: NSColor(white: 0.32, alpha: 1)
    )
    static let backlogBackground = Color(
        light: NSColor(srgbRed: 0.98, green: 0.98, blue: 0.988, alpha: 1),
        dark: NSColor(white: 0.14, alpha: 1)
    )
    static let backlogCard = Color(
        light: .white,
        dark: NSColor(white: 0.19, alpha: 1)
    )
    static let backlogCardBorder = Color(
        light: NSColor(white: 0, alpha: 0.1),
        dark: NSColor(white: 1, alpha: 0.08)
    )

    init(light: NSColor, dark: NSColor) {
        self.init(
            nsColor: NSColor(name: nil) { appearance in
                appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
            }
        )
    }
}
