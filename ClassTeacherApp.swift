import SwiftUI

@main
struct ClassTeacherApp: App {
    @StateObject private var viewModel = AppViewModel()

    init() {
        AppTheme.applyGlobalAppearance()
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(viewModel)
                .tint(AppTheme.Colors.accent)
        }
    }
}

// 主 Tab 视图
struct MainTabView: View {
    @EnvironmentObject var viewModel: AppViewModel

    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("工作台", systemImage: "square.grid.2x2.fill")
            }

            NavigationStack {
                StudentListView()
            }
            .tabItem {
                Label("学生", systemImage: "person.2.fill")
            }

            NavigationStack {
                ExamListView()
            }
            .tabItem {
                Label("成绩", systemImage: "chart.bar.fill")
            }

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("我的", systemImage: "person.crop.circle.fill")
            }
        }
        .tint(AppTheme.Colors.accent)
    }
}
