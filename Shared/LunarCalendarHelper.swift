import Foundation

struct LunarCalendarHelper {
    private static let chineseCalendar: Calendar = {
        var cal = Calendar(identifier: .chinese)
        cal.locale = Locale(identifier: "zh_CN")
        return cal
    }()

    private static let lunarMonths = ["正", "二", "三", "四", "五", "六", "七", "八", "九", "十", "冬", "腊"]

    private static let lunarDays = [
        "初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
        "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
        "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"
    ]

    static func lunarDay(for date: Date) -> String {
        let day = chineseCalendar.component(.day, from: date)
        guard day >= 1, day <= lunarDays.count else { return "" }
        return lunarDays[day - 1]
    }

    static func lunarMonth(for date: Date) -> String {
        let month = chineseCalendar.component(.month, from: date)
        guard month >= 1, month <= lunarMonths.count else { return "" }
        return lunarMonths[month - 1] + "月"
    }

    static func lunarDateString(for date: Date) -> String {
        let festival = chineseFestival(for: date) ?? solarFestival(for: date)
        if let festival = festival {
            return festival
        }
        let day = chineseCalendar.component(.day, from: date)
        if day == 1 {
            return lunarMonth(for: date)
        }
        return lunarDay(for: date)
    }

    static func chineseFestival(for date: Date) -> String? {
        let month = chineseCalendar.component(.month, from: date)
        let day = chineseCalendar.component(.day, from: date)

        switch (month, day) {
        case (1, 1): return "春节"
        case (1, 15): return "元宵"
        case (5, 5): return "端午"
        case (7, 7): return "七夕"
        case (7, 15): return "中元"
        case (8, 15): return "中秋"
        case (9, 9): return "重阳"
        case (12, 8): return "腊八"
        case (12, 30): return "除夕"
        default: return nil
        }
    }

    static func solarFestival(for date: Date) -> String? {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)

        switch (month, day) {
        case (1, 1): return "元旦"
        case (2, 14): return "情人节"
        case (3, 8): return "妇女节"
        case (3, 12): return "植树节"
        case (4, 5): return "清明"
        case (5, 1): return "劳动节"
        case (5, 4): return "青年节"
        case (6, 1): return "儿童节"
        case (10, 1): return "国庆节"
        case (12, 25): return "圣诞节"
        default: return nil
        }
    }
}
