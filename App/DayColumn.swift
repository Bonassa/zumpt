import SwiftUI
import ZumptKit

struct DayColumn: View {
    let events: [PositionedEvent]
    let colors: [String: CalendarColor]
    let isWeekend: Bool
    let nowMinute: Int?

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                ForEach(events, id: \.event.id) { positioned in
                    let frame = Self.frame(of: positioned, columnWidth: proxy.size.width)
                    EventBlock(
                        event: positioned.event,
                        color: colors[positioned.event.calendarID]?.color ?? .unknownCalendar,
                        height: frame.height
                    )
                    .frame(width: frame.width, height: frame.height)
                    .offset(x: frame.minX, y: frame.minY)
                }
                if let nowMinute {
                    NowLine()
                        .frame(width: proxy.size.width + 1)
                        .offset(x: -1, y: WeekGridMetrics.y(forMinute: nowMinute) - 1)
                }
            }
        }
        .frame(height: WeekGridMetrics.dayHeight)
        .background {
            DayColumnBackground(isWeekend: isWeekend)
        }
    }

    private static func frame(of positioned: PositionedEvent, columnWidth: CGFloat) -> CGRect {
        let inset: CGFloat = 3
        let gap: CGFloat = 2
        let columnCount = CGFloat(positioned.columnCount)
        let width = (columnWidth - inset * 2 - gap * (columnCount - 1)) / columnCount
        let duration = positioned.endMinute - positioned.startMinute
        return CGRect(
            x: inset + CGFloat(positioned.column) * (width + gap),
            y: WeekGridMetrics.y(forMinute: positioned.startMinute),
            width: max(width, 0),
            height: max(WeekGridMetrics.y(forMinute: duration) - 2, 20)
        )
    }
}

struct EventTitle: View {
    let event: CalendarEvent

    var body: some View {
        if event.title.isEmpty {
            Text("No title")
        } else {
            Text(verbatim: event.title)
        }
    }
}

private struct EventBlock: View {
    let event: CalendarEvent
    let color: Color
    let height: CGFloat

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.locale) private var locale

    var body: some View {
        let palette = EventPalette(base: color, colorScheme: colorScheme)
        VStack(alignment: .leading, spacing: 1) {
            EventTitle(event: event)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(showsTime ? 2 : 1)
            if showsTime {
                Text(timeRange)
                    .font(.system(size: 11))
                    .monospacedDigit()
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, height < 26 ? 3 : 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .foregroundStyle(palette.text)
        .background(palette.fill, in: .rect(cornerRadius: 5))
        .clipShape(.rect(cornerRadius: 5))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("event-\(event.title)")
    }

    private var showsTime: Bool {
        height >= 36
    }

    private var timeRange: String {
        (event.start..<event.end).formatted(Date.IntervalFormatStyle(date: .omitted, time: .shortened, locale: locale))
    }
}

private struct NowLine: View {
    var body: some View {
        Rectangle()
            .fill(Color.today)
            .frame(height: 2)
            .overlay(alignment: .leading) {
                Circle()
                    .fill(Color.today)
                    .frame(width: 10, height: 10)
                    .offset(x: -4)
            }
            .accessibilityHidden(true)
    }
}

private struct DayColumnBackground: View {
    let isWeekend: Bool

    var body: some View {
        Canvas { context, size in
            if isWeekend {
                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.weekendFill))
            }
            for hour in 0..<24 {
                let y = CGFloat(hour) * WeekGridMetrics.hourHeight
                context.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 1)), with: .color(.gridLine))
            }
            context.fill(Path(CGRect(x: 0, y: 0, width: 1, height: size.height)), with: .color(.gridLine))
        }
        .accessibilityHidden(true)
    }
}
