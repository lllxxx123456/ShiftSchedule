import SwiftUI

struct QuickSetupView: View {
    @ObservedObject var viewModel: ScheduleViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var startDate = Date()
    @State private var cyclePosition: CyclePosition = .fuzhongDay1
    @State private var simplePosition: SimplePosition = .workDay
    @State private var fuzhongStart = Calendar.current.date(from: DateComponents(hour: 8, minute: 30)) ?? Date()
    @State private var fuzhongEnd = Calendar.current.date(from: DateComponents(hour: 21, minute: 0)) ?? Date()
    @State private var kuguanStart = Calendar.current.date(from: DateComponents(hour: 8, minute: 30)) ?? Date()
    @State private var kuguanEnd = Calendar.current.date(from: DateComponents(hour: 21, minute: 0)) ?? Date()
    @State private var workStart = Calendar.current.date(from: DateComponents(hour: 8, minute: 30)) ?? Date()
    @State private var workEnd = Calendar.current.date(from: DateComponents(hour: 21, minute: 0)) ?? Date()
    @State private var showConfirm = false

    private var setupType: QuickSetupType {
        viewModel.activeSchedule?.setupType ?? .twoOnTwoOff
    }

    private var isMergedSchedule: Bool {
        viewModel.activeSchedule?.isMerged == true
    }

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if isMergedSchedule {
                        mergedUnsupportedCard
                    } else {
                        instructionCard
                        datePickerCard

                        if setupType == .twoOnTwoOff {
                            positionCardTwoOnTwo
                            fuzhongTimeCard
                            kuguanTimeCard
                        } else {
                            positionCardOneOnOne
                            workTimeCard
                        }

                        previewCard
                        generateButton
                    }
                }
                .padding(20)
            }
            .background(colorScheme == .dark ? Color(red: 0.11, green: 0.11, blue: 0.13) : Color(red: 0.96, green: 0.96, blue: 0.98))
            .navigationTitle("快捷排班 - \(setupType.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .alert("确认生成排班", isPresented: $showConfirm) {
                Button("取消", role: .cancel) {}
                Button("确认生成", role: .destructive) {
                    generateAndDismiss()
                }
            } message: {
                Text("将根据设置前后各2年自动生成排班数据，已有的排班数据将被覆盖。")
            }
        }
    }

    private var mergedUnsupportedCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("汇总排班不支持快捷排班")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? .white : Color(white: 0.2))
            }

            Text("当前选择的是合并后的汇总排班表。请先回到首页切换到普通排班表，再进行快捷排班生成。")
                .font(.system(size: 14))
                .foregroundColor(colorScheme == .dark ? Color(white: 0.65) : Color(white: 0.4))
                .lineSpacing(4)

            Button("关闭") { dismiss() }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.orange)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 16).fill(colorScheme == .dark ? Color(red: 0.17, green: 0.17, blue: 0.19) : .white))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    // MARK: - Instruction Card
    private var instructionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text("使用说明")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? .white : Color(white: 0.2))
            }

            if setupType == .twoOnTwoOff {
                Text("选择一个你确定的日期，并指定该日是复重还是库管的第几天。系统将按照「复重→复重→休息→休息→库管→库管→休息→休息」的规律自动排列。")
                    .font(.system(size: 14))
                    .foregroundColor(colorScheme == .dark ? Color(white: 0.65) : Color(white: 0.4))
                    .lineSpacing(4)
            } else {
                Text("选择一个你确定的日期，指定该日是上班还是休息。系统将按照「上班→休息」的规律自动排列。")
                    .font(.system(size: 14))
                    .foregroundColor(colorScheme == .dark ? Color(white: 0.65) : Color(white: 0.4))
                    .lineSpacing(4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.opacity(0.06))
        )
    }

    // MARK: - Date Picker
    private var datePickerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("选择已知日期", systemImage: "calendar.badge.clock")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(colorScheme == .dark ? Color(white: 0.7) : Color(white: 0.3))

            DatePicker("日期", selection: $startDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .environment(\.locale, Locale(identifier: "zh_CN"))
                .tint(Color(red: 79/255, green: 70/255, blue: 229/255))

            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color(red: 79/255, green: 70/255, blue: 229/255))
                    .font(.system(size: 16))
                Text("已选择：\(selectedDateString)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(red: 79/255, green: 70/255, blue: 229/255))
                Spacer()
                Text(selectedPositionLabel)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(selectedPositionColor)
                    .clipShape(Capsule())
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(red: 79/255, green: 70/255, blue: 229/255).opacity(0.1))
            )
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(colorScheme == .dark ? Color(red: 0.17, green: 0.17, blue: 0.19) : .white))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    // MARK: - Position Card (上二休二)
    private var positionCardTwoOnTwo: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("该日是什么班", systemImage: "person.badge.clock")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(colorScheme == .dark ? Color(white: 0.7) : Color(white: 0.3))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(CyclePosition.allCases) { pos in
                    Button(action: { withAnimation { cyclePosition = pos } }) {
                        HStack(spacing: 6) {
                            Image(systemName: posIcon(pos))
                                .font(.system(size: 14))
                            Text(pos.displayName)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(cyclePosition == pos ? .white : posColor(pos))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(cyclePosition == pos
                                    ? LinearGradient(colors: posGradient(pos), startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient(colors: [posLightColor(pos)], startPoint: .leading, endPoint: .trailing))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(colorScheme == .dark ? Color(red: 0.17, green: 0.17, blue: 0.19) : .white))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    // MARK: - Position Card (上一休一)
    private var positionCardOneOnOne: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("该日是什么班", systemImage: "person.badge.clock")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(colorScheme == .dark ? Color(white: 0.7) : Color(white: 0.3))

            HStack(spacing: 12) {
                ForEach(SimplePosition.allCases) { pos in
                    Button(action: { withAnimation { simplePosition = pos } }) {
                        HStack(spacing: 6) {
                            Image(systemName: pos == .workDay ? "briefcase.fill" : "moon.stars.fill")
                                .font(.system(size: 14))
                            Text(pos.displayName)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(simplePosition == pos ? .white : (pos == .workDay ? ShiftType.work.color : ShiftType.rest.color))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(simplePosition == pos
                                    ? LinearGradient(colors: pos == .workDay ? ShiftType.work.gradientColors : ShiftType.rest.gradientColors, startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient(colors: [pos == .workDay ? ShiftType.work.lightColor : ShiftType.rest.lightColor], startPoint: .leading, endPoint: .trailing))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(colorScheme == .dark ? Color(red: 0.17, green: 0.17, blue: 0.19) : .white))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    // MARK: - Fuzhong Time Card
    private var fuzhongTimeCard: some View {
        timeCard(title: "复重岗位时间", color: ShiftType.fuzhong.color,
                 startTime: $fuzhongStart, endTime: $fuzhongEnd)
    }

    // MARK: - Kuguan Time Card
    private var kuguanTimeCard: some View {
        timeCard(title: "库管岗位时间", color: ShiftType.kuguang.color,
                 startTime: $kuguanStart, endTime: $kuguanEnd)
    }

    // MARK: - Work Time Card (上一休一)
    private var workTimeCard: some View {
        timeCard(title: "上班时间", color: ShiftType.work.color,
                 startTime: $workStart, endTime: $workEnd)
    }

    private func timeCard(title: String, color: Color, startTime: Binding<Date>, endTime: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Circle().fill(color).frame(width: 10, height: 10)
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? Color(white: 0.7) : Color(white: 0.3))
            }
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("上班")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? Color(white: 0.6) : Color(white: 0.4))
                    DatePicker("", selection: startTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
                Spacer()
                Image(systemName: "arrow.right")
                    .foregroundColor(colorScheme == .dark ? Color(white: 0.6) : Color(white: 0.4))
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("下班")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? Color(white: 0.6) : Color(white: 0.4))
                    DatePicker("", selection: endTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(colorScheme == .dark ? Color(red: 0.17, green: 0.17, blue: 0.19) : .white))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    // MARK: - Preview Card
    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("排班预览（前16天）", systemImage: "eye")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(colorScheme == .dark ? Color(white: 0.7) : Color(white: 0.3))

            let preview = generatePreview()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 8), spacing: 4) {
                ForEach(Array(preview.enumerated()), id: \.offset) { _, type in
                    VStack(spacing: 2) {
                        Circle()
                            .fill(type.color)
                            .frame(width: 8, height: 8)
                        Text(type.rawValue)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(type.color)
                    }
                    .frame(height: 32)
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(colorScheme == .dark ? Color(red: 0.17, green: 0.17, blue: 0.19) : .white))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    // MARK: - Generate Button
    private var generateButton: some View {
        Button(action: { showConfirm = true }) {
            HStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                Text("生成排班")
                    .font(.system(size: 17, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color(red: 79/255, green: 70/255, blue: 229/255), Color(red: 129/255, green: 100/255, blue: 255/255)],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color(red: 79/255, green: 70/255, blue: 229/255).opacity(0.4), radius: 12, x: 0, y: 4)
        }
    }

    // MARK: - Selected Date Display
    private var selectedDateString: String {
        let f = DateFormatter()
        f.dateFormat = "M月d日 EEEE"
        f.locale = Locale(identifier: "zh_CN")
        return f.string(from: startDate)
    }

    private var selectedPositionLabel: String {
        if setupType == .twoOnTwoOff {
            return cyclePosition.displayName
        } else {
            return simplePosition.displayName
        }
    }

    private var selectedPositionColor: Color {
        if setupType == .twoOnTwoOff {
            switch cyclePosition {
            case .fuzhongDay1, .fuzhongDay2: return ShiftType.fuzhong.color
            case .kuguanDay1, .kuguanDay2: return ShiftType.kuguang.color
            }
        }
        return simplePosition == .workDay ? ShiftType.work.color : ShiftType.rest.color
    }

    // MARK: - Helpers
    private func generatePreview() -> [ShiftType] {
        if setupType == .twoOnTwoOff {
            let fullCycle: [ShiftType] = [.fuzhong, .fuzhong, .rest, .rest, .kuguang, .kuguang, .rest, .rest]
            let offset = cyclePosition.rawValue
            return (0..<16).map { fullCycle[($0 + offset) % fullCycle.count] }
        } else {
            let fullCycle: [ShiftType] = [.work, .rest]
            let offset = simplePosition.rawValue
            return (0..<16).map { fullCycle[($0 + offset) % fullCycle.count] }
        }
    }

    private func generateAndDismiss() {
        guard let scheduleId = viewModel.activeScheduleId else { return }
        guard !isMergedSchedule else { return }

        if setupType == .twoOnTwoOff {
            viewModel.generateTwoOnTwoOff(
                scheduleId: scheduleId,
                startDate: startDate,
                cyclePosition: cyclePosition,
                fuzhongStart: timeFormatter.string(from: fuzhongStart),
                fuzhongEnd: timeFormatter.string(from: fuzhongEnd),
                kuguanStart: timeFormatter.string(from: kuguanStart),
                kuguanEnd: timeFormatter.string(from: kuguanEnd)
            )
        } else {
            viewModel.generateOneOnOneOff(
                scheduleId: scheduleId,
                startDate: startDate,
                simplePosition: simplePosition,
                workStart: timeFormatter.string(from: workStart),
                workEnd: timeFormatter.string(from: workEnd)
            )
        }
        dismiss()
    }

    private func posIcon(_ pos: CyclePosition) -> String {
        switch pos {
        case .fuzhongDay1, .fuzhongDay2: return "scalemass.fill"
        case .kuguanDay1, .kuguanDay2: return "shippingbox.fill"
        }
    }

    private func posColor(_ pos: CyclePosition) -> Color {
        switch pos {
        case .fuzhongDay1, .fuzhongDay2: return ShiftType.fuzhong.color
        case .kuguanDay1, .kuguanDay2: return ShiftType.kuguang.color
        }
    }

    private func posGradient(_ pos: CyclePosition) -> [Color] {
        switch pos {
        case .fuzhongDay1, .fuzhongDay2: return ShiftType.fuzhong.gradientColors
        case .kuguanDay1, .kuguanDay2: return ShiftType.kuguang.gradientColors
        }
    }

    private func posLightColor(_ pos: CyclePosition) -> Color {
        switch pos {
        case .fuzhongDay1, .fuzhongDay2: return ShiftType.fuzhong.lightColor
        case .kuguanDay1, .kuguanDay2: return ShiftType.kuguang.lightColor
        }
    }
}
