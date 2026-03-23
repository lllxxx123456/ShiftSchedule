import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()

    func requestPermission() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func scheduleShiftNotifications(shifts: [String: DayShift]) {
        center.removeAllPendingNotificationRequests()

        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "zh_CN")

        let today = calendar.startOfDay(for: Date())
        var scheduledCount = 0
        let maxNotifications = 60

        for dayOffset in 0..<730 {
            guard scheduledCount < maxNotifications else { break }
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            let key = dateFormatter.string(from: date)
            guard let shift = shifts[key], shift.shiftType != .rest else { continue }

            let isDay1 = isFirstWorkDay(key: key, shifts: shifts, dateFormatter: dateFormatter, calendar: calendar)

            if isDay1 {
                let content = UNMutableNotificationContent()
                content.title = "上班打卡提醒"
                content.body = "今天是\(shift.shiftType.rawValue)第1天，记得打开上班打卡！"
                content.sound = UNNotificationSound.default
                content.interruptionLevel = .timeSensitive

                var comps = calendar.dateComponents([.year, .month, .day], from: date)
                comps.hour = 8
                comps.minute = 5

                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                let request = UNNotificationRequest(identifier: "clockin_\(key)", content: content, trigger: trigger)
                center.add(request)
                scheduledCount += 1
            } else {
                let content = UNMutableNotificationContent()
                content.title = "下班打卡提醒"
                content.body = "今天是\(shift.shiftType.rawValue)第2天，记得下班打卡！"
                content.sound = UNNotificationSound.default
                content.interruptionLevel = .timeSensitive

                var comps = calendar.dateComponents([.year, .month, .day], from: date)
                comps.hour = 21
                comps.minute = 1

                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                let request = UNNotificationRequest(identifier: "clockout_\(key)", content: content, trigger: trigger)
                center.add(request)
                scheduledCount += 1
            }
        }
    }

    private func isFirstWorkDay(key: String, shifts: [String: DayShift], dateFormatter: DateFormatter, calendar: Calendar) -> Bool {
        guard let currentDate = dateFormatter.date(from: key),
              let shift = shifts[key] else { return true }

        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: currentDate) else { return true }
        let yesterdayKey = dateFormatter.string(from: yesterday)

        if let yesterdayShift = shifts[yesterdayKey],
           yesterdayShift.shiftType == shift.shiftType {
            return false
        }
        return true
    }
}
