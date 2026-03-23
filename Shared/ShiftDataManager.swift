import Foundation

class ShiftDataManager {
    static let shared = ShiftDataManager()

    private let suiteName = "group.com.myshift.schedule"
    private let shiftsKey = "savedShifts"
    private let patternKey = "schedulePattern"

    private var userDefaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? UserDefaults.standard
    }

    private let dateFormatter: DateFormatter = {
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

    // MARK: - Shifts CRUD
    func saveShifts(_ shifts: [String: DayShift]) {
        if let data = try? JSONEncoder().encode(shifts) {
            userDefaults.set(data, forKey: shiftsKey)
            userDefaults.synchronize()
            UserDefaults.standard.set(data, forKey: shiftsKey)
            UserDefaults.standard.synchronize()
        }
    }

    func loadShifts() -> [String: DayShift] {
        let data = userDefaults.data(forKey: shiftsKey) ?? UserDefaults.standard.data(forKey: shiftsKey)
        guard let data = data else { return [:] }
        return (try? JSONDecoder().decode([String: DayShift].self, from: data)) ?? [:]
    }

    func getShift(for date: Date) -> DayShift? {
        loadShifts()[dateString(from: date)]
    }

    func saveShift(_ shift: DayShift) {
        var shifts = loadShifts()
        shifts[shift.id] = shift
        saveShifts(shifts)
    }

    func deleteShift(for dateString: String) {
        var shifts = loadShifts()
        shifts.removeValue(forKey: dateString)
        saveShifts(shifts)
    }

    // MARK: - Pattern
    func savePattern(_ pattern: SchedulePattern) {
        if let data = try? JSONEncoder().encode(pattern) {
            userDefaults.set(data, forKey: patternKey)
            userDefaults.synchronize()
            UserDefaults.standard.set(data, forKey: patternKey)
            UserDefaults.standard.synchronize()
        }
    }

    func loadPattern() -> SchedulePattern? {
        let data = userDefaults.data(forKey: patternKey) ?? UserDefaults.standard.data(forKey: patternKey)
        guard let data = data else { return nil }
        return try? JSONDecoder().decode(SchedulePattern.self, from: data)
    }

    // MARK: - Generate from Pattern
    func generateShiftsFromPattern(_ pattern: SchedulePattern, until endDate: Date) {
        guard let start = date(from: pattern.startDate) else { return }
        var shifts = loadShifts()
        let calendar = Calendar.current
        let cycleLength = pattern.cycle.count

        var current = start
        var index = 0

        while current <= endDate {
            let key = dateString(from: current)
            let shiftType = pattern.cycle[index % cycleLength]

            var startTime: String?
            var endTime: String?

            switch shiftType {
            case .fuzhong:
                startTime = pattern.fuzhongStartTime
                endTime = pattern.fuzhongEndTime
            case .kuguang:
                startTime = pattern.kuguanStartTime
                endTime = pattern.kuguanEndTime
            case .rest:
                break
            }

            shifts[key] = DayShift(
                id: key,
                shiftType: shiftType,
                startTime: startTime,
                endTime: endTime,
                location: nil,
                notes: nil
            )

            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
            index += 1
        }

        saveShifts(shifts)
    }
}
