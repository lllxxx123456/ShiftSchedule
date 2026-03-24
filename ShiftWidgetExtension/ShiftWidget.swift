import WidgetKit
import SwiftUI

// MARK: - Timeline Entry
struct ShiftEntry: TimelineEntry {
    let date: Date
    let shifts: [String: DayShift]
    let scheduleName: String
    let shiftTypeColors: [String: ShiftColorConfig]
}

extension ShiftEntry {
    func resolvedShiftColor(for shift: DayShift) -> Color {
        if let c = shift.customColors?.shiftColor { return c }
        if let c = shiftTypeColors[shift.shiftType.rawValue]?.shiftColor { return c }
        return shift.shiftType.color
    }
}

// MARK: - Timeline Provider
struct ShiftWidgetProvider: TimelineProvider {
    private let dataManager = ShiftDataManager.shared

    func placeholder(in context: Context) -> ShiftEntry {
        ShiftEntry(date: Date(), shifts: [:], scheduleName: "排班表", shiftTypeColors: [:])
    }

    func getSnapshot(in context: Context, completion: @escaping (ShiftEntry) -> Void) {
        let result = loadStarredData()
        let entry = ShiftEntry(date: Date(), shifts: result.shifts, scheduleName: result.name, shiftTypeColors: result.colors)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ShiftEntry>) -> Void) {
        let result = loadStarredData()
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let entries = (0..<30).compactMap { offset -> ShiftEntry? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: startOfToday) else { return nil }
            return ShiftEntry(date: date, shifts: result.shifts, scheduleName: result.name, shiftTypeColors: result.colors)
        }
        let nextRefresh = calendar.date(byAdding: .day, value: 30, to: startOfToday) ?? Date()
        let timeline = Timeline(entries: entries, policy: .after(nextRefresh))
        completion(timeline)
    }

    private func loadStarredData() -> (shifts: [String: DayShift], name: String, colors: [String: ShiftColorConfig]) {
        let schedules = dataManager.loadSchedules()
        let info = dataManager.loadWidgetInfo()
        let starredSchedule = schedules.first(where: { $0.isStarred }) ?? schedules.first
        let colors = starredSchedule?.shiftTypeColors ?? [:]
        if !info.shifts.isEmpty {
            return (info.shifts, info.name, colors)
        }
        if let target = starredSchedule {
            return (target.shifts, target.name, colors)
        }
        return ([:], "排班表", [:])
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
        f.locale = Locale(identifier: "zh_CN")
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
        f.locale = Locale(identifier: "zh_CN")
        return f
    }()

    private let weekdays = ["日", "一", "二", "三", "四", "五", "六"]

    var body: some View {
        let calendar = Calendar.current
        let today = entry.date
        let weekday = calendar.component(.weekday, from: today)
        let startOfWeek = calendar.date(byAdding: .day, value: -(weekday - 1), to: today) ?? today
        let weekDates = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }

        VStack(spacing: 4) {
            HStack {
                Text(entry.scheduleName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text(monthYearString(today))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
            }

            HStack(spacing: 0) {
                ForEach(Array(weekdays.enumerated()), id: \.offset) { index, day in
                    Text(day)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(index == 0 || index == 6 ? .white.opacity(0.6) : .white.opacity(0.85))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 2)

            HStack(spacing: 2) {
                ForEach(Array(weekDates.enumerated()), id: \.offset) { _, date in
                    let key = dateFormatter.string(from: date)
                    let shift = entry.shifts[key]
                    let isToday = calendar.isDateInToday(date)
                    let dayNum = calendar.component(.day, from: date)

                    VStack(spacing: 2) {
                        Text("\(dayNum)")
                            .font(.system(size: 16, weight: isToday ? .heavy : .semibold, design: .rounded))
                            .foregroundColor(.white)

                        Text(LunarCalendarHelper.lunarDateString(for: date))
                            .font(.system(size: 8))
                            .foregroundColor(.white.opacity(0.75))
                            .lineLimit(1)

                        if let shift = shift {
                            Text(shift.shiftType.rawValue)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(entry.resolvedShiftColor(for: shift))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(.white)
                                .clipShape(Capsule())
                        } else {
                            Color.clear.frame(height: 16)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isToday ? .white.opacity(0.2) : .clear)
                    )
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
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
        f.locale = Locale(identifier: "zh_CN")
        return f
    }()

    private let weekdays = ["日", "一", "二", "三", "四", "五", "六"]

    var body: some View {
        let calendar = Calendar.current
        let today = entry.date
        let weekday = calendar.component(.weekday, from: today)
        let startOfWeek = calendar.date(byAdding: .day, value: -(weekday - 1), to: today) ?? today
        let allDates = (0..<28).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }

        let todayShift = entry.shifts[dateFormatter.string(from: today)]
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        let tomorrowShift = entry.shifts[dateFormatter.string(from: tomorrow)]

        VStack(spacing: 0) {
            // 顶部：居中排班表名称
            Text(entry.scheduleName)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 5)

            // 星期表头
            HStack(spacing: 0) {
                ForEach(Array(weekdays.enumerated()), id: \.offset) { index, day in
                    Text(day)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(index == 0 || index == 6 ? .white.opacity(0.55) : .white.opacity(0.85))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 4)

            // 4 行日历
            ForEach(0..<4, id: \.self) { weekIndex in
                let weekDates = Array(allDates[(weekIndex * 7)..<(weekIndex * 7 + 7)])
                largeWeekRow(weekDates, calendar: calendar)
            }

            // 分割线
            Rectangle()
                .fill(.white.opacity(0.15))
                .frame(height: 1)
                .padding(.vertical, 4)

            // 底部：今天 / 明天
            HStack(spacing: 0) {
                HStack(spacing: 6) {
                    Image(systemName: todayShift?.shiftType.icon ?? "calendar")
                        .font(.system(size: 16))
                        .foregroundColor(.white)

                    VStack(alignment: .leading, spacing: 0) {
                        Text("今天")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        Text(todayShift?.shiftType.rawValue ?? "未排班")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    if let shift = todayShift, let start = shift.startTime, let end = shift.endTime {
                        Text("\(start)-\(end)")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 1, height: 28)
                    .padding(.horizontal, 6)

                HStack(spacing: 6) {
                    Image(systemName: tomorrowShift?.shiftType.icon ?? "calendar")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.85))

                    VStack(alignment: .leading, spacing: 0) {
                        Text("明天")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        Text(tomorrowShift?.shiftType.rawValue ?? "未排班")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.95))
                    }

                    Spacer()

                    if let shift = tomorrowShift, let start = shift.startTime, let end = shift.endTime {
                        Text("\(start)-\(end)")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 2)
        }
        .padding(.horizontal, 10)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [
                    Color(red: 79/255, green: 70/255, blue: 229/255),
                    Color(red: 109/255, green: 90/255, blue: 245/255),
                    Color(red: 139/255, green: 115/255, blue: 252/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private func largeWeekRow(_ dates: [Date], calendar: Calendar) -> some View {
        HStack(spacing: 3) {
            ForEach(Array(dates.enumerated()), id: \.offset) { _, date in
                let key = dateFormatter.string(from: date)
                let shift = entry.shifts[key]
                let isToday = calendar.isDateInToday(date)
                let dayNum = calendar.component(.day, from: date)

                VStack(spacing: 3) {
                    Text("\(dayNum)")
                        .font(.system(size: 17, weight: isToday ? .heavy : .medium, design: .rounded))
                        .foregroundColor(.white)

                    if let shift = shift {
                        Text(shift.shiftType.rawValue)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(shiftTextColor(shift))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 3)
                            .background(shiftBgColor(shift))
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    } else {
                        Text(" ")
                            .font(.system(size: 12))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 3)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isToday ? .white.opacity(0.18) : .clear)
                )
            }
        }
        .frame(maxHeight: .infinity)
    }

    private func shiftTextColor(_ shift: DayShift) -> Color {
        if let c = shift.customColors?.shiftColor { return c }
        if let c = entry.shiftTypeColors[shift.shiftType.rawValue]?.shiftColor { return c }
        switch shift.shiftType {
        case .fuzhong: return Color(red: 79/255, green: 70/255, blue: 229/255)
        case .kuguang: return Color(red: 194/255, green: 100/255, blue: 20/255)
        case .work: return Color(red: 180/255, green: 30/255, blue: 30/255)
        case .rest: return Color(red: 16/255, green: 130/255, blue: 60/255)
        }
    }

    private func shiftBgColor(_ shift: DayShift) -> Color {
        if let c = shift.customColors?.bgColor { return c }
        if let c = entry.shiftTypeColors[shift.shiftType.rawValue]?.bgColor { return c }
        switch shift.shiftType {
        case .fuzhong: return Color(red: 224/255, green: 221/255, blue: 255/255)
        case .kuguang: return Color(red: 255/255, green: 230/255, blue: 190/255)
        case .work: return Color(red: 254/255, green: 226/255, blue: 226/255)
        case .rest: return Color(red: 200/255, green: 245/255, blue: 220/255)
        }
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
        .description("在桌面查看星标排班表信息")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
