import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: ScheduleViewModel
    @State private var showingQuickSetup = false
    @State private var showClearAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    scheduleSection
                    statsSection
                    dangerSection
                    aboutSection
                }
                .padding(20)
            }
            .background(Color(red: 0.96, green: 0.96, blue: 0.98))
            .navigationTitle("设置")
            .sheet(isPresented: $showingQuickSetup) {
                QuickSetupView(viewModel: viewModel)
            }
            .alert("确认清除", isPresented: $showClearAlert) {
                Button("取消", role: .cancel) {}
                Button("清除", role: .destructive) {
                    viewModel.clearAllShifts()
                }
            } message: {
                Text("确定要清除所有排班数据吗？此操作不可撤销。")
            }
        }
    }

    // MARK: - Schedule Section
    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("排班管理")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                Button(action: { showingQuickSetup = true }) {
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
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.primary)
                            Text("一键生成上二休二规律排班")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                    .padding(14)
                }
                .buttonStyle(.plain)
            }
            .background(RoundedRectangle(cornerRadius: 14).fill(.white))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
    }

    // MARK: - Stats Section
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("排班统计")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.leading, 4)

            let stats = calculateStats()

            HStack(spacing: 12) {
                StatCard(title: "复重", count: stats.fuzhong, color: ShiftType.fuzhong.color, icon: "scalemass.fill")
                StatCard(title: "库管", count: stats.kuguang, color: ShiftType.kuguang.color, icon: "shippingbox.fill")
                StatCard(title: "休息", count: stats.rest, color: ShiftType.rest.color, icon: "moon.stars.fill")
            }
        }
    }

    // MARK: - Danger Section
    private var dangerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("数据管理")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.leading, 4)

            Button(action: { showClearAlert = true }) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(0.1))
                            .frame(width: 32, height: 32)
                        Image(systemName: "trash.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                    }

                    Text("清除所有排班")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.red)

                    Spacer()
                }
                .padding(14)
            }
            .buttonStyle(.plain)
            .background(RoundedRectangle(cornerRadius: 14).fill(.white))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
    }

    // MARK: - About Section
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("关于")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                infoRow(icon: "app.badge", title: "应用名称", value: "排班表")
                Divider().padding(.leading, 58)
                infoRow(icon: "number", title: "版本", value: "1.0.0")
                Divider().padding(.leading, 58)
                infoRow(icon: "iphone", title: "适配", value: "iOS 17.0+")
            }
            .background(RoundedRectangle(cornerRadius: 14).fill(.white))
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
                .font(.system(size: 15))

            Spacer()

            Text(value)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding(14)
    }

    private struct Stats {
        var fuzhong: Int = 0
        var kuguang: Int = 0
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

        for dayOffset in 0..<range.count {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfMonth) {
                let key = df.string(from: date)
                if let shift = viewModel.shifts[key] {
                    switch shift.shiftType {
                    case .fuzhong: stats.fuzhong += 1
                    case .kuguang: stats.kuguang += 1
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

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            Text("\(count)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.white)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }
}
