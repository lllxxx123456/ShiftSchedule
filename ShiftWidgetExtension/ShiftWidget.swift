import WidgetKit
import SwiftUI

// MARK: - Timeline Entry
struct ShiftEntry: TimelineEntry {
    let date: Date
    let shifts: [String: DayShift]
}

// MARK: - Timeline Provider
struct ShiftWidgetProvider: TimelineProvider {
    private let dataManager = ShiftDataManager.shared

    func placeholder(in context: Context) -> ShiftEntry {
        ShiftEntry(date: Date(), shifts: [:])
    }

    func getSnapshot(in context: Context, completion: @escaping (ShiftEntry) -> Void) {
        let entry = ShiftEntry(date: Date(), shifts: dataManager.loadShifts())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ShiftEntry>) -> Void) {
        let shifts = dataManager.loadShifts()
        let entry = ShiftEntry(date: Date(), shifts: shifts)

        let calendar = Calendar.current
        let nextMidnight = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date())
        let timeline = Timeline(entries: [entry], policy: .after(nextMidnight))
        completion(timeline)
    }
}

// MARK: - Widget Entry View
struct ShiftWidgetEntryView: View {
    var entry: ShiftWidgetProvider.Entry

    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget
struct SmallWidgetView: View {
    let entry: ShiftEntry

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    var body: some View {
        let today = entry.date
        let key = dateFormatter.string(from: today)
        let shift = entry.shifts[key]
        let calendar = Calendar.current
        let day = calendar.component(.day, from: today)
        let weekdayNames = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        let weekday = weekdayNames[calendar.component(.weekday, from: today) - 1]

        VStack(spacing: 6) {
            HStack {
                Text(weekday)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Text(LunarCalendarHelper.lunarDateString(for: today))
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            Text("\(day)")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Spacer()

            if let shift = shift {
                HStack(spacing: 4) {
                    Image(systemName: shift.shiftType.icon)
                        .font(.system(size: 12))
                    Text(shift.shiftType.rawValue)
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(.white.opacity(0.2))
                .clipShape(Capsule())
            } else {
                Text("未排班")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(14)
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: shift?.shiftType.gradientColors ?? [Color(red: 79/255, green: 70/255, blue: 229/255), Color(red: 129/255, green: 100/255, blue: 255/255)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Medium Widget
struct MediumWidgetView: View {
    let entry: ShiftEntry

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private let weekdays = ["日", "一", "二", "三", "四", "五", "六"]

    var body: some View {
        let calendar = Calendar.current
        let today = entry.date
        let weekday = calendar.component(.weekday, from: today)
        let startOfWeek = calendar.date(byAdding: .day, value: -(weekday - 1), to: today) ?? today
        let weekDates = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }

        VStack(spacing: 6) {
            HStack {
                Text("排班表")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text(monthYearString(today))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }

            HStack(spacing: 0) {
                ForEach(Array(weekdays.enumerated()), id: \.offset) { index, day in
                    Text(day)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(index == 0 || index == 6 ? .white.opacity(0.6) : .white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                }
            }

            HStack(spacing: 3) {
                ForEach(Array(weekDates.enumerated()), id: \.offset) { _, date in
                    let key = dateFormatter.string(from: date)
                    let shift = entry.shifts[key]
                    let isToday = calendar.isDateInToday(date)
                    let dayNum = calendar.component(.day, from: date)

                    VStack(spacing: 3) {
                        Text("\(dayNum)")
                            .font(.system(size: 15, weight: isToday ? .heavy : .semibold, design: .rounded))
                            .foregroundColor(.white)

                        Text(LunarCalendarHelper.lunarDateString(for: date))
                            .font(.system(size: 7))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)

                        if let shift = shift {
                            Text(shift.shiftType.rawValue)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(shift.shiftType.color)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(.white)
                                .clipShape(Capsule())
                        } else {
                            Spacer().frame(height: 15)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isToday ? .white.opacity(0.2) : .clear)
                    )
                }
            }
        }
        .padding(12)
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [
                    Color(red: 79/255, green: 70/255, blue: 229/255),
                    Color(red: 129/255, green: 100/255, blue: 255/255),
                    Color(red: 167/255, green: 139/255, blue: 250/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private func monthYearString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy年M月"
        f.locale = Locale(identifier: "zh_CN")
        return f.string(from: date)
    }
}

// MARK: - Large Widget
struct LargeWidgetView: View {
    let entry: ShiftEntry

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private let weekdays = ["日", "一", "二", "三", "四", "五", "六"]

    var body: some View {
        let calendar = Calendar.current
        let today = entry.date
        let weekday = calendar.component(.weekday, from: today)
        let startOfWeek = calendar.date(byAdding: .day, value: -(weekday - 1), to: today) ?? today
        let twoWeekDates = (0..<14).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
        let week1 = Array(twoWeekDates.prefix(7))
        let week2 = Array(twoWeekDates.suffix(7))

        let todayShift = entry.shifts[dateFormatter.string(from: today)]

        VStack(spacing: 8) {
            HStack {
                Text("排班表")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text(monthYearString(today))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }

            HStack(spacing: 0) {
                ForEach(Array(weekdays.enumerated()), id: \.offset) { index, day in
                    Text(day)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(index == 0 || index == 6 ? .white.opacity(0.6) : .white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 4)

            weekRow(week1, calendar: calendar)
            weekRow(week2, calendar: calendar)

            Divider()
                .background(.white.opacity(0.3))

            HStack(spacing: 10) {
                Image(systemName: todayShift?.shiftType.icon ?? "calendar")
                    .font(.system(size: 20))
                    .foregroundColor(.white)

                VStack(alignment: .leading, spacing: 2) {
                    Text("今日 \(todayDateString(today))")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))

                    Text(todayShift?.shiftType.rawValue ?? "未排班")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                Spacer()

                if let shift = todayShift, let start = shift.startTime, let end = shift.endTime {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(start)")
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white)
                        Text("\(end)")
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(14)
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [
                    Color(red: 79/255, green: 70/255, blue: 229/255),
                    Color(red: 129/255, green: 100/255, blue: 255/255),
                    Color(red: 167/255, green: 139/255, blue: 250/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private func weekRow(_ dates: [Date], calendar: Calendar) -> some View {
        HStack(spacing: 3) {
            ForEach(Array(dates.enumerated()), id: \.offset) { _, date in
                let key = dateFormatter.string(from: date)
                let shift = entry.shifts[key]
                let isToday = calendar.isDateInToday(date)
                let dayNum = calendar.component(.day, from: date)

                VStack(spacing: 3) {
                    Text("\(dayNum)")
                        .font(.system(size: 15, weight: isToday ? .heavy : .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Text(LunarCalendarHelper.lunarDateString(for: date))
                        .font(.system(size: 8))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)

                    if let shift = shift {
                        Text(shift.shiftType.rawValue)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(shift.shiftType.color)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(.white)
                            .clipShape(Capsule())
                    } else {
                        Spacer().frame(height: 15)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isToday ? .white.opacity(0.2) : .clear)
                )
            }
        }
    }

    private func monthYearString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy年M月"
        f.locale = Locale(identifier: "zh_CN")
        return f.string(from: date)
    }

    private func todayDateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "M月d日"
        f.locale = Locale(identifier: "zh_CN")
        return f.string(from: date)
    }
}

// MARK: - Widget Definition
struct ShiftWidget: Widget {
    let kind: String = "ShiftWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ShiftWidgetProvider()) { entry in
            ShiftWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("排班表")
        .description("在桌面查看排班信息")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
