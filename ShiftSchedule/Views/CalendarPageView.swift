import SwiftUI

struct CalendarPageView: View {
    @ObservedObject var viewModel: ScheduleViewModel
    @State private var showingQuickSetup = false
    @State private var showingDayDetail = false
    @GestureState private var dragOffset: CGFloat = 0
    @Environment(\.colorScheme) private var colorScheme

    private let weekdays = ["日", "一", "二", "三", "四", "五", "六"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)

    private var pageBg: Color {
        colorScheme == .dark ? Color(red: 0.11, green: 0.11, blue: 0.13) : Color(red: 0.96, green: 0.96, blue: 0.98)
    }
    private var cardBg: Color {
        colorScheme == .dark ? Color(red: 0.17, green: 0.17, blue: 0.19) : .white
    }
    private var labelPrimary: Color {
        colorScheme == .dark ? .white : Color(red: 0.15, green: 0.15, blue: 0.2)
    }
    private var labelSecondary: Color {
        colorScheme == .dark ? Color(white: 0.65) : Color(white: 0.4)
    }
    private var labelTertiary: Color {
        colorScheme == .dark ? Color(white: 0.55) : Color(white: 0.55)
    }

    var body: some View {
        ZStack {
            pageBg.ignoresSafeArea()

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
        VStack(spacing: 8) {
            HStack(alignment: .center) {
                Button(action: { switchMonth(forward: false) }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.white.opacity(0.15))
                        .clipShape(Circle())
                }

                Spacer()

                VStack(spacing: 2) {
                    Text(viewModel.yearString)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                    Text(viewModel.monthString)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }

                Spacer()

                Button(action: { switchMonth(forward: true) }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.white.opacity(0.15))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)

            HStack(spacing: 10) {
                if let schedule = viewModel.activeSchedule {
                    Text(schedule.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(.white.opacity(0.2))
                        .clipShape(Capsule())
                }

                Spacer()

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) { viewModel.goToToday() }
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 9))
                        Text("今天")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.2))
                    .clipShape(Capsule())
                }

                Button(action: { showingQuickSetup = true }) {
                    HStack(spacing: 3) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 9))
                        Text("快捷排班")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.2))
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
        .padding(.top, 10)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 79/255, green: 70/255, blue: 229/255),
                    Color(red: 129/255, green: 100/255, blue: 255/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: Color(red: 79/255, green: 70/255, blue: 229/255).opacity(0.25), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    // MARK: - Calendar Card
    private var calendarCard: some View {
        VStack(spacing: 6) {
            HStack(spacing: 0) {
                ForEach(Array(weekdays.enumerated()), id: \.offset) { index, day in
                    Text(day)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(index == 0 || index == 6 ? Color.red.opacity(0.6) : labelSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 14)
            .padding(.bottom, 4)

            Divider().padding(.horizontal, 8)

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(viewModel.daysInCurrentMonth()) { dayItem in
                    if let date = dayItem.date {
                        DayCellView(
                            date: date,
                            shift: viewModel.activeShifts[viewModel.dateString(from: date)],
                            isToday: viewModel.isToday(date),
                            isWeekend: viewModel.isWeekend(date)
                        )
                        .onTapGesture {
                            viewModel.selectedDate = date
                            showingDayDetail = true
                        }
                    } else {
                        Color.clear.frame(height: 68)
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(cardBg)
                .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 4)
        )
        .offset(x: dragOffset)
        .animation(.interpolatingSpring(stiffness: 200, damping: 22), value: dragOffset)
        .gesture(
            DragGesture(minimumDistance: 20)
                .updating($dragOffset) { value, state, _ in
                    state = value.translation.width * 0.25
                }
                .onEnded { value in
                    let threshold: CGFloat = 50
                    if value.translation.width > threshold {
                        switchMonth(forward: false)
                    } else if value.translation.width < -threshold {
                        switchMonth(forward: true)
                    }
                }
        )
    }

    // MARK: - Today Info Card
    private var todayInfoCard: some View {
        let today = Date()
        let shift = viewModel.activeShifts[viewModel.dateString(from: today)]

        return VStack(spacing: 0) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: shift?.shiftType.gradientColors ?? [.gray, .gray.opacity(0.7)],
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
                        .foregroundColor(labelSecondary)

                    Text(LunarCalendarHelper.lunarDateString(for: today))
                        .font(.system(size: 12))
                        .foregroundColor(labelTertiary)
                }

                Spacer()

                if let shift = shift {
                    Text(shift.shiftType.rawValue)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(shift.shiftType.color)
                } else {
                    Text("未排班")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(labelTertiary)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)

            if let shift = shift {
                Divider().padding(.horizontal, 18)

                HStack(spacing: 20) {
                    if let start = shift.startTime, let end = shift.endTime {
                        Label("\(start) - \(end)", systemImage: "clock.fill")
                            .font(.system(size: 13))
                            .foregroundColor(labelSecondary)
                    }
                    if let location = shift.location, !location.isEmpty {
                        Label(location, systemImage: "mappin.circle.fill")
                            .font(.system(size: 13))
                            .foregroundColor(labelSecondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(cardBg)
                .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 4)
        )
    }

    // MARK: - Month Switch
    private func switchMonth(forward: Bool) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if forward {
                viewModel.nextMonth()
            } else {
                viewModel.previousMonth()
            }
        }
    }
}
