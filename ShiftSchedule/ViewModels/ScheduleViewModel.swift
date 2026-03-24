import Foundation
import SwiftUI
import WidgetKit

class ScheduleViewModel: ObservableObject {
    @Published var currentMonth: Date
    @Published var schedules: [Schedule] = []
    @Published var activeScheduleId: String?
    @Published var selectedDate: Date?
    @Published var weatherData: WeatherData?
    @Published var isLoadingWeather = false

    private let dataManager = ShiftDataManager.shared

    let calendar: Calendar = {
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
        loadSchedules()
    }

    // MARK: - Active Schedule
    var activeSchedule: Schedule? {
        if let id = activeScheduleId {
            return schedules.first(where: { $0.id == id })
        }
        return schedules.first
    }

    var activeShifts: [String: DayShift] {
        activeSchedule?.shifts ?? [:]
    }

    var starredSchedule: Schedule? {
        schedules.first(where: { $0.isStarred })
    }

    // MARK: - Data Loading
    func loadSchedules() {
        schedules = dataManager.loadSchedules()
        if activeScheduleId == nil || !schedules.contains(where: { $0.id == activeScheduleId }) {
            activeScheduleId = schedules.first?.id
        }
        dataManager.syncWidgetData(schedules)
        WidgetCenter.shared.reloadTimelines(ofKind: "ShiftWidget")
        fetchWeatherForActiveSchedule()
    }

    func saveAllSchedules() {
        dataManager.saveSchedules(schedules)
        WidgetCenter.shared.reloadTimelines(ofKind: "ShiftWidget")
        WidgetCenter.shared.reloadAllTimelines()
        if let starred = starredSchedule {
            NotificationManager.shared.scheduleShiftNotifications(shifts: starred.shifts)
        }
    }

    // MARK: - Widget Sync
    func syncWidget() {
        dataManager.syncWidgetData(schedules)
        WidgetCenter.shared.reloadTimelines(ofKind: "ShiftWidget")
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Schedule Switching
    func switchToSchedule(_ id: String) {
        activeScheduleId = id
        fetchWeatherForActiveSchedule()
    }

    // MARK: - Weather
    func fetchWeatherForActiveSchedule() {
        guard let schedule = activeSchedule, !schedule.city.isEmpty else {
            isLoadingWeather = false
            weatherData = nil
            return
        }
        isLoadingWeather = true
        WeatherService.shared.fetchWeather(for: schedule.city) { [weak self] data in
            self?.weatherData = data
            self?.isLoadingWeather = false
        }
    }

    func updateScheduleCity(id: String, city: String) {
        guard let idx = schedules.firstIndex(where: { $0.id == id }) else { return }
        schedules[idx].city = city.trimmingCharacters(in: .whitespacesAndNewlines)
        saveAllSchedules()
        if id == activeScheduleId {
            fetchWeatherForActiveSchedule()
        }
    }

    func dateString(from date: Date) -> String {
        dateFormatter.string(from: date)
    }

    private func normalizedDate(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    // MARK: - Schedule CRUD
    func addSchedule(name: String, setupType: QuickSetupType, colorTag: String = "indigo") {
        var schedule = Schedule(name: name, setupType: setupType, colorTag: colorTag)
        if schedules.isEmpty { schedule.isStarred = true }
        schedules.append(schedule)
        activeScheduleId = schedule.id
        saveAllSchedules()
        fetchWeatherForActiveSchedule()
    }

    func deleteSchedule(id: String) {
        schedules.removeAll(where: { $0.id == id })
        if activeScheduleId == id { activeScheduleId = schedules.first?.id }
        saveAllSchedules()
        fetchWeatherForActiveSchedule()
    }

    func renameSchedule(id: String, name: String) {
        if let idx = schedules.firstIndex(where: { $0.id == id }) {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            schedules[idx].name = trimmed
            saveAllSchedules()
        }
    }

    func setStarred(id: String) {
        for i in schedules.indices {
            schedules[i].isStarred = (schedules[i].id == id)
        }
        saveAllSchedules()
    }

    func updateYearsForward(id: String, years: Int) {
        guard let idx = schedules.firstIndex(where: { $0.id == id }),
              let pattern = schedules[idx].pattern else { return }
        schedules[idx].yearsForward = years
        regenerateShifts(for: idx, pattern: pattern)
        saveAllSchedules()
    }

    // MARK: - Merged Schedule
    func createMergedSchedule(name: String, sourceIds: [String]) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        var merged = Schedule(name: trimmedName.isEmpty ? "汇总排班" : trimmedName, colorTag: "purple")
        merged.isMerged = true
        merged.sourceScheduleIds = sourceIds
        rebuildMergedShifts(&merged)
        schedules.append(merged)
        saveAllSchedules()
    }

    func rebuildMergedShifts(_ merged: inout Schedule) {
        var allKeys = Set<String>()
        let sources = schedules.filter { merged.sourceScheduleIds.contains($0.id) }
        for s in sources { allKeys.formUnion(s.shifts.keys) }

        var mergedShifts: [String: DayShift] = [:]
        for key in allKeys {
            var infos: [MergedDayInfo] = []
            var primaryType: ShiftType = .rest
            for s in sources {
                if let shift = s.shifts[key] {
                    infos.append(MergedDayInfo(scheduleName: s.name, shiftType: shift.shiftType, colorTag: s.colorTag))
                    if shift.shiftType != .rest { primaryType = shift.shiftType }
                }
            }
            let notesJson = (try? JSONEncoder().encode(infos)).flatMap { String(data: $0, encoding: .utf8) }
            mergedShifts[key] = DayShift(id: key, shiftType: primaryType, notes: notesJson)
        }
        merged.shifts = mergedShifts
    }

    func refreshMergedSchedules() {
        for i in schedules.indices where schedules[i].isMerged {
            rebuildMergedShifts(&schedules[i])
        }
        saveAllSchedules()
    }

    func getMergedInfos(for dateKey: String) -> [MergedDayInfo] {
        guard let schedule = activeSchedule, schedule.isMerged,
              let shift = schedule.shifts[dateKey],
              let notesStr = shift.notes,
              let data = notesStr.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([MergedDayInfo].self, from: data)) ?? []
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
        func hash(into hasher: inout Hasher) { hasher.combine(id) }
        static func == (lhs: CalendarDay, rhs: CalendarDay) -> Bool { lhs.id == rhs.id }
    }

