import SwiftUI

struct ScheduleListView: View {
    @ObservedObject var viewModel: ScheduleViewModel
    @State private var showAddSheet = false
    @State private var showMergeSheet = false
    @State private var newName = ""
    @State private var newSetupType: QuickSetupType = .twoOnTwoOff
    @State private var newColorTag = "indigo"
    @State private var editingId: String?
    @State private var editName = ""

    private let colorOptions: [(String, Color)] = [
        ("indigo", Color(red: 79/255, green: 70/255, blue: 229/255)),
        ("blue", Color(red: 59/255, green: 130/255, blue: 246/255)),
        ("orange", Color(red: 234/255, green: 138/255, blue: 56/255)),
        ("green", Color(red: 16/255, green: 185/255, blue: 129/255)),
        ("pink", Color(red: 236/255, green: 72/255, blue: 153/255)),
        ("purple", Color(red: 147/255, green: 51/255, blue: 234/255))
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(viewModel.schedules) { schedule in
                        scheduleCard(schedule)
                    }

                    addButton
                    mergeButton
                }
                .padding(16)
            }
            .background(Color(red: 0.96, green: 0.96, blue: 0.98))
            .navigationTitle("排班表管理")
            .sheet(isPresented: $showAddSheet) { addSheet }
            .sheet(isPresented: $showMergeSheet) { mergeSheet }
        }
    }

    // MARK: - Schedule Card
    private func scheduleCard(_ schedule: Schedule) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Circle()
                    .fill(colorForTag(schedule.colorTag))
                    .frame(width: 12, height: 12)

                if editingId == schedule.id {
                    TextField("名称", text: $editName, onCommit: {
                        viewModel.renameSchedule(id: schedule.id, name: editName)
                        editingId = nil
                    })
                    .font(.system(size: 16, weight: .semibold))
                    .textFieldStyle(.plain)
                } else {
                    Text(schedule.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }

                if schedule.isMerged {
                    Text("汇总")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.purple)
                        .clipShape(Capsule())
                }

                Spacer()

                if schedule.isStarred {
                    Image(systemName: "star.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.yellow)
                }
            }
            .padding(14)

            Divider().padding(.leading, 38)

            HStack(spacing: 16) {
                if !schedule.isMerged {
                    Text(schedule.setupType.rawValue)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(white: 0.45))

                    Text("班次: \(schedule.shifts.count)天")
                        .font(.system(size: 12))
                        .foregroundColor(Color(white: 0.5))
                } else {
                    Text("合并自 \(schedule.sourceScheduleIds.count) 个排班表")
                        .font(.system(size: 12))
                        .foregroundColor(Color(white: 0.5))
                }

                Spacer()

                Button(action: {
                    viewModel.setStarred(id: schedule.id)
                }) {
                    Image(systemName: schedule.isStarred ? "star.fill" : "star")
                        .font(.system(size: 14))
                        .foregroundColor(schedule.isStarred ? .yellow : Color(white: 0.6))
                }

                Button(action: {
                    editingId = schedule.id
                    editName = schedule.name
                }) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14))
                        .foregroundColor(Color(white: 0.5))
                }

                Button(action: {
                    viewModel.activeScheduleId = schedule.id
                }) {
                    Text("查看")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(colorForTag(schedule.colorTag))
                        .clipShape(Capsule())
                }

                if viewModel.schedules.count > 1 {
                    Button(action: {
                        viewModel.deleteSchedule(id: schedule.id)
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 13))
                            .foregroundColor(.red.opacity(0.7))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Add Button
    private var addButton: some View {
        Button(action: { showAddSheet = true }) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                Text("新建排班表")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(Color(red: 79/255, green: 70/255, blue: 229/255))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color(red: 79/255, green: 70/255, blue: 229/255).opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
            )
        }
    }

    // MARK: - Merge Button
    private var mergeButton: some View {
        Group {
            let nonMerged = viewModel.schedules.filter { !$0.isMerged }
            if nonMerged.count >= 2 {
                Button(action: { showMergeSheet = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.merge")
                            .font(.system(size: 18))
                        Text("合并排班表（汇总）")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.purple)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.purple.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                    )
                }
            }
        }
    }

    // MARK: - Add Sheet
    private var addSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("排班表名称")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(white: 0.3))
                    TextField("例如：我的排班", text: $newName)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 15))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("排班模式")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(white: 0.3))
                    Picker("", selection: $newSetupType) {
                        ForEach(QuickSetupType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("颜色标签")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(white: 0.3))
                    HStack(spacing: 12) {
                        ForEach(colorOptions, id: \.0) { tag, color in
                            Circle()
                                .fill(color)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle().stroke(.white, lineWidth: newColorTag == tag ? 3 : 0)
                                )
                                .shadow(color: newColorTag == tag ? color.opacity(0.5) : .clear, radius: 4)
                                .onTapGesture { newColorTag = tag }
                        }
                    }
                }

                Spacer()
            }
            .padding(20)
            .navigationTitle("新建排班表")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { showAddSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") {
                        let name = newName.isEmpty ? (newSetupType == .twoOnTwoOff ? "我的排班" : "TA的排班") : newName
                        viewModel.addSchedule(name: name, setupType: newSetupType, colorTag: newColorTag)
                        newName = ""
                        showAddSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Merge Sheet
    @State private var selectedMergeIds: Set<String> = []
    @State private var mergeName = "汇总排班"

    private var mergeSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("汇总名称")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(white: 0.3))
                    TextField("例如：汇总排班", text: $mergeName)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 15))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("选择要合并的排班表")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(white: 0.3))

                    ForEach(viewModel.schedules.filter({ !$0.isMerged })) { schedule in
                        Button(action: {
                            if selectedMergeIds.contains(schedule.id) {
                                selectedMergeIds.remove(schedule.id)
                            } else {
                                selectedMergeIds.insert(schedule.id)
                            }
                        }) {
                            HStack {
                                Image(systemName: selectedMergeIds.contains(schedule.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedMergeIds.contains(schedule.id) ? colorForTag(schedule.colorTag) : Color(white: 0.6))
                                Circle().fill(colorForTag(schedule.colorTag)).frame(width: 10, height: 10)
                                Text(schedule.name)
                                    .font(.system(size: 15))
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedMergeIds.contains(schedule.id) ? colorForTag(schedule.colorTag).opacity(0.08) : Color(white: 0.97))
                            )
                        }
                    }
                }

                Spacer()
            }
            .padding(20)
            .navigationTitle("合并排班表")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { showMergeSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("合并") {
                        viewModel.createMergedSchedule(name: mergeName, sourceIds: Array(selectedMergeIds))
                        selectedMergeIds = []
                        showMergeSheet = false
                    }
                    .disabled(selectedMergeIds.count < 2)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func colorForTag(_ tag: String) -> Color {
        colorOptions.first(where: { $0.0 == tag })?.1 ?? .indigo
    }
}
