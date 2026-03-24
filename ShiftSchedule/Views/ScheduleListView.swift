import SwiftUI

struct ScheduleListView: View {
    @ObservedObject var viewModel: ScheduleViewModel
    @Binding var selectedTab: Int
    @State private var activeSheet: ActiveSheet?
    @State private var newName = ""
    @State private var newCity = ""
    @State private var newSetupType: QuickSetupType = .twoOnTwoOff
    @State private var newColorTag = "indigo"
    @State private var editingId: String?
    @State private var editName = ""
    @State private var deleteTargetId: String?
    @State private var showDeleteAlert = false
    @State private var editCityId: String?
    @State private var editCity = ""
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    private enum ActiveSheet: Identifiable {
        case add
        case merge
        case city(String)

        var id: String {
            switch self {
            case .add:
                return "add"
            case .merge:
                return "merge"
            case .city(let id):
                return "city-\(id)"
            }
        }
    }

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
            .background(colorScheme == .dark ? Color(red: 0.11, green: 0.11, blue: 0.13) : Color(red: 0.96, green: 0.96, blue: 0.98))
            .navigationTitle("排班表管理")
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .add:
                    addSheet
                case .merge:
                    mergeSheet
                case .city:
                    citySheet
                }
            }
            .alert("确认删除", isPresented: $showDeleteAlert) {
                Button("取消", role: .cancel) { deleteTargetId = nil }
                Button("删除", role: .destructive) {
                    if let id = deleteTargetId {
                        viewModel.deleteSchedule(id: id)
                    }
                    deleteTargetId = nil
                }
            } message: {
                Text("确定要删除这个排班表吗？删除后无法恢复。")
            }
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
                        .foregroundColor(colorScheme == .dark ? Color(white: 0.6) : Color(white: 0.45))

                    Text("班次: \(schedule.shifts.count)天")
                        .font(.system(size: 12))
                        .foregroundColor(colorScheme == .dark ? Color(white: 0.55) : Color(white: 0.5))
                } else {
                    Text("合并自 \(schedule.sourceScheduleIds.count) 个排班表")
                        .font(.system(size: 12))
                        .foregroundColor(colorScheme == .dark ? Color(white: 0.55) : Color(white: 0.5))
                }

                if !schedule.city.isEmpty {
                    Label(schedule.city, systemImage: "mappin.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.orange.opacity(0.8))
                }

                Spacer()

                Button(action: {
                    viewModel.setStarred(id: schedule.id)
                }) {
                    Image(systemName: schedule.isStarred ? "star.fill" : "star")
                        .font(.system(size: 14))
                        .foregroundColor(schedule.isStarred ? .yellow : Color(white: 0.55))
                }

                Button(action: {
                    editingId = schedule.id
                    editName = schedule.name
                }) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14))
                        .foregroundColor(colorScheme == .dark ? Color(white: 0.6) : Color(white: 0.5))
                }

                Button(action: {
                    editCityId = schedule.id
                    editCity = schedule.city
                    activeSheet = .city(schedule.id)
                }) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 13))
                        .foregroundColor(.orange.opacity(0.7))
                }

                Button(action: {
                    viewModel.switchToSchedule(schedule.id)
                    selectedTab = 0
                    dismiss()
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
                        deleteTargetId = schedule.id
                        showDeleteAlert = true
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
                .fill(colorScheme == .dark ? Color(red: 0.17, green: 0.17, blue: 0.19) : .white)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Add Button
    private var addButton: some View {
        Button(action: {
            newName = ""
            newCity = ""
            newSetupType = .twoOnTwoOff
            newColorTag = "indigo"
            activeSheet = .add
        }) {
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
                Button(action: {
                    selectedMergeIds = []
                    mergeName = "汇总排班"
                    activeSheet = .merge
                }) {
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
                        .foregroundColor(colorScheme == .dark ? Color(white: 0.7) : Color(white: 0.3))
                    TextField("例如：我的排班", text: $newName)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 15))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("排班模式")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(colorScheme == .dark ? Color(white: 0.7) : Color(white: 0.3))
                    Picker("", selection: $newSetupType) {
                        ForEach(QuickSetupType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("天气城市")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(colorScheme == .dark ? Color(white: 0.7) : Color(white: 0.3))
                    TextField("例如：北京（选填，用于显示天气）", text: $newCity)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 15))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("颜色标签")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(colorScheme == .dark ? Color(white: 0.7) : Color(white: 0.3))
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
                    Button("取消") { activeSheet = nil }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") {
                        let name = newName.isEmpty ? (newSetupType == .twoOnTwoOff ? "我的排班" : "TA的排班") : newName
                        viewModel.addSchedule(name: name, setupType: newSetupType, colorTag: newColorTag)
                        if !newCity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                           let last = viewModel.schedules.last {
                            viewModel.updateScheduleCity(id: last.id, city: newCity.trimmingCharacters(in: .whitespacesAndNewlines))
                        }
                        newName = ""
                        newCity = ""
                        activeSheet = nil
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var citySheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("天气城市")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(colorScheme == .dark ? Color(white: 0.7) : Color(white: 0.3))
                    TextField("例如：北京", text: $editCity)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 15))
                    Text("输入该排班表对应的城市名称，用于在日历底部显示天气")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(20)
            .navigationTitle("设置天气城市")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { activeSheet = nil }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        if let id = editCityId {
                            viewModel.updateScheduleCity(id: id, city: editCity)
                        }
                        activeSheet = nil
                    }
                }
            }
        }
        .presentationDetents([.fraction(0.28)])
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
                        .foregroundColor(colorScheme == .dark ? Color(white: 0.7) : Color(white: 0.3))
                    TextField("例如：汇总排班", text: $mergeName)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 15))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("选择要合并的排班表")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(colorScheme == .dark ? Color(white: 0.7) : Color(white: 0.3))

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
                                    .fill(selectedMergeIds.contains(schedule.id) ? colorForTag(schedule.colorTag).opacity(0.08) : (colorScheme == .dark ? Color(white: 0.15) : Color(white: 0.97)))
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
                    Button("取消") { activeSheet = nil }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("合并") {
                        viewModel.createMergedSchedule(name: mergeName, sourceIds: Array(selectedMergeIds))
                        selectedMergeIds = []
                        activeSheet = nil
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
