import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ScheduleViewModel()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            CalendarPageView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "calendar")
                    Text("日历")
                }
                .tag(0)

            SettingsView(viewModel: viewModel, selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("设置")
                }
                .tag(1)
        }
        .tint(Color(red: 79/255, green: 70/255, blue: 229/255))
    }
}