    func daysInMonth(_ month: Date) -> [CalendarDay] {
        guard let range = calendar.range(of: .day, in: .month, for: month) else { return [] }
        let firstWeekday = calendar.component(.weekday, from: month)
        var days: [CalendarDay] = []
        var index = 0
        for _ in 0..<(firstWeekday - 1) {
            days.append(CalendarDay(id: index, date: nil))
            index += 1
        }
        for dayOffset in 0..<range.count {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: month) {
                days.append(CalendarDay(id: index, date: date))
            }
            index += 1
        }
        return days
    }

    func daysInCurrentMonth() -> [CalendarDay] {
        daysInMonth(currentMonth)
    }

    // MARK: - Shift Operations
    func saveShift(_ shift: DayShift) {
        guard let idx = schedules.firstIndex(where: { $0.id == activeScheduleId }) else { return }
        guard !schedules[idx].isMerged else { return }
        schedules[idx].shifts[shift.id] = shift
        refreshMergedSchedules()
    }

    func deleteShift(for date: Date) {
        guard let idx = schedules.firstIndex(where: { $0.id == activeScheduleId }) else { return }
        guard !schedules[idx].isMerged else { return }
        schedules[idx].shifts.removeValue(forKey: dateString(from: date))
        refreshMergedSchedules()
    }

    // MARK: - Pattern Generation (上二休二)
    func generateTwoOnTwoOff(scheduleId: String, startDate: Date, cyclePosition: CyclePosition,
                              fuzhongStart: String, fuzhongEnd: String,
                              kuguanStart: String, kuguanEnd: String) {
        guard let idx = schedules.firstIndex(where: { $0.id == scheduleId }) else { return }
        guard !schedules[idx].isMerged else { return }
        let fullCycle: [ShiftType] = [.fuzhong, .fuzhong, .rest, .rest, .kuguang, .kuguang, .rest, .rest]
        let offset = cyclePosition.rawValue
        let knownDate = normalizedDate(startDate)
        let adjustedStart = calendar.date(byAdding: .day, value: -offset, to: knownDate) ?? knownDate

        let pattern = SchedulePattern(
            startDate: dateString(from: adjustedStart),
            cycle: fullCycle,
            fuzhongStartTime: fuzhongStart,
            fuzhongEndTime: fuzhongEnd,
            kuguanStartTime: kuguanStart,
            kuguanEndTime: kuguanEnd
        )

        let backward = calendar.date(byAdding: .year, value: -schedules[idx].yearsBackward, to: adjustedStart) ?? adjustedStart
        let forward = calendar.date(byAdding: .year, value: schedules[idx].yearsForward, to: adjustedStart) ?? adjustedStart
        schedules[idx].shifts = dataManager.generateShifts(pattern: pattern, from: backward, to: forward)
        schedules[idx].pattern = pattern
        refreshMergedSchedules()
    }

    // MARK: - Pattern Generation (上一休一)
    func generateOneOnOneOff(scheduleId: String, startDate: Date, simplePosition: SimplePosition,
                              workStart: String, workEnd: String) {
        guard let idx = schedules.firstIndex(where: { $0.id == scheduleId }) else { return }
        guard !schedules[idx].isMerged else { return }
        let fullCycle: [ShiftType] = [.work, .rest]
        let offset = simplePosition.rawValue
        let knownDate = normalizedDate(startDate)
        let adjustedStart = calendar.date(byAdding: .day, value: -offset, to: knownDate) ?? knownDate

        let pattern = SchedulePattern(
            startDate: dateString(from: adjustedStart),
            cycle: fullCycle,
            workStartTime: workStart,
            workEndTime: workEnd
        )

        let backward = calendar.date(byAdding: .year, value: -schedules[idx].yearsBackward, to: adjustedStart) ?? adjustedStart
        let forward = calendar.date(byAdding: .year, value: schedules[idx].yearsForward, to: adjustedStart) ?? adjustedStart
        schedules[idx].shifts = dataManager.generateShifts(pattern: pattern, from: backward, to: forward)
        schedules[idx].pattern = pattern
        refreshMergedSchedules()
    }

    private func regenerateShifts(for idx: Int, pattern: SchedulePattern) {
        guard let startDate = dataManager.date(from: pattern.startDate) else { return }
        let normalizedStartDate = normalizedDate(startDate)
        let backward = calendar.date(byAdding: .year, value: -schedules[idx].yearsBackward, to: normalizedStartDate) ?? normalizedStartDate
        let forward = calendar.date(byAdding: .year, value: schedules[idx].yearsForward, to: normalizedStartDate) ?? normalizedStartDate
        schedules[idx].shifts = dataManager.generateShifts(pattern: pattern, from: backward, to: forward)
    }

    func clearScheduleShifts(id: String) {
        if let idx = schedules.firstIndex(where: { $0.id == id }) {
            guard !schedules[idx].isMerged else { return }
            schedules[idx].shifts = [:]
            schedules[idx].pattern = nil
            refreshMergedSchedules()
        }
    }
}
