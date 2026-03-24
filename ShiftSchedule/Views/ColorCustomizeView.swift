import SwiftUI

// MARK: - 排班表级别颜色设置（每种班次类型）
struct ColorCustomizeView: View {
    @ObservedObject var viewModel: ScheduleViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var editingType: ShiftType?
    @State private var textColorHex: String = ""
    @State private var shiftColorHex: String = ""
    @State private var bgColorHex: String = ""

    private var pageBg: Color {
        colorScheme == .dark ? Color(red: 0.11, green: 0.11, blue: 0.13) : Color(red: 0.96, green: 0.96, blue: 0.98)
    }
    private var cardBg: Color {
        colorScheme == .dark ? Color(red: 0.17, green: 0.17, blue: 0.19) : .white
    }

    private var availableTypes: [ShiftType] {
        let setupType = viewModel.activeSchedule?.setupType ?? .twoOnTwoOff
        switch setupType {
        case .twoOnTwoOff: return [.fuzhong, .kuguang, .rest]
        case .oneOnOneOff: return [.work, .rest]
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    instructionCard

                    ForEach(availableTypes) { type in
                        shiftTypeColorCard(type)
                    }

                    resetButton
                }
                .padding(20)
            }
            .background(pageBg)
            .navigationTitle("自定义颜色")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
            .sheet(item: $editingType) { type in
                ColorEditorSheet(
                    shiftType: type,
                    textColorHex: textColorHex,
                    shiftColorHex: shiftColorHex,
                    bgColorHex: bgColorHex,
                    onSave: { text, shift, bg in
                        saveColors(for: type, text: text, shift: shift, bg: bg)
                    }
                )
            }
        }
    }

    private var instructionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "paintpalette.fill")
                    .foregroundColor(Color(red: 79/255, green: 70/255, blue: 229/255))
                Text("颜色自定义说明")
                    .font(.system(size: 16, weight: .bold))
            }
            Text("为每种班次类型设置自定义颜色。设置后会影响日历中所有该类型班次的显示。您也可以在单日详情中为特定某天单独设置颜色。")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(cardBg))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private func shiftTypeColorCard(_ type: ShiftType) -> some View {
        let config = viewModel.activeSchedule?.shiftTypeColors[type.rawValue] ?? .empty
        let effectiveShiftColor = config.shiftColor ?? type.color
        let effectiveBgColor = config.bgColor ?? type.lightColor
        let effectiveTextColor = config.textColor

        return VStack(spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: type.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 40, height: 40)
                    Image(systemName: type.icon)
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(type.rawValue)
                        .font(.system(size: 17, weight: .bold))
                    Text(type.description)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: {
                    textColorHex = config.textColorHex ?? ""
                    shiftColorHex = config.shiftColorHex ?? ""
                    bgColorHex = config.bgColorHex ?? ""
                    editingType = type
                }) {
                    Text("编辑")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color(red: 79/255, green: 70/255, blue: 229/255))
                        .clipShape(Capsule())
                }
            }

            // 预览
            HStack(spacing: 8) {
                previewItem(label: "字体", color: effectiveTextColor ?? (colorScheme == .dark ? .white : Color(red: 0.15, green: 0.15, blue: 0.2)), isSet: config.textColorHex != nil)
                previewItem(label: "标签", color: effectiveShiftColor, isSet: config.shiftColorHex != nil)
                previewItem(label: "背景", color: effectiveBgColor, isSet: config.bgColorHex != nil)

                Spacer()

                // 迷你预览格子
                miniPreviewCell(type: type, config: config)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(cardBg))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private func previewItem(label: String, color: Color, isSet: Bool) -> some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 6)
                .fill(color)
                .frame(width: 32, height: 32)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                )
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(isSet ? .primary : .secondary)
            if isSet {
                Circle()
                    .fill(Color.green)
                    .frame(width: 5, height: 5)
            }
        }
    }

    private func miniPreviewCell(type: ShiftType, config: ShiftColorConfig) -> some View {
        let shiftColor = config.shiftColor ?? type.color
        let bgColor = config.bgColor ?? type.lightColor
        let textColor = config.textColor ?? (colorScheme == .dark ? .white : Color(red: 0.15, green: 0.15, blue: 0.2))

        return VStack(spacing: 2) {
            Text("15")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(textColor)
            Text(type.rawValue)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .background(Capsule().fill(shiftColor))
        }
        .frame(width: 48, height: 52)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(bgColor.opacity(colorScheme == .dark ? 0.35 : 0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(shiftColor.opacity(0.15), lineWidth: 1)
        )
    }

    private var resetButton: some View {
        Button(action: resetAllColors) {
            HStack {
                Image(systemName: "arrow.counterclockwise")
                Text("恢复默认颜色")
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

    private func saveColors(for type: ShiftType, text: String, shift: String, bg: String) {
        guard let idx = viewModel.schedules.firstIndex(where: { $0.id == viewModel.activeScheduleId }) else { return }
        var config = ShiftColorConfig()
        config.textColorHex = text.isEmpty ? nil : text
        config.shiftColorHex = shift.isEmpty ? nil : shift
        config.bgColorHex = bg.isEmpty ? nil : bg
        if config.textColorHex == nil && config.shiftColorHex == nil && config.bgColorHex == nil {
            viewModel.schedules[idx].shiftTypeColors.removeValue(forKey: type.rawValue)
        } else {
            viewModel.schedules[idx].shiftTypeColors[type.rawValue] = config
        }
        viewModel.saveAllSchedules()
    }

    private func resetAllColors() {
        guard let idx = viewModel.schedules.firstIndex(where: { $0.id == viewModel.activeScheduleId }) else { return }
        viewModel.schedules[idx].shiftTypeColors = [:]
        viewModel.saveAllSchedules()
    }
}

// MARK: - 颜色编辑弹窗
struct ColorEditorSheet: View {
    let shiftType: ShiftType
    @State var textColorHex: String
    @State var shiftColorHex: String
    @State var bgColorHex: String
    let onSave: (String, String, String) -> Void
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private let presetColors: [String] = [
        "#DC2626", "#EF4444", "#F97316", "#F59E0B", "#EAB308",
        "#22C55E", "#16A34A", "#10B981", "#14B8A6", "#06B6D4",
        "#3B82F6", "#2563EB", "#4F46E5", "#6366F1", "#8B5CF6",
        "#A855F7", "#D946EF", "#EC4899", "#F43F5E", "#6B7280",
        "#1F2937", "#FFFFFF", "#F3F4F6", "#FEE2E2", "#DCFCE7",
        "#DBEAFE", "#E0E7FF", "#FEF3C7", "#FCE7F3", "#F5F3FF"
    ]

    private var cardBg: Color {
        colorScheme == .dark ? Color(red: 0.17, green: 0.17, blue: 0.19) : .white
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 预览
                    previewSection

                    // 字体颜色
                    colorSection(title: "字体颜色", subtitle: "日期数字的颜色", hex: $textColorHex, defaultColor: shiftType.color)

                    // 班次显示颜色
                    colorSection(title: "班次标签颜色", subtitle: "上班/休息标签的颜色", hex: $shiftColorHex, defaultColor: shiftType.color)

                    // 背景颜色
                    colorSection(title: "日历背景颜色", subtitle: "日历格子的背景颜色", hex: $bgColorHex, defaultColor: shiftType.lightColor)
                }
                .padding(20)
            }
            .background(colorScheme == .dark ? Color(red: 0.11, green: 0.11, blue: 0.13) : Color(red: 0.96, green: 0.96, blue: 0.98))
            .navigationTitle("编辑 \(shiftType.rawValue) 颜色")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(textColorHex, shiftColorHex, bgColorHex)
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }

    private var previewSection: some View {
        VStack(spacing: 8) {
            Text("预览效果")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)

            let shiftColor = shiftColorHex.isEmpty ? shiftType.color : Color(hex: shiftColorHex)
            let bgColor = bgColorHex.isEmpty ? shiftType.lightColor : Color(hex: bgColorHex)
            let textColor = textColorHex.isEmpty ? (colorScheme == .dark ? Color.white : Color(red: 0.15, green: 0.15, blue: 0.2)) : Color(hex: textColorHex)

            HStack(spacing: 12) {
                // 普通日预览
                VStack(spacing: 2) {
                    Text("普通日")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    VStack(spacing: 1) {
                        Text("15")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(textColor)
                        Text("初五")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.gray.opacity(0.7))
                        Text(shiftType.rawValue)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(shiftColor))
                    }
                    .frame(width: 52, height: 68)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(bgColor.opacity(colorScheme == .dark ? 0.35 : 0.5))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(shiftColor.opacity(0.15), lineWidth: 1)
                    )
                }

                // 今日预览
                VStack(spacing: 2) {
                    Text("今日")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    VStack(spacing: 1) {
                        Text("15")
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                        Text("初五")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                        Text(shiftType.rawValue)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(shiftColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(.white))
                    }
                    .frame(width: 52, height: 68)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(bgColorHex.isEmpty ? shiftColor : Color(hex: bgColorHex))
                    )
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(cardBg))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private func colorSection(title: String, subtitle: String, hex: Binding<String>, defaultColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
                if !hex.wrappedValue.isEmpty {
                    Button(action: { hex.wrappedValue = "" }) {
                        Text("恢复默认")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.red)
                    }
                }
            }

            // 当前颜色显示
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(hex.wrappedValue.isEmpty ? defaultColor : Color(hex: hex.wrappedValue))
                    .frame(width: 40, height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                    )

                TextField("#RRGGBB", text: hex)
                    .font(.system(size: 14, design: .monospaced))
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.allCharacters)
                    .disableAutocorrection(true)
            }

            // 预设颜色
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 10), spacing: 6) {
                ForEach(presetColors, id: \.self) { color in
                    Circle()
                        .fill(Color(hex: color))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .strokeBorder(hex.wrappedValue == color ? Color.primary : Color.gray.opacity(0.2), lineWidth: hex.wrappedValue == color ? 2.5 : 1)
                        )
                        .onTapGesture {
                            hex.wrappedValue = color
                        }
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(cardBg))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

