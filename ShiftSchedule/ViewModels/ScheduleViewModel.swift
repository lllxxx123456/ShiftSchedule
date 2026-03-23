import Foundation
import SwiftUI
import WidgetKit

class ScheduleViewModel: ObservableObject {
    @Published var currentMonth: Date
    @Published var shifts: [String: DayShift] = [:]
    @Published var selectedDate: Date?

    private let dataManager = ShiftDataManager.shared

    private let calendar: Calendar = {
        var cal = Calendar.current
        cal.locale = Locale(identifier: "zh_CN")
        cal.firstWeekday = 1
        return cal
    }()

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "zh_CN")
        return f
    }()

    private let displayDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MM月dd日"
        f.locale = Locale(identifier: "zh_CN")
        return f
    }()

    init() {
        let now = Date()
        let components = Calendar.current.dateComponents([.year, .month], from: now)
        self.currentMonth = Calendar.current.date(from: components) ?? now
        loadShifts()
    }

    func loadShifts() {
        shifts = dataManager.loadShifts()
    }

    func dateString(from date: Date) -> String {
        dateFormatter.string(from: date)
    }

    // MARK: - Display Strings
    var yearString: String {
        "\(calendar.component(.year, from: currentMonth))年"
    }

    var monthString: String {
        let monthNames = ["一月", "二月", "三月", "四月", "五月", "六月",
                          "七月", "八月", "九月", "十月", "十一月", "十二月"]
        let month = calendar.component(.month, from: currentMonth)
        return monthNames[month - 1]
    }

    var todayDateString: String {
        displayDateFormatter.string(from: Date())
    }

    var todayWeekdayString: String {
        let weekdayNames = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        let weekday = calendar.component(.weekday, from: Date())
        return weekdayNames[weekday - 1]
    }

    // MARK: - Navigation
    func previousMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newMonth
        }
    }

    func nextMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newMonth
        }
    }

    func goToToday() {
        let now = Date()
        let components = calendar.dateComponents([.year, .month], from: now)
        if let month = calendar.date(from: components) {
            currentMonth = month
        }
    }

    func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    func isWeekend(_ date: Date) -> Bool {
        let weekday = calendar.component(.weekday, from: date)
        return weekday == 1 || weekday == 7
    }

    // MARK: - Calendar Grid
    struct CalendarDay: Identifiable, Hashable {
        let id: Int
        let date: Date?

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

        static func == (lhs: CalendarDay, rhs: CalendarDay) -> Bool {
            lhs.id == rhs.id
        }
    }

    func daysInCurrentMonth() -> [CalendarDay] {
        guard let range = calendar.range(of: .day, in: .month, for: currentMonth) else { return [] }

        let firstWeekday = calendar.component(.weekday, from: currentMonth)

        var days: [CalendarDay] = []
        var index = 0

        for _ in 0..<(firstWeekday - 1) {
            days.append(CalendarDay(id: index, date: nil))
            index += 1
        }

        for dayOffset in 0..<range.count {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: currentMonth) {
                days.append(CalendarDay(id: index, date: date))
            }
            index += 1
        }

        return days
    }

    // MARK: - Shift Operations
    func saveShift(_ shift: DayShift) {
        dataManager.saveShift(shift)
        loadShifts()
        WidgetCenter.shared.reloadAllTimelines()
        NotificationManager.shared.scheduleShiftNotifications(shifts: shifts)
    }

    func deleteShift(for date: Date) {
        dataManager.deleteShift(for: dateString(from: date))
        loadShifts()
        WidgetCenter.shared.reloadAllTimelines()
        NotificationManager.shared.scheduleShiftNotifications(shifts: shifts)
    }

    func generatePattern(startDate: Date, cyclePosition: CyclePosition,
                         fuzhongStart: String, fuzhongEnd: String,
                         kuguanStart: String, kuguanEnd: String) {
        let fullCycle: [ShiftType] = [.fuzhong, .fuzhong, .rest, .rest, .kuguang, .kuguang, .rest, .rest]
        let offset = cyclePosition.rawValue

        let adjustedStart = calendar.date(byAdding: .day, value: -offset, to: startDate) ?? startDate

        let pattern = SchedulePattern(
            startDate: dateString(from: adjustedStart),
            cycle: fullCycle,
            fuzhongStartTime: fuzhongStart,
            fuzhongEndTime: fuzhongEnd,
            kuguanStartTime: kuguanStart,
            kuguanEndTime: kuguanEnd
        )

        let endDate = calendar.date(byAdding: .year, value: 2, to: adjustedStart) ?? adjustedStart
        dataManager.generateShiftsFromPattern(pattern, until: endDate)
        dataManager.savePattern(pattern)
        loadShifts()
        WidgetCenter.shared.reloadAllTimelines()
        NotificationManager.shared.scheduleShiftNotifications(shifts: shifts)
    }

    func clearAllShifts() {
        dataManager.saveShifts([:])
        loadShifts()
        WidgetCenter.shared.reloadAllTimelines()
        NotificationManager.shared.scheduleShiftNotifications(shifts: [:])
    }

    // MARK: - Week Data for Widget
    func currentWeekDates() -> [Date] {
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        guard let startOfWeek = calendar.date(byAdding: .day, value: -(weekday - 1), to: today) else {
            return []
        }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }

    func twoWeekDates() -> [Date] {
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        guard let startOfWeek = calendar.date(byAdding: .day, value: -(weekday - 1), to: today) else {
            return []
        }
        return (0..<14).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }
}
