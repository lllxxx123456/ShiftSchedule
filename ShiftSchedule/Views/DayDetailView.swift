import SwiftUI

struct DayDetailView: View {
    @ObservedObject var viewModel: ScheduleViewModel
    let date: Date
    @Environment(\.dismiss) var dismiss

    @State private var shiftType: ShiftType = .rest
    @State private var startTime: Date = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
    @State private var endTime: Date = Calendar.current.date(from: DateComponents(hour: 20, minute: 0)) ?? Date()
    @State private var location: String = ""
    @State private var notes: String = ""

    private let calendar = Calendar.current
    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    dateInfoCard
                    shiftTypeSelector
                    if shiftType != .rest {
                        timeSection
                        detailSection
                    }
                    actionButtons
                }
                .padding(20)
            }
            .background(Color(red: 0.96, green: 0.96, blue: 0.98))
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
        .background(RoundedRectangle(cornerRadius: 16).fill(.white))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    // MARK: - Shift Type Selector
    private var shiftTypeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("岗位类型")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.secondary)

            HStack(spacing: 10) {
                ForEach(ShiftType.allCases) { type in
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
        .background(RoundedRectangle(cornerRadius: 16).fill(.white))
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
        .background(RoundedRectangle(cornerRadius: 16).fill(.white))
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
        .background(RoundedRectangle(cornerRadius: 16).fill(.white))
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

            if viewModel.shifts[viewModel.dateString(from: date)] != nil {
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
        let key = viewModel.dateString(from: date)
        if let existing = viewModel.shifts[key] {
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
}
