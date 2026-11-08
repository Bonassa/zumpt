import SwiftUI
import ZumptKit

enum WeekGridMetrics {
    static let hourHeight: CGFloat = 56
    static let gutterWidth: CGFloat = 56
    static let topPadding: CGFloat = 10
    static let bottomPadding: CGFloat = 12
    static let firstVisibleHour = 8
    static let weekendWeight: CGFloat = 0.7

    static var dayHeight: CGFloat {
        hourHeight * 24
    }

    static func y(forMinute minute: Int) -> CGFloat {
        CGFloat(minute) * hourHeight / 60
    }

    static func minute(forY y: CGFloat) -> Double {
        Double(y * 60 / hourHeight)
    }

    static func weight(of day: Date, calendar: Calendar) -> CGFloat {
        calendar.isDateInWeekend(day) ? weekendWeight : 1
    }
}

struct WeekGrid: View {
    let week: Week
    let events: [CalendarEvent]
    let tasks: [TaskItem]
    let colors: [String: CalendarColor]
    let calendar: Calendar
    let now: Date

    @State private var scrollPosition = ScrollPosition(
        y: WeekGridMetrics.y(forMinute: WeekGridMetrics.firstVisibleHour * 60)
    )
    @State private var selectedEventID: String?

    var body: some View {
        VStack(spacing: 0) {
            DayHeaderRow(days: week.days, calendar: calendar, now: now)
            Rectangle().fill(Color.gridLine).frame(height: 1)
            AllDayRow(
                days: week.days,
                events: events,
                colors: colors,
                calendar: calendar,
                selectedEventID: $selectedEventID
            )
            Rectangle().fill(Color.strongGridLine).frame(height: 1)
            ScrollView(.vertical) {
                HStack(alignment: .top, spacing: 0) {
                    HourGutter(calendar: calendar, nowMinute: nowMinute)
                        .frame(width: WeekGridMetrics.gutterWidth)
                    WeightedColumns {
                        ForEach(week.days, id: \.self) { day in
                            DayColumn(
                                day: day,
                                items: DayLayout.timedItems(events: events, tasks: tasks, on: day, calendar: calendar),
                                colors: colors,
                                isWeekend: calendar.isDateInWeekend(day),
                                nowMinute: calendar.isDate(day, inSameDayAs: now) ? nowMinute : nil,
                                calendar: calendar,
                                selectedEventID: $selectedEventID
                            )
                            .layoutValue(
                                key: ColumnWeight.self,
                                value: WeekGridMetrics.weight(of: day, calendar: calendar)
                            )
                        }
                    }
                }
                .padding(.top, WeekGridMetrics.topPadding)
                .padding(.bottom, WeekGridMetrics.bottomPadding)
            }
            .scrollPosition($scrollPosition)
            .scrollIndicators(.never)
        }
    }

    private var nowMinute: Int? {
        guard week.contains(now, calendar: calendar) else {
            return nil
        }
        let components = calendar.dateComponents([.hour, .minute], from: now)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }
}

private struct DayHeaderRow: View {
    let days: [Date]
    let calendar: Calendar
    let now: Date

    var body: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: WeekGridMetrics.gutterWidth)
            WeightedColumns {
                ForEach(days, id: \.self) { day in
                    DayHeaderCell(
                        day: day,
                        calendar: calendar,
                        isToday: calendar.isDate(day, inSameDayAs: now),
                        isWeekend: calendar.isDateInWeekend(day)
                    )
                    .layoutValue(key: ColumnWeight.self, value: WeekGridMetrics.weight(of: day, calendar: calendar))
                }
            }
        }
        .frame(height: 46)
    }
}

private struct DayHeaderCell: View {
    let day: Date
    let calendar: Calendar
    let isToday: Bool
    let isWeekend: Bool

    @Environment(\.locale) private var locale

    var body: some View {
        HStack(spacing: 6) {
            Text(weekdayName)
                .font(.system(size: 13, weight: isToday ? .semibold : .regular))
            if isToday {
                Text(dayNumber)
                    .font(.system(size: 14))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(Color.today))
            } else {
                Text(dayNumber)
                    .font(.system(size: 15))
                    .monospacedDigit()
            }
        }
        .foregroundStyle(isWeekend && !isToday ? .secondary : .primary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var weekdayName: String {
        let symbol = day.formatted(Date.FormatStyle(locale: locale, calendar: calendar).weekday(.abbreviated))
        return symbol.trimmingCharacters(in: CharacterSet(charactersIn: ".")).capitalized(with: locale)
    }

    private var dayNumber: String {
        day.formatted(Date.FormatStyle(locale: locale, calendar: calendar).day())
    }
}

private struct AllDayRow: View {
    let days: [Date]
    let events: [CalendarEvent]
    let colors: [String: CalendarColor]
    let calendar: Calendar
    @Binding var selectedEventID: String?

