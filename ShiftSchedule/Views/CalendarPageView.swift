import SwiftUI

struct CalendarPageView: View {
    @ObservedObject var viewModel: ScheduleViewModel
    @State private var showingQuickSetup = false
    @State private var showingDayDetail = false

    private let weekdays = ["日", "一", "二", "三", "四", "五", "六"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.95, blue: 1.0),
                    Color(red: 0.98, green: 0.98, blue: 1.0),
                    Color.white
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                headerView
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        calendarCard
                            .padding(.horizontal, 16)
                            .padding(.top, 12)

                        todayInfoCard
                            .padding(.horizontal, 16)

                        Spacer(minLength: 80)
                    }
                }
            }
        }
        .sheet(isPresented: $showingQuickSetup) {
            QuickSetupView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingDayDetail) {
            if let date = viewModel.selectedDate {
                DayDetailView(viewModel: viewModel, date: date)
            }
        }
    }

    // MARK: - Header
    private var headerView: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 79/255, green: 70/255, blue: 229/255),
                    Color(red: 129/255, green: 100/255, blue: 255/255),
                    Color(red: 167/255, green: 139/255, blue: 250/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 8) {
                HStack(alignment: .center) {
                    Button(action: { withAnimation(.spring(response: 0.3)) { viewModel.previousMonth() } }) {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.9))
                    }

                    Spacer()

                    VStack(spacing: 2) {
                        Text(viewModel.yearString)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8))
                        Text(viewModel.monthString)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    Button(action: { withAnimation(.spring(response: 0.3)) { viewModel.nextMonth() } }) {
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
                .padding(.horizontal, 24)

                HStack(spacing: 12) {
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) { viewModel.goToToday() }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 10))
                            Text("今天")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.2))
                        .clipShape(Capsule())
                    }

                    Spacer()

                    Button(action: { showingQuickSetup = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 10))
                            Text("快捷排班")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.2))
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }
            .padding(.top, 8)
        }
        .frame(height: 130)
        .clipShape(
            UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 24, bottomTrailingRadius: 24, topTrailingRadius: 0)
        )
        .shadow(color: Color(red: 79/255, green: 70/255, blue: 229/255).opacity(0.3), radius: 12, x: 0, y: 4)
    }

    // MARK: - Calendar Card
    private var calendarCard: some View {
        VStack(spacing: 6) {
            HStack(spacing: 0) {
                ForEach(Array(weekdays.enumerated()), id: \.offset) { index, day in
                    Text(day)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(index == 0 || index == 6 ? Color.red.opacity(0.6) : Color.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 14)
            .padding(.bottom, 4)

            Divider()
                .padding(.horizontal, 8)

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(viewModel.daysInCurrentMonth()) { dayItem in
                    if let date = dayItem.date {
                        DayCellView(
                            date: date,
                            shift: viewModel.shifts[viewModel.dateString(from: date)],
                            isToday: viewModel.isToday(date),
                            isWeekend: viewModel.isWeekend(date)
                        )
                        .onTapGesture {
                            viewModel.selectedDate = date
                            showingDayDetail = true
                        }
                    } else {
                        Color.clear
                            .frame(height: 68)
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 4)
        )
    }

    // MARK: - Today Info Card
    private var todayInfoCard: some View {
        let today = Date()
        let shift = viewModel.shifts[viewModel.dateString(from: today)]

        return VStack(spacing: 0) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: shift?.shiftType.gradientColors ?? [.blue, .blue.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: shift?.shiftType.icon ?? "calendar")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("今日 \(viewModel.todayDateString) \(viewModel.todayWeekdayString)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)

                    Text(LunarCalendarHelper.lunarDateString(for: today))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary.opacity(0.7))
                }

                Spacer()

                if let shift = shift {
                    Text(shift.shiftType.rawValue)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(shift.shiftType.color)
                } else {
                    Text("未排班")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)

            if let shift = shift {
                Divider()
                    .padding(.horizontal, 18)

                HStack(spacing: 20) {
                    if let start = shift.startTime, let end = shift.endTime {
                        Label("\(start) - \(end)", systemImage: "clock.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }

                    if let location = shift.location, !location.isEmpty {
                        Label(location, systemImage: "mappin.circle.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 4)
        )
    }
}
