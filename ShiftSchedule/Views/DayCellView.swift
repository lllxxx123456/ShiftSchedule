import SwiftUI

struct DayCellView: View {
    let date: Date
    let shift: DayShift?
    let isToday: Bool
    let isWeekend: Bool

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 2) {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 16, weight: isToday ? .heavy : .semibold, design: .rounded))
                .foregroundColor(isToday ? .white : dayNumberColor)

            Text(lunarText)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(isToday ? .white.opacity(0.85) : festivalColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if let shift = shift {
                Text(shift.shiftType.rawValue)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(isToday ? shift.shiftType.color : .white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(isToday ? .white : shift.shiftType.color)
                    )
            } else {
                Spacer()
                    .frame(height: 16)
            }
        }
        .frame(height: 68)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(isToday ? .clear : (shift != nil ? shift!.shiftType.color.opacity(0.15) : .clear), lineWidth: 1)
        )
    }

    private var backgroundColor: Color {
        if isToday {
            if let shift = shift {
                return shift.shiftType.color
            }
            return Color(red: 79/255, green: 70/255, blue: 229/255)
        }
        if let shift = shift {
            return shift.shiftType.lightColor.opacity(0.4)
        }
        return .clear
    }

    private var dayNumberColor: Color {
        if isWeekend {
            return .red.opacity(0.65)
        }
        return .primary
    }

    private var lunarText: String {
        LunarCalendarHelper.lunarDateString(for: date)
    }

    private var festivalColor: Color {
        if LunarCalendarHelper.chineseFestival(for: date) != nil ||
           LunarCalendarHelper.solarFestival(for: date) != nil {
            return Color(red: 234/255, green: 88/255, blue: 12/255)
        }
        return .gray.opacity(0.7)
    }
}