    var body: some View {
        HStack(spacing: 0) {
            Text("all-day")
                .font(.system(size: 10.5))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .padding(.trailing, 8)
                .frame(width: WeekGridMetrics.gutterWidth, alignment: .trailing)
            WeightedColumns {
                ForEach(days, id: \.self) { day in
                    AllDayCell(
                        events: DayLayout.allDayEvents(events, on: day, calendar: calendar),
                        colors: colors,
                        isWeekend: calendar.isDateInWeekend(day),
                        selectedEventID: $selectedEventID
                    )
                    .layoutValue(key: ColumnWeight.self, value: WeekGridMetrics.weight(of: day, calendar: calendar))
                }
            }
        }
        .frame(minHeight: 34)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("all-day-row")
    }
}

private struct AllDayCell: View {
    let events: [CalendarEvent]
    let colors: [String: CalendarColor]
    let isWeekend: Bool
    @Binding var selectedEventID: String?

    var body: some View {
        VStack(spacing: 4) {
            ForEach(events) { event in
                AllDayChip(
                    event: event,
                    color: colors[event.calendarID] ?? .unknown,
                    selectedEventID: $selectedEventID
                )
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 3)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(isWeekend ? Color.weekendFill : Color.clear)
        .overlay(alignment: .leading) {
            Rectangle().fill(Color.gridLine).frame(width: 1)
        }
    }
}

private struct AllDayChip: View {
    let event: CalendarEvent
    let color: CalendarColor
    @Binding var selectedEventID: String?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let palette = EventPalette(base: color, colorScheme: colorScheme)
        let isSelected = selectedEventID == event.id
        Button {
            selectedEventID = event.id
        } label: {
            EventTitle(event: event)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)
                .padding(.horizontal, 7)
                .frame(maxWidth: .infinity, minHeight: 22, maxHeight: 22, alignment: .leading)
                .foregroundStyle(isSelected ? palette.selectedText : palette.text)
                .background(isSelected ? palette.selectedFill : palette.fill, in: .rect(cornerRadius: 5))
                .contentShape(.rect(cornerRadius: 5))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("event-\(event.title)")
        .eventDetailsPopover(for: event, selectedEventID: $selectedEventID)
    }
}

private struct HourGutter: View {
    let calendar: Calendar
    let nowMinute: Int?

    @Environment(\.locale) private var locale

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ForEach(visibleHours, id: \.self) { hour in
                Text(hourLabel(hour))
                    .font(.system(size: 10.5))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .fixedSize()
                    .padding(.trailing, 8)
                    .offset(y: WeekGridMetrics.y(forMinute: hour * 60) - 7)
                    .accessibilityIdentifier("hour-label-\(hour)")
            }
            if let nowMinute {
                Text(nowLabel(nowMinute))
                    .font(.system(size: 10.5, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .fixedSize()
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(Color.today))
                    .padding(.trailing, 4)
                    .offset(y: WeekGridMetrics.y(forMinute: nowMinute) - 8)
                    .accessibilityIdentifier("now-indicator")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .frame(height: WeekGridMetrics.dayHeight)
    }

    private var visibleHours: [Int] {
        (0..<24).filter { hour in
            guard let nowMinute else {
                return true
            }
            return abs(nowMinute - hour * 60) >= 15
        }
    }

    private var usesTwelveHourClock: Bool {
        switch locale.hourCycle {
        case .oneToTwelve, .zeroToEleven: true
        default: false
        }
    }

    private func hourLabel(_ hour: Int) -> String {
        let style = Date.FormatStyle(locale: locale, calendar: calendar)
        return format(
            minute: hour * 60,
            usesTwelveHourClock
                ? style.hour(.defaultDigits(amPM: .abbreviated))
                : style.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits)
        )
    }

    private func nowLabel(_ minute: Int) -> String {
        format(
            minute: minute,
            Date.FormatStyle(locale: locale, calendar: calendar).hour(.defaultDigits(amPM: .omitted)).minute(.twoDigits)
        )
    }

    private func format(minute: Int, _ style: Date.FormatStyle) -> String {
        let components = DateComponents(year: 2001, month: 1, day: 1, hour: minute / 60, minute: minute % 60)
        guard let date = calendar.date(from: components) else {
            return ""
        }
        return date.formatted(style)
    }
}
