import SwiftUI

struct DayCellView: View {
    let date: Date
    let shift: DayShift?
    let isToday: Bool
    let isWeekend: Bool
    var mergedInfos: [MergedDayInfo] = []
    var cellHeight: CGFloat = 68
    @Environment(\.colorScheme) private var colorScheme

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 1) {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 15, weight: isToday ? .heavy : .semibold, design: .rounded))
                .foregroundColor(isToday ? .white : dayNumberColor)

            Text(lunarText)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(isToday ? .white.opacity(0.85) : festivalColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if !mergedInfos.isEmpty {
                VStack(spacing: 1) {
                    ForEach(Array(mergedInfos.enumerated()), id: \.offset) { _, info in
                        HStack(spacing: 2) {
                            Circle()
                                .fill(colorForTag(info.colorTag))
                                .frame(width: 4, height: 4)
                            Text("\(info.scheduleName):\(info.shiftType.rawValue)")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundColor(isToday ? .white : colorForTag(info.colorTag))
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        }
                    }
                }
            } else if let shift = shift {
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
        .frame(height: cellHeight)
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
            return shift.shiftType.lightColor.opacity(colorScheme == .dark ? 0.25 : 0.4)
        }
        return .clear
    }

    private var dayNumberColor: Color {
        if isWeekend {
            return .red.opacity(0.65)
        }
        return colorScheme == .dark ? .white : Color(red: 0.15, green: 0.15, blue: 0.2)
    }

    private var lunarText: String {
        LunarCalendarHelper.lunarDateString(for: date)
    }

    private var festivalColor: Color {
        if LunarCalendarHelper.chineseFestival(for: date) != nil ||
           LunarCalendarHelper.solarFestival(for: date) != nil {
            return Color(red: 234/255, green: 88/255, blue: 12/255)
        }
        return colorScheme == .dark ? .gray.opacity(0.8) : .gray.opacity(0.7)
    }

    private func colorForTag(_ tag: String) -> Color {
        switch tag {
        case "indigo": return Color(red: 79/255, green: 70/255, blue: 229/255)
        case "blue": return Color(red: 59/255, green: 130/255, blue: 246/255)
        case "orange": return Color(red: 234/255, green: 138/255, blue: 56/255)
        case "green": return Color(red: 16/255, green: 185/255, blue: 129/255)
        case "pink": return Color(red: 236/255, green: 72/255, blue: 153/255)
        case "purple": return Color(red: 147/255, green: 51/255, blue: 234/255)
        default: return .indigo
        }
    }
}
