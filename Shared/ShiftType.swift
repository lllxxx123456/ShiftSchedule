import Foundation
import SwiftUI

// MARK: - Shift Type
enum ShiftType: String, Codable, CaseIterable, Identifiable {
    case fuzhong = "复重"
    case kuguang = "库管"
    case rest = "休息"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .fuzhong: return Color(red: 79/255, green: 70/255, blue: 229/255)
        case .kuguang: return Color(red: 234/255, green: 138/255, blue: 56/255)
        case .rest: return Color(red: 16/255, green: 185/255, blue: 129/255)
        }
    }

    var lightColor: Color {
        switch self {
        case .fuzhong: return Color(red: 224/255, green: 231/255, blue: 255/255)
        case .kuguang: return Color(red: 254/255, green: 235/255, blue: 199/255)
        case .rest: return Color(red: 209/255, green: 250/255, blue: 229/255)
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .fuzhong: return [Color(red: 79/255, green: 70/255, blue: 229/255), Color(red: 99/255, green: 102/255, blue: 241/255)]
        case .kuguang: return [Color(red: 234/255, green: 138/255, blue: 56/255), Color(red: 251/255, green: 191/255, blue: 36/255)]
        case .rest: return [Color(red: 16/255, green: 185/255, blue: 129/255), Color(red: 52/255, green: 211/255, blue: 153/255)]
        }
    }

    var icon: String {
        switch self {
        case .fuzhong: return "scalemass.fill"
        case .kuguang: return "shippingbox.fill"
        case .rest: return "moon.stars.fill"
        }
    }

    var description: String {
        switch self {
        case .fuzhong: return "复重岗位"
        case .kuguang: return "库管岗位"
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

// MARK: - Schedule Pattern
struct SchedulePattern: Codable {
    var startDate: String
    var cycle: [ShiftType]
    var fuzhongStartTime: String
    var fuzhongEndTime: String
    var kuguanStartTime: String
    var kuguanEndTime: String
}

// MARK: - Cycle Start Option
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