// MARK: - 单日颜色编辑视图
struct DayColorEditorView: View {
    @ObservedObject var viewModel: ScheduleViewModel
    let date: Date
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var textColorHex: String = ""
    @State private var shiftColorHex: String = ""
    @State private var bgColorHex: String = ""

    private var dateKey: String {
        viewModel.dateString(from: date)
    }

    private var currentShift: DayShift? {
        viewModel.activeShifts[dateKey]
    }

    private let presetColors: [String] = [
        "#DC2626", "#EF4444", "#F97316", "#F59E0B", "#EAB308",
        "#22C55E", "#16A34A", "#10B981", "#14B8A6", "#06B6D4",
        "#3B82F6", "#2563EB", "#4F46E5", "#6366F1", "#8B5CF6",
        "#A855F7", "#D946EF", "#EC4899", "#F43F5E", "#6B7280",
        "#1F2937", "#FFFFFF", "#F3F4F6", "#FEE2E2", "#DCFCE7",
        "#DBEAFE", "#E0E7FF", "#FEF3C7", "#FCE7F3", "#F5F3FF"
    ]

    private var cardBg: Color {
        colorScheme == .dark ? Color(red: 0.17, green: 0.17, blue: 0.19) : .white
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let shift = currentShift {
                        Text("为 \(formatDate(date)) 的「\(shift.shiftType.rawValue)」设置颜色")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)

                        colorSection(title: "字体颜色", hex: $textColorHex, defaultColor: shift.shiftType.color)
                        colorSection(title: "标签颜色", hex: $shiftColorHex, defaultColor: shift.shiftType.color)
                        colorSection(title: "背景颜色", hex: $bgColorHex, defaultColor: shift.shiftType.lightColor)

                        HStack(spacing: 10) {
                            Button(action: {
                                textColorHex = ""
                                shiftColorHex = ""
                                bgColorHex = ""
                            }) {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                    Text("恢复默认")
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.orange)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color.orange.opacity(0.08)))
                            }

                            Button(action: saveDayColors) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("保存")
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        colors: [Color(red: 79/255, green: 70/255, blue: 229/255), Color(red: 129/255, green: 100/255, blue: 255/255)],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    } else {
                        Text("该日暂无排班，请先设置排班后再自定义颜色。")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .padding(20)
                    }
                }
                .padding(20)
            }
            .background(colorScheme == .dark ? Color(red: 0.11, green: 0.11, blue: 0.13) : Color(red: 0.96, green: 0.96, blue: 0.98))
            .navigationTitle("单日颜色设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
            .onAppear { loadExistingColors() }
        }
    }

    private func colorSection(title: String, hex: Binding<String>, defaultColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                if !hex.wrappedValue.isEmpty {
                    Button("清除") { hex.wrappedValue = "" }
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                }
            }

            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(hex.wrappedValue.isEmpty ? defaultColor : Color(hex: hex.wrappedValue))
                    .frame(width: 36, height: 36)
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.gray.opacity(0.3), lineWidth: 1))

                TextField("#RRGGBB", text: hex)
                    .font(.system(size: 14, design: .monospaced))
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.allCharacters)
                    .disableAutocorrection(true)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 10), spacing: 5) {
                ForEach(presetColors, id: \.self) { color in
                    Circle()
                        .fill(Color(hex: color))
                        .frame(width: 26, height: 26)
                        .overlay(
                            Circle().strokeBorder(hex.wrappedValue == color ? Color.primary : Color.gray.opacity(0.2), lineWidth: hex.wrappedValue == color ? 2.5 : 1)
                        )
                        .onTapGesture { hex.wrappedValue = color }
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(cardBg))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private func loadExistingColors() {
        if let colors = currentShift?.customColors {
            textColorHex = colors.textColorHex ?? ""
            shiftColorHex = colors.shiftColorHex ?? ""
            bgColorHex = colors.bgColorHex ?? ""
        }
    }

    private func saveDayColors() {
        guard let idx = viewModel.schedules.firstIndex(where: { $0.id == viewModel.activeScheduleId }) else { return }
        guard var shift = viewModel.schedules[idx].shifts[dateKey] else { return }

        var config = ShiftColorConfig()
        config.textColorHex = textColorHex.isEmpty ? nil : textColorHex
        config.shiftColorHex = shiftColorHex.isEmpty ? nil : shiftColorHex
        config.bgColorHex = bgColorHex.isEmpty ? nil : bgColorHex

        if config.textColorHex == nil && config.shiftColorHex == nil && config.bgColorHex == nil {
            shift.customColors = nil
        } else {
            shift.customColors = config
        }

        viewModel.schedules[idx].shifts[dateKey] = shift
        viewModel.saveAllSchedules()
        dismiss()
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "M月d日"
        f.locale = Locale(identifier: "zh_CN")
        return f.string(from: date)
    }
}
