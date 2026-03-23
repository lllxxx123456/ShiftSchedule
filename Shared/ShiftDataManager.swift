import Foundation

class ShiftDataManager {
    static let shared = ShiftDataManager()

    private let suiteName = "group.com.myshift.schedule"
    private let schedulesKey = "savedSchedules"
    private let widgetShiftsKey = "widgetShifts"

    private var userDefaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? UserDefaults.standard
    }

    let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "zh_CN")
        return f
    }()

    func dateString(from date: Date) -> String {
        dateFormatter.string(from: date)
    }

    func date(from string: String) -> Date? {
        dateFormatter.date(from: string)
    }

    // MARK: - Schedules CRUD
    func saveSchedules(_ schedules: [Schedule]) {
        if let data = try? JSONEncoder().encode(schedules) {
            userDefaults.set(data, forKey: schedulesKey)
            userDefaults.synchronize()
            UserDefaults.standard.set(data, forKey: schedulesKey)
            UserDefaults.standard.synchronize()
        }
        syncWidgetData(schedules)
    }

    func loadSchedules() -> [Schedule] {
        let data = userDefaults.data(forKey: schedulesKey) ?? UserDefaults.standard.data(forKey: schedulesKey)
        guard let data = data else { return [] }
        return (try? JSONDecoder().decode([Schedule].self, from: data)) ?? []
    }

    func syncWidgetData(_ schedules: [Schedule]) {
        if let starred = schedules.first(where: { $0.isStarred }) {
            if let data = try? JSONEncoder().encode(starred.shifts) {
                userDefaults.set(data, forKey: widgetShiftsKey)
                userDefaults.synchronize()
                UserDefaults.standard.set(data, forKey: widgetShiftsKey)
                UserDefaults.standard.synchronize()
            }
        }
    }

    func loadWidgetShifts() -> [String: DayShift] {
        let data = userDefaults.data(forKey: widgetShiftsKey) ?? UserDefaults.standard.data(forKey: widgetShiftsKey)
        guard let data = data else { return [:] }
        return (try? JSONDecoder().decode([String: DayShift].self, from: data)) ?? [:]
    }

    // MARK: - Generate Shifts from Pattern
    func generateShifts(pattern: SchedulePattern, from startDate: Date, to endDate: Date) -> [String: DayShift] {
        var shifts: [String: DayShift] = [:]
        let calendar = Calendar.current
        let cycleLength = pattern.cycle.count

        var current = startDate
        var index = 0

        while current <= endDate {
            let key = dateString(from: current)
            let shiftType = pattern.cycle[index % cycleLength]

            var sTime: String?
            var eTime: String?

            switch shiftType {
            case .fuzhong:
                sTime = pattern.fuzhongStartTime
                eTime = pattern.fuzhongEndTime
            case .kuguang:
                sTime = pattern.kuguanStartTime
                eTime = pattern.kuguanEndTime
            case .work:
                sTime = pattern.workStartTime
                eTime = pattern.workEndTime
            case .rest:
                break
            }

            shifts[key] = DayShift(
                id: key,
                shiftType: shiftType,
                startTime: sTime,
                endTime: eTime,
                location: nil,
                notes: nil
            )

            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
            index += 1
        }

        return shifts
    }
}
