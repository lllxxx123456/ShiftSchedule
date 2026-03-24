import SwiftUI

struct DayDetailView: View {
    @ObservedObject var viewModel: ScheduleViewModel
    let date: Date
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var shiftType: ShiftType = .rest
    @State private var startTime: Date = Calendar.current.date(from: DateComponents(hour: 8, minute: 30)) ?? Date()
    @State private var endTime: Date = Calendar.current.date(from: DateComponents(hour: 21, minute: 0)) ?? Date()
    @State private var location: String = ""
    @State private var notes: String = ""

    private let calendar = Calendar.current
    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    private var pageBg: Color {
        colorScheme == .dark ? Color(red: 0.11, green: 0.11, blue: 0.13) : Color(red: 0.96, green: 0.96, blue: 0.98)
    }
    private var cardBg: Color {
        colorScheme == .dark ? Color(red: 0.17, green: 0.17, blue: 0.19) : .white
    }

    private var isMergedSchedule: Bool {
        viewModel.activeSchedule?.isMerged == true
    }

    private var mergedInfos: [MergedDayInfo] {
        viewModel.getMergedInfos(for: viewModel.dateString(from: date))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    dateInfoCard
                    if isMergedSchedule {
                        mergedInfoSection
                    } else {
                        shiftTypeSelector
                        if shiftType != .rest {
                            timeSection
                            detailSection
                        }
                        actionButtons
                    }
                }
                .padding(20)
            }
            .background(pageBg)
            .navigationTitle("排班详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
            .onAppear { loadExistingShift() }
        }
    }

    private var mergedInfoSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "square.stack.3d.up.fill")
                    .foregroundColor(.purple)
                Text("汇总排班详情")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? .white : Color(white: 0.2))
            }

            Text("汇总排班仅展示来源排班，不支持在这里直接编辑。")
                .font(.system(size: 13))
                .foregroundColor(.secondary)

            if mergedInfos.isEmpty {
                Text("当日暂无来源排班数据")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(mergedInfos.enumerated()), id: \.offset) { _, info in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(colorForTag(info.colorTag))
                                .frame(width: 10, height: 10)

                            Text(info.scheduleName)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(colorScheme == .dark ? .white : .primary)

                            Spacer()

                            Text(info.shiftType.rawValue)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(colorForTag(info.colorTag))
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(cardBg))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    // MARK: - Date Info Card
    private var dateInfoCard: some View {
        let weekdayNames = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        let weekday = weekdayNames[calendar.component(.weekday, from: date) - 1]
        let dateStr = formatDate(date)
        let lunarStr = LunarCalendarHelper.lunarDateString(for: date)

        return HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 79/255, green: 70/255, blue: 229/255),
                                Color(red: 129/255, green: 100/255, blue: 255/255)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)

                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(dateStr)
                    .font(.system(size: 17, weight: .semibold))
                Text("\(weekday) · \(lunarStr)")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(cardBg))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    // MARK: - Shift Type Selector
    private var availableTypes: [ShiftType] {
        let setupType = viewModel.activeSchedule?.setupType ?? .twoOnTwoOff
        switch setupType {
        case .twoOnTwoOff: return [.fuzhong, .kuguang, .rest]
        case .oneOnOneOff: return [.work, .rest]
        }
    }

    private var shiftTypeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("岗位类型")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.secondary)

            HStack(spacing: 10) {
                ForEach(availableTypes) { type in
                    Button(action: { withAnimation(.spring(response: 0.3)) { shiftType = type } }) {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(shiftType == type
                                        ? LinearGradient(colors: type.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                                        : LinearGradient(colors: [type.lightColor], startPoint: .top, endPoint: .bottom))
                                    .frame(width: 52, height: 52)

                                Image(systemName: type.icon)
                                    .font(.system(size: 22))
                                    .foregroundColor(shiftType == type ? .white : type.color)
                            }

                            Text(type.rawValue)
                                .font(.system(size: 13, weight: shiftType == type ? .bold : .medium))
                                .foregroundColor(shiftType == type ? type.color : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(shiftType == type ? type.lightColor.opacity(0.5) : .clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(shiftType == type ? type.color.opacity(0.3) : .clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(cardBg))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    // MARK: - Time Section
    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("上班时间")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.secondary)

            HStack {
                DatePicker("上班", selection: $startTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                Text("至")
                    .foregroundColor(.secondary)
                DatePicker("下班", selection: $endTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(cardBg))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    // MARK: - Detail Section
    private var detailSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("其他信息")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.secondary)

            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.orange)
                    TextField("工作地点（选填）", text: $location)
                }

                Divider()

                HStack(alignment: .top) {
                    Image(systemName: "note.text")
                        .foregroundColor(.blue)
                        .padding(.top, 2)
                    TextField("备注（选填）", text: $notes, axis: .vertical)
                        .lineLimit(3)
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(cardBg))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button(action: saveShift) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("保存")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 79/255, green: 70/255, blue: 229/255),
                            Color(red: 129/255, green: 100/255, blue: 255/255)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            if viewModel.activeShifts[viewModel.dateString(from: date)] != nil {
                Button(action: {
                    viewModel.deleteShift(for: date)
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("删除排班")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.red.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.red.opacity(0.08))
                    )
                }
            }
        }
    }

    // MARK: - Helpers
    private func loadExistingShift() {
        guard !isMergedSchedule else { return }
        let key = viewModel.dateString(from: date)
        if let existing = viewModel.activeShifts[key] {
            shiftType = existing.shiftType
            if let st = existing.startTime, let parsed = parseTime(st) {
                startTime = parsed
            }
            if let et = existing.endTime, let parsed = parseTime(et) {
                endTime = parsed
            }
            location = existing.location ?? ""
            notes = existing.notes ?? ""
        }
    }

    private func saveShift() {
        let key = viewModel.dateString(from: date)
        let shift = DayShift(
            id: key,
            shiftType: shiftType,
            startTime: shiftType != .rest ? timeFormatter.string(from: startTime) : nil,
            endTime: shiftType != .rest ? timeFormatter.string(from: endTime) : nil,
            location: location.isEmpty ? nil : location,
            notes: notes.isEmpty ? nil : notes
        )
        viewModel.saveShift(shift)
        dismiss()
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy年M月d日"
        f.locale = Locale(identifier: "zh_CN")
        return f.string(from: date)
    }

    private func parseTime(_ timeStr: String) -> Date? {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.date(from: timeStr)
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
