import Foundation
import SwiftUI

// MARK: - Quick Setup Type
enum QuickSetupType: String, Codable, CaseIterable, Identifiable {
    case twoOnTwoOff = "上二休二"
    case oneOnOneOff = "上一休一"
    var id: String { rawValue }
}

// MARK: - Shift Type
enum ShiftType: String, Codable, CaseIterable, Identifiable {
    case fuzhong = "复重"
    case kuguang = "库管"
    case work = "上班"
    case rest = "休息"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .fuzhong: return Color(red: 79/255, green: 70/255, blue: 229/255)
        case .kuguang: return Color(red: 234/255, green: 138/255, blue: 56/255)
        case .work: return Color(red: 59/255, green: 130/255, blue: 246/255)
        case .rest: return Color(red: 16/255, green: 185/255, blue: 129/255)
        }
    }

    var lightColor: Color {
        switch self {
        case .fuzhong: return Color(red: 224/255, green: 231/255, blue: 255/255)
        case .kuguang: return Color(red: 254/255, green: 235/255, blue: 199/255)
        case .work: return Color(red: 219/255, green: 234/255, blue: 254/255)
        case .rest: return Color(red: 209/255, green: 250/255, blue: 229/255)
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .fuzhong: return [Color(red: 79/255, green: 70/255, blue: 229/255), Color(red: 99/255, green: 102/255, blue: 241/255)]
        case .kuguang: return [Color(red: 234/255, green: 138/255, blue: 56/255), Color(red: 251/255, green: 191/255, blue: 36/255)]
        case .work: return [Color(red: 59/255, green: 130/255, blue: 246/255), Color(red: 96/255, green: 165/255, blue: 250/255)]
        case .rest: return [Color(red: 16/255, green: 185/255, blue: 129/255), Color(red: 52/255, green: 211/255, blue: 153/255)]
        }
    }

    var icon: String {
        switch self {
        case .fuzhong: return "scalemass.fill"
        case .kuguang: return "shippingbox.fill"
        case .work: return "briefcase.fill"
        case .rest: return "moon.stars.fill"
        }
    }

    var description: String {
        switch self {
        case .fuzhong: return "复重岗位"
        case .kuguang: return "库管岗位"
        case .work: return "上班"
        case .rest: return "休息日"
        }
    }
}

// MARK: - Day Shift
struct DayShift: Codable, Identifiable, Equatable {
    var id: String
    var shiftType: ShiftType
    var startTime: String?
    var endTime: String?
    var location: String?
    var notes: String?

    static func == (lhs: DayShift, rhs: DayShift) -> Bool {
        lhs.id == rhs.id && lhs.shiftType == rhs.shiftType
    }
}

// MARK: - Schedule (Multiple schedules support)
struct Schedule: Codable, Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var isStarred: Bool = false
    var shifts: [String: DayShift] = [:]
    var pattern: SchedulePattern? = nil
    var setupType: QuickSetupType = .twoOnTwoOff
    var yearsForward: Int = 2
    var yearsBackward: Int = 2
    var isMerged: Bool = false
    var sourceScheduleIds: [String] = []
    var colorTag: String = "indigo"
    var city: String = ""

    init(
        id: String = UUID().uuidString,
        name: String,
        isStarred: Bool = false,
        shifts: [String: DayShift] = [:],
        pattern: SchedulePattern? = nil,
        setupType: QuickSetupType = .twoOnTwoOff,
        yearsForward: Int = 2,
        yearsBackward: Int = 2,
        isMerged: Bool = false,
        sourceScheduleIds: [String] = [],
        colorTag: String = "indigo",
        city: String = ""
    ) {
        self.id = id
        self.name = name
        self.isStarred = isStarred
        self.shifts = shifts
        self.pattern = pattern
        self.setupType = setupType
        self.yearsForward = yearsForward
        self.yearsBackward = yearsBackward
        self.isMerged = isMerged
        self.sourceScheduleIds = sourceScheduleIds
        self.colorTag = colorTag
        self.city = city
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case isStarred
        case shifts
        case pattern
        case setupType
        case yearsForward
        case yearsBackward
        case isMerged
        case sourceScheduleIds
        case colorTag
        case city
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        name = try container.decode(String.self, forKey: .name)
        isStarred = try container.decodeIfPresent(Bool.self, forKey: .isStarred) ?? false
        shifts = try container.decodeIfPresent([String: DayShift].self, forKey: .shifts) ?? [:]
        pattern = try container.decodeIfPresent(SchedulePattern.self, forKey: .pattern)
        setupType = try container.decodeIfPresent(QuickSetupType.self, forKey: .setupType) ?? .twoOnTwoOff
        yearsForward = try container.decodeIfPresent(Int.self, forKey: .yearsForward) ?? 2
        yearsBackward = try container.decodeIfPresent(Int.self, forKey: .yearsBackward) ?? 2
        isMerged = try container.decodeIfPresent(Bool.self, forKey: .isMerged) ?? false
        sourceScheduleIds = try container.decodeIfPresent([String].self, forKey: .sourceScheduleIds) ?? []
        colorTag = try container.decodeIfPresent(String.self, forKey: .colorTag) ?? "indigo"
        city = try container.decodeIfPresent(String.self, forKey: .city) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(isStarred, forKey: .isStarred)
        try container.encode(shifts, forKey: .shifts)
        try container.encodeIfPresent(pattern, forKey: .pattern)
        try container.encode(setupType, forKey: .setupType)
        try container.encode(yearsForward, forKey: .yearsForward)
        try container.encode(yearsBackward, forKey: .yearsBackward)
        try container.encode(isMerged, forKey: .isMerged)
        try container.encode(sourceScheduleIds, forKey: .sourceScheduleIds)
        try container.encode(colorTag, forKey: .colorTag)
        try container.encode(city, forKey: .city)
    }
}

// MARK: - Schedule Pattern
struct SchedulePattern: Codable {
    var startDate: String
    var cycle: [ShiftType]
    var fuzhongStartTime: String?
    var fuzhongEndTime: String?
    var kuguanStartTime: String?
    var kuguanEndTime: String?
    var workStartTime: String?
    var workEndTime: String?
}

// MARK: - Cycle Start Option (上二休二)
enum CyclePosition: Int, CaseIterable, Identifiable {
    case fuzhongDay1 = 0
    case fuzhongDay2 = 1
    case kuguanDay1 = 4
    case kuguanDay2 = 5

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .fuzhongDay1: return "复重 第1天"
        case .fuzhongDay2: return "复重 第2天"
        case .kuguanDay1: return "库管 第1天"
        case .kuguanDay2: return "库管 第2天"
        }
    }
}

// MARK: - Cycle Start Option (上一休一)
enum SimplePosition: Int, CaseIterable, Identifiable {
    case workDay = 0
    case restDay = 1

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .workDay: return "上班"
        case .restDay: return "休息"
        }
    }
}

// MARK: - Merged Day Info
struct MergedDayInfo: Codable {
    var scheduleName: String
    var shiftType: ShiftType
    var colorTag: String
}
