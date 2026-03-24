import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: ScheduleViewModel
    @Binding var selectedTab: Int
    @State private var activeSheet: SettingsSheetType?
    @State private var showClearAlert = false
    @State private var showSyncToast = false
    @Environment(\.colorScheme) private var colorScheme

    private enum SettingsSheetType: String, Identifiable {
        case quickSetup, scheduleList, colorCustomize
        var id: String { rawValue }
    }

    private var pageBg: Color {
        colorScheme == .dark ? Color(red: 0.11, green: 0.11, blue: 0.13) : Color(red: 0.96, green: 0.96, blue: 0.98)
    }
    private var cardBg: Color {
        colorScheme == .dark ? Color(red: 0.17, green: 0.17, blue: 0.19) : .white
    }
    private var sectionTitle: Color {
        colorScheme == .dark ? Color(white: 0.7) : Color(white: 0.3)
    }
    private var subtitleColor: Color {
        colorScheme == .dark ? Color(white: 0.6) : Color(white: 0.45)
    }

    private var canClearActiveSchedule: Bool {
        guard let schedule = viewModel.activeSchedule else { return false }
        return !schedule.isMerged
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    scheduleManageSection
                    widgetSyncSection
                    scheduleSection
                    colorCustomizeSection
                    yearsSection
                    statsSection
                    dangerSection
                    aboutSection
                }
                .padding(20)
            }
            .background(pageBg)
            .navigationTitle("设置")
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .quickSetup:
                    QuickSetupView(viewModel: viewModel)
                case .scheduleList:
                    ScheduleListView(viewModel: viewModel, selectedTab: $selectedTab)
                case .colorCustomize:
                    ColorCustomizeView(viewModel: viewModel)
                }
            }
            .overlay(
                Group {
                    if showSyncToast {
                        VStack {
                            Spacer()
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("小组件已同步")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .shadow(radius: 8)
                            .padding(.bottom, 30)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            )
            .alert("确认清除", isPresented: $showClearAlert) {
                Button("取消", role: .cancel) {}
                Button("清除", role: .destructive) {
                    if let id = viewModel.activeScheduleId {
                        viewModel.clearScheduleShifts(id: id)
                    }
                }
            } message: {
                Text("确定要清除当前排班表的所有排班数据吗？此操作不可撤销。")
            }
        }
    }

    // MARK: - Schedule Management
    private var scheduleManageSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("排班表管理")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(sectionTitle)
                .padding(.leading, 4)

            Button(action: { activeSheet = .scheduleList }) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 32, height: 32)
                        Image(systemName: "list.bullet.rectangle.portrait.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("管理排班表")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                        Text("新建、删除、星标、合并排班表")
                            .font(.system(size: 13))
                            .foregroundColor(subtitleColor)
                    }

                    Spacer()

                    Text("\(viewModel.schedules.count)个")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(subtitleColor)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary.opacity(0.5))
                }
                .padding(14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(RoundedRectangle(cornerRadius: 14).fill(cardBg))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
    }

    // MARK: - Widget Sync
    private var widgetSyncSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("小组件")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(sectionTitle)
                .padding(.leading, 4)

            Button(action: {
                viewModel.syncWidget()
                withAnimation(.spring()) { showSyncToast = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation { showSyncToast = false }
                }
            }) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 32, height: 32)
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("同步小组件")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                        Text("手动刷新桌面小组件数据")
                            .font(.system(size: 13))
                            .foregroundColor(subtitleColor)
                    }

                    Spacer()

                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.blue)
                }
                .padding(14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(RoundedRectangle(cornerRadius: 14).fill(cardBg))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
    }

    // MARK: - Schedule Section
    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("快捷排班")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(sectionTitle)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                Button(action: { activeSheet = .quickSetup }) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: ShiftType.fuzhong.gradientColors,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 32, height: 32)
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("快捷排班")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(colorScheme == .dark ? .white : .primary)
                            if let schedule = viewModel.activeSchedule {
                                Text("当前：\(schedule.name)（\(schedule.setupType.rawValue)）")
                                    .font(.system(size: 13))
                                    .foregroundColor(subtitleColor)
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                    .padding(14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .background(RoundedRectangle(cornerRadius: 14).fill(cardBg))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
    }

    // MARK: - Color Customize
    private var colorCustomizeSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("外观设置")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(sectionTitle)
                .padding(.leading, 4)

            Button(action: { activeSheet = .colorCustomize }) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LinearGradient(colors: [Color(red: 236/255, green: 72/255, blue: 153/255), Color(red: 167/255, green: 139/255, blue: 250/255)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 32, height: 32)
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("自定义颜色")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                        Text("设置班次字体、标签、背景颜色")
                            .font(.system(size: 13))
                            .foregroundColor(subtitleColor)
                    }

                    Spacer()

                    let customCount = viewModel.activeSchedule?.shiftTypeColors.count ?? 0
                    if customCount > 0 {
                        Text("\(customCount)项自定义")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(subtitleColor)
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary.opacity(0.5))
                }
                .padding(14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(RoundedRectangle(cornerRadius: 14).fill(cardBg))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
    }

    // MARK: - Years Config
    private var yearsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("排班范围")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(sectionTitle)
                .padding(.leading, 4)

            if let schedule = viewModel.activeSchedule, !schedule.isMerged {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                            .foregroundColor(.indigo)
                        Text("往后生成年数")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                        Spacer()
                        Picker("", selection: Binding(
                            get: { schedule.yearsForward },
                            set: { viewModel.updateYearsForward(id: schedule.id, years: $0) }
                        )) {
                            ForEach(1...10, id: \.self) { y in
                                Text("\(y)年").tag(y)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.indigo)
                    }

                    HStack {
                        Image(systemName: "calendar.badge.minus")
                            .foregroundColor(.orange)
                        Text("往前生成年数")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                        Spacer()
                        Text("\(schedule.yearsBackward)年")
                            .font(.system(size: 15))
                            .foregroundColor(subtitleColor)
                    }
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14).fill(cardBg))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            }
        }
    }

    // MARK: - Stats Section
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("排班统计（本月）")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(sectionTitle)
                .padding(.leading, 4)

            let stats = calculateStats()

            HStack(spacing: 12) {
                StatCard(title: "复重", count: stats.fuzhong, color: ShiftType.fuzhong.color, icon: "scalemass.fill")
                StatCard(title: "库管", count: stats.kuguang, color: ShiftType.kuguang.color, icon: "shippingbox.fill")
                StatCard(title: "上班", count: stats.work, color: ShiftType.work.color, icon: "briefcase.fill")
                StatCard(title: "休息", count: stats.rest, color: ShiftType.rest.color, icon: "moon.stars.fill")
            }
        }
    }

    // MARK: - Danger Section
    private var dangerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("数据管理")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(sectionTitle)
                .padding(.leading, 4)

            Button(action: {
                if canClearActiveSchedule {
                    showClearAlert = true
                }
            }) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill((canClearActiveSchedule ? Color.red : Color.gray).opacity(0.1))
                            .frame(width: 32, height: 32)
                        Image(systemName: "trash.fill")
                            .font(.system(size: 14))
                            .foregroundColor(canClearActiveSchedule ? .red : .gray)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("清除当前排班表数据")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(canClearActiveSchedule ? .red : .gray)

                        if !canClearActiveSchedule {
                            Text("汇总排班不能直接清空，请修改来源排班表")
                                .font(.system(size: 12))
                                .foregroundColor(subtitleColor)
                        }
                    }

                    Spacer()
                }
                .padding(14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!canClearActiveSchedule)
            .background(RoundedRectangle(cornerRadius: 14).fill(cardBg))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
    }

    // MARK: - About Section
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("关于")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(sectionTitle)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                infoRow(icon: "app.badge", title: "应用名称", value: "排班表")
                Divider().padding(.leading, 58)
                infoRow(icon: "number", title: "版本", value: "2.0.0")
                Divider().padding(.leading, 58)
                infoRow(icon: "iphone", title: "适配", value: "iOS 17.0+")
            }
            .background(RoundedRectangle(cornerRadius: 14).fill(cardBg))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
    }

    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }

            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(colorScheme == .dark ? .white : .primary)

            Spacer()

            Text(value)
                .font(.system(size: 15))
                .foregroundColor(subtitleColor)
        }
        .padding(14)
    }

    private struct Stats {
        var fuzhong: Int = 0
        var kuguang: Int = 0
        var work: Int = 0
        var rest: Int = 0
    }

    private func calculateStats() -> Stats {
        var stats = Stats()
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month], from: now)
        guard let startOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: now) else {
            return stats
        }

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"

        let shifts = viewModel.activeShifts
        for dayOffset in 0..<range.count {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfMonth) {
                let key = df.string(from: date)
                if let shift = shifts[key] {
                    switch shift.shiftType {
                    case .fuzhong: stats.fuzhong += 1
                    case .kuguang: stats.kuguang += 1
                    case .work: stats.work += 1
                    case .rest: stats.rest += 1
                    }
                }
            }
        }
        return stats
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let count: Int
    let color: Color
    let icon: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)

            Text("\(count)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(colorScheme == .dark ? .white : Color(red: 0.15, green: 0.15, blue: 0.2))

            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(colorScheme == .dark ? Color(white: 0.6) : Color(white: 0.35))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(colorScheme == .dark ? Color(red: 0.17, green: 0.17, blue: 0.19) : .white)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }
}
