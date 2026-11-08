import SwiftUI
import ZumptKit

struct DayColumn: View {
    let day: Date
    let items: [PositionedItem]
    let colors: [String: CalendarColor]
    let isWeekend: Bool
    let nowMinute: Int?
    let calendar: Calendar
    @Binding var selectedEventID: String?
    let dropTask: (UUID, Date) -> Void

    @State private var dropMinute: Int?

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                ForEach(items, id: \.item.id) { positioned in
                    let frame = Self.frame(of: positioned, columnWidth: proxy.size.width)
                    switch positioned.item {
                    case .event(let event):
                        EventBlock(
                            event: event,
                            color: colors[event.calendarID] ?? .unknown,
                            height: frame.height,
                            selectedEventID: $selectedEventID
                        )
                        .frame(width: frame.width, height: frame.height)
                        .eventDetailsPopover(for: event, selectedEventID: $selectedEventID)
                        .offset(x: frame.minX, y: frame.minY)
                    case .task(let task):
                        TaskBlock(task: task)
                            .frame(width: frame.width, height: frame.height)
                            .offset(x: frame.minX, y: frame.minY)
                    }
                }
                if let dropMinute {
                    TaskDropPreview(start: TaskDrop.start(atMinute: dropMinute, on: day, calendar: calendar))
                        .frame(
                            width: max(proxy.size.width - 6, 0),
                            height: WeekGridMetrics.y(forMinute: TaskItem.durationInMinutes) - 2
                        )
                        .offset(x: 3, y: WeekGridMetrics.y(forMinute: dropMinute))
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
        .dropDestination(for: TaskDragItem.self) { items, session in
            dropMinute = nil
            let start = TaskDrop.start(atMinute: Self.dropMinute(at: session.location), on: day, calendar: calendar)
            for item in items {
                dropTask(item.id, start)
            }
        }
        .onDropSessionUpdated { session in
            switch session.phase {
            case .entering, .active:
                dropMinute = session.localSession == nil ? nil : Self.dropMinute(at: session.location)
            default:
                dropMinute = nil
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("day-column-\(dayIdentifier)")
    }

    private var dayIdentifier: String {
        let components = calendar.dateComponents([.year, .month, .day], from: day)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }

    private static func dropMinute(at location: CGPoint) -> Int {
        TaskDrop.startMinute(at: WeekGridMetrics.minute(forY: location.y))
    }

    private static func frame(of positioned: PositionedItem, columnWidth: CGFloat) -> CGRect {
        let inset: CGFloat = 3
        let gap: CGFloat = 2
        let columnCount = CGFloat(positioned.columnCount)
        let singleColumnWidth = (columnWidth - inset * 2 - gap * (columnCount - 1)) / columnCount
        let columnSpan = CGFloat(positioned.columnSpan)
        let width = singleColumnWidth * columnSpan + gap * (columnSpan - 1)
        let duration = positioned.endMinute - positioned.startMinute
        return CGRect(
            x: inset + CGFloat(positioned.column) * (singleColumnWidth + gap),
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

extension View {
    func eventDetailsPopover(for event: CalendarEvent, selectedEventID: Binding<String?>) -> some View {
        modifier(EventDetailsPopover(event: event, selectedEventID: selectedEventID))
    }
}

private struct EventDetailsPopover: ViewModifier {
    let event: CalendarEvent
    @Binding var selectedEventID: String?

    @Environment(\.locale) private var locale

    func body(content: Content) -> some View {
        content.popover(isPresented: isPresented, arrowEdge: .trailing) {
            EventDetailsView(event: event)
                .environment(\.locale, locale)
        }
    }

    private var isPresented: Binding<Bool> {
        Binding(
            get: { selectedEventID == event.id },
            set: { isPresented in
                if !isPresented, selectedEventID == event.id {
                    selectedEventID = nil
                }
            }
        )
    }
}

private struct EventBlock: View {
    let event: CalendarEvent
    let color: CalendarColor
    let height: CGFloat
    @Binding var selectedEventID: String?

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.locale) private var locale

    var body: some View {
        let palette = EventPalette(base: color, colorScheme: colorScheme)
        let isSelected = selectedEventID == event.id
        Button {
            selectedEventID = event.id
        } label: {
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
            .foregroundStyle(isSelected ? palette.selectedText : palette.text)
            .background(isSelected ? palette.selectedFill : palette.fill, in: .rect(cornerRadius: 5))
            .clipShape(.rect(cornerRadius: 5))
            .contentShape(.rect(cornerRadius: 5))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("event-\(event.title)")
    }

    private var showsTime: Bool {
        height >= 36
    }

    private var timeRange: String {
        (event.start..<event.end).formatted(Date.IntervalFormatStyle(date: .omitted, time: .shortened, locale: locale))
    }
}

private struct TaskDropPreview: View {
    let start: Date

    @Environment(\.locale) private var locale

    var body: some View {
        Text(TaskBlock.timeRange(from: start, locale: locale))
            .font(.system(size: 11, weight: .semibold))
            .monospacedDigit()
            .lineLimit(1)
            .foregroundStyle(Color.task)
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(Color.task.opacity(0.12), in: .rect(cornerRadius: 6))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color.task, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
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
            .allowsHitTesting(false)
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
