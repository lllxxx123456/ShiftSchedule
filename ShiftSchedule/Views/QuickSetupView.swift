import SwiftUI

struct QuickSetupView: View {
    @ObservedObject var viewModel: ScheduleViewModel
    @Environment(\.dismiss) var dismiss

    @State private var startDate = Date()
    @State private var cyclePosition: CyclePosition = .fuzhongDay1
    @State private var fuzhongStart = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
    @State private var fuzhongEnd = Calendar.current.date(from: DateComponents(hour: 20, minute: 0)) ?? Date()
    @State private var kuguanStart = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
    @State private var kuguanEnd = Calendar.current.date(from: DateComponents(hour: 20, minute: 0)) ?? Date()
    @State private var showConfirm = false

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    instructionCard
                    datePickerCard
                    positionCard
                    fuzhongTimeCard
                    kuguanTimeCard
                    previewCard
                    generateButton
                }
                .padding(20)
            }
            .background(Color(red: 0.96, green: 0.96, blue: 0.98))
            .navigationTitle("快捷排班")
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
                Text("将从选定日期起生成2年的排班数据，已有的排班数据将被覆盖。")
            }
        }
    }

    // MARK: - Instruction Card
    private var instructionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text("使用说明")
                    .font(.system(size: 15, weight: .semibold))
            }

            Text("选择一个你确定的日期，并指定该日是复重还是库管的第几天。系统将按照「复重→复重→休息→休息→库管→库管→休息→休息」的规律自动排列全年班次。")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .lineSpacing(4)
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
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.secondary)

            DatePicker("日期", selection: $startDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .environment(\.locale, Locale(identifier: "zh_CN"))
                .tint(Color(red: 79/255, green: 70/255, blue: 229/255))
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(.white))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    // MARK: - Position Card
    private var positionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("该日是什么班", systemImage: "person.badge.clock")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.secondary)

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
        .background(RoundedRectangle(cornerRadius: 16).fill(.white))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    // MARK: - Fuzhong Time Card
    private var fuzhongTimeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Circle()
                    .fill(ShiftType.fuzhong.color)
                    .frame(width: 10, height: 10)
                Text("复重岗位时间")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.secondary)
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("上班")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    DatePicker("", selection: $fuzhongStart, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
                Spacer()
                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("下班")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    DatePicker("", selection: $fuzhongEnd, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(.white))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    // MARK: - Kuguan Time Card
    private var kuguanTimeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Circle()
                    .fill(ShiftType.kuguang.color)
                    .frame(width: 10, height: 10)
                Text("库管岗位时间")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.secondary)
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("上班")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    DatePicker("", selection: $kuguanStart, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
                Spacer()
                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("下班")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    DatePicker("", selection: $kuguanEnd, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(.white))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    // MARK: - Preview Card
    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("排班预览（前16天）", systemImage: "eye")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.secondary)

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
        .background(RoundedRectangle(cornerRadius: 16).fill(.white))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    // MARK: - Generate Button
    private var generateButton: some View {
        Button(action: { showConfirm = true }) {
            HStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                Text("生成全年排班")
                    .font(.system(size: 17, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
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
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color(red: 79/255, green: 70/255, blue: 229/255).opacity(0.4), radius: 12, x: 0, y: 4)
        }
    }

    // MARK: - Helpers
    private func generatePreview() -> [ShiftType] {
        let fullCycle: [ShiftType] = [.fuzhong, .fuzhong, .rest, .rest, .kuguang, .kuguang, .rest, .rest]
        let offset = cyclePosition.rawValue
        return (0..<16).map { i in
            fullCycle[(i + offset) % fullCycle.count]
        }
    }

    private func generateAndDismiss() {
        let fStart = timeFormatter.string(from: fuzhongStart)
        let fEnd = timeFormatter.string(from: fuzhongEnd)
        let kStart = timeFormatter.string(from: kuguanStart)
        let kEnd = timeFormatter.string(from: kuguanEnd)

        viewModel.generatePattern(
            startDate: startDate,
            cyclePosition: cyclePosition,
            fuzhongStart: fStart,
            fuzhongEnd: fEnd,
            kuguanStart: kStart,
            kuguanEnd: kEnd
        )
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
