import Foundation

class ShiftDataManager {
    static let shared = ShiftDataManager()

    private struct WidgetSnapshot: Codable {
        let name: String
        let shifts: [String: DayShift]
    }

    private let suiteName = "group.com.myshift.schedule"
    private let schedulesKey = "savedSchedules"
    private let widgetShiftsKey = "widgetShifts"
    private let widgetSnapshotKey = "widgetSnapshot"
    private let widgetFileName = "widget_snapshot.json"

    private let sharedDefaults: UserDefaults

    private var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: suiteName)
    }

    private var widgetFileURL: URL? {
        containerURL?.appendingPathComponent(widgetFileName)
    }

    init() {
        self.sharedDefaults = UserDefaults(suiteName: "group.com.myshift.schedule") ?? UserDefaults.standard
    }

    private var userDefaults: UserDefaults { sharedDefaults }

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
        }
        syncWidgetData(schedules)
    }

    func loadSchedules() -> [Schedule] {
        if let data = userDefaults.data(forKey: schedulesKey),
           let schedules = try? JSONDecoder().decode([Schedule].self, from: data),
           !schedules.isEmpty {
            return schedules
        }
        if let data = UserDefaults.standard.data(forKey: schedulesKey),
           let schedules = try? JSONDecoder().decode([Schedule].self, from: data),
           !schedules.isEmpty {
            return schedules
        }
        return []
    }

    func syncWidgetData(_ schedules: [Schedule]) {
        // 写入全量排班表供 Widget 直接读取
        if let allData = try? JSONEncoder().encode(schedules) {
            userDefaults.set(allData, forKey: schedulesKey)
        }

        // 确定星标排班表
        let target = schedules.first(where: { $0.isStarred }) ?? schedules.first
        if let target = target {
            // 写入星标排班 shifts
            if let data = try? JSONEncoder().encode(target.shifts) {
                userDefaults.set(data, forKey: widgetShiftsKey)
            }
            // 写入快照到 UserDefaults + 文件双通道
            let snapshot = WidgetSnapshot(name: target.name, shifts: target.shifts)
            if let snapshotData = try? JSONEncoder().encode(snapshot) {
                userDefaults.set(snapshotData, forKey: widgetSnapshotKey)
                if let fileURL = widgetFileURL {
                    try? snapshotData.write(to: fileURL, options: .atomic)
                }
            }
        } else {
            userDefaults.removeObject(forKey: widgetShiftsKey)
            userDefaults.removeObject(forKey: widgetSnapshotKey)
            if let fileURL = widgetFileURL {
                try? FileManager.default.removeItem(at: fileURL)
            }
        }

        userDefaults.synchronize()
    }

    func loadWidgetShifts() -> [String: DayShift] {
        // 1. UserDefaults 快照
        if let snapshotData = userDefaults.data(forKey: widgetSnapshotKey),
           let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: snapshotData),
           !snapshot.shifts.isEmpty {
            return snapshot.shifts
        }
        // 2. UserDefaults shifts
        if let data = userDefaults.data(forKey: widgetShiftsKey),
           let shifts = try? JSONDecoder().decode([String: DayShift].self, from: data),
           !shifts.isEmpty {
            return shifts
        }
        // 3. 文件快照
        if let fileURL = widgetFileURL,
           let data = try? Data(contentsOf: fileURL),
           let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data),
           !snapshot.shifts.isEmpty {
            return snapshot.shifts
        }
        // 4. 全量排班表
        let schedules = loadSchedules()
        let target = schedules.first(where: { $0.isStarred }) ?? schedules.first
        return target?.shifts ?? [:]
    }

    func loadWidgetInfo() -> (shifts: [String: DayShift], name: String) {
        // 1. UserDefaults 快照
        if let snapshotData = userDefaults.data(forKey: widgetSnapshotKey),
           let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: snapshotData),
           !snapshot.shifts.isEmpty {
            return (snapshot.shifts, snapshot.name)
        }
        // 2. 文件快照
        if let fileURL = widgetFileURL,
           let data = try? Data(contentsOf: fileURL),
           let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data),
           !snapshot.shifts.isEmpty {
            return (snapshot.shifts, snapshot.name)
        }
        // 3. 全量排班表
        let schedules = loadSchedules()
        let target = schedules.first(where: { $0.isStarred }) ?? schedules.first
        let shifts = target?.shifts ?? [:]
        let name = target?.name ?? "排班表"
        return (shifts, name)
    }

    // MARK: - Generate Shifts from Pattern
    func generateShifts(pattern: SchedulePattern, from startDate: Date, to endDate: Date) -> [String: DayShift] {
        var shifts: [String: DayShift] = [:]
        let calendar = Calendar.current
        let cycleLength = pattern.cycle.count

        guard let patternOrigin = date(from: pattern.startDate) else { return shifts }

        let normalizedOrigin = calendar.startOfDay(for: patternOrigin)
        let finalDate = calendar.startOfDay(for: endDate)

        var current = calendar.startOfDay(for: startDate)
        while current <= finalDate {
            let key = dateString(from: current)
            let daysDiff = calendar.dateComponents([.day], from: normalizedOrigin, to: current).day ?? 0
            var cycleIndex = daysDiff % cycleLength
            if cycleIndex < 0 { cycleIndex += cycleLength }
            let shiftType = pattern.cycle[cycleIndex]

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
        }

        return shifts
    }
}
