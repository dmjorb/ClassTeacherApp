import SwiftUI

// 工作台首页
struct HomeView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showingAddTodo = false
    @State private var newTodoTitle = ""
    @State private var showingCompose = false

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "上午好"
        case 12..<14: return "中午好"
        case 14..<18: return "下午好"
        default: return "晚上好"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                statCards
                functionGrid
                nextDutySection
                todayCoursesSection
                todoSection
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .ignoresSafeArea(edges: .top)
        .toolbar(.hidden, for: .navigationBar)
        .alert("添加待办", isPresented: $showingAddTodo) {
            TextField("待办事项", text: $newTodoTitle)
            Button("取消", role: .cancel) {}
            Button("添加") {
                let title = newTodoTitle.trimmingCharacters(in: .whitespaces)
                if !title.isEmpty {
                    viewModel.addTodo(title: title)
                }
                newTodoTitle = ""
            }
        }
        .sheet(isPresented: $showingCompose) {
            NavigationStack {
                NotificationComposeView()
            }
        }
    }

    // MARK: - 顶部渐变头部
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(greeting)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.85))
            HStack(alignment: .firstTextBaseline) {
                Text(viewModel.classInfo.className.isEmpty ? "我的班级" : viewModel.classInfo.className)
                    .font(.title.bold())
                    .foregroundColor(.white)
                Spacer()
                Text("\(viewModel.weekdayString) \(viewModel.todayString)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 60)
        .padding(.bottom, 24)
        .background(
            LinearGradient(colors: [Color(red: 0.55, green: 0.40, blue: 0.85), Color(red: 0.72, green: 0.55, blue: 0.90)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
    }

    // MARK: - 数据概览
    private var statCards: some View {
        HStack(spacing: 12) {
            StatCard(value: "\(viewModel.students.count)", label: "学生", systemImage: "person.2.fill", color: .blue)
            StatCard(value: "\(viewModel.exams.count)", label: "考试", systemImage: "doc.text.fill", color: .orange)
            StatCard(value: "\(viewModel.pendingTodos.count)", label: "待办", systemImage: "checklist", color: .green)
        }
    }

    // MARK: - 功能入口（全部为真实跳转/弹窗）
    private var functionGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("功能")
                .font(.headline)
                .padding(.horizontal, 4)

            LazyVGrid(columns: columns, spacing: 12) {
                NavigationLink { StudentListView() } label: {
                    FeatureButton(title: "学生名册", systemImage: "person.2.fill", color: .blue)
                }
                .buttonStyle(.plain)

                NavigationLink { ExamListView() } label: {
                    FeatureButton(title: "成绩管理", systemImage: "chart.bar.fill", color: .orange)
                }
                .buttonStyle(.plain)

                NavigationLink { SeatView() } label: {
                    FeatureButton(title: "座位表", systemImage: "square.grid.3x3.fill", color: .teal)
                }
                .buttonStyle(.plain)

                NavigationLink { ScheduleView() } label: {
                    FeatureButton(title: "班级课表", systemImage: "calendar", color: .purple)
                }
                .buttonStyle(.plain)

                NavigationLink { DutyView() } label: {
                    FeatureButton(title: "值日表", systemImage: "broom.fill", color: .green)
                }
                .buttonStyle(.plain)

                Button {
                    showingCompose = true
                } label: {
                    FeatureButton(title: "发通知", systemImage: "megaphone.fill", color: .red)
                }
                .buttonStyle(.plain)

                NavigationLink { NotificationListView() } label: {
                    ZStack(alignment: .topTrailing) {
                        FeatureButton(title: "通知记录", systemImage: "bell.fill", color: .indigo)
                        if viewModel.unreadNotificationCount > 0 {
                            Text("\(viewModel.unreadNotificationCount)")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(Capsule().fill(Color.red))
                                .offset(x: -8, y: 4)
                        }
                    }
                }
                .buttonStyle(.plain)

                NavigationLink { RankingListView() } label: {
                    FeatureButton(title: "总分排名", systemImage: "list.number", color: .pink)
                }
                .buttonStyle(.plain)

                NavigationLink { AlbumListView() } label: {
                    FeatureButton(title: "班级相册", systemImage: "photo.on.rectangle.angled", color: .cyan)
                }
                .buttonStyle(.plain)

                NavigationLink { ClassMapView() } label: {
                    FeatureButton(title: "分布地图", systemImage: "map.fill", color: .brown)
                }
                .buttonStyle(.plain)

                NavigationLink { SettingsView() } label: {
                    FeatureButton(title: "班级设置", systemImage: "gearshape.fill", color: .gray)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - 下次值日
    @ViewBuilder
    private var nextDutySection: some View {
        if let duty = viewModel.currentDutyGroup {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("值日安排")
                        .font(.headline)
                    Spacer()
                    Button("换下一组") {
                        withAnimation { viewModel.nextDutyGroup() }
                    }
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
                }
                HStack(spacing: 14) {
                    Text("\(duty.groupNumber)")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .frame(width: 52, height: 52)
                        .background(Color.green)
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 4) {
                        Text("第\(duty.groupNumber)值日组")
                            .font(.body.weight(.semibold))
                        Text(viewModel.dutyStudentNames(of: duty).isEmpty ? "未安排成员" : viewModel.dutyStudentNames(of: duty))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    // MARK: - 今日课程
    private var todayCoursesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("今日课程")
                    .font(.headline)
                Spacer()
                NavigationLink("课表") { ScheduleView() }
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
            }

            let todayCourses = viewModel.todayCourses()
            if todayCourses.isEmpty {
                Text("今天没有排课")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(todayCourses.enumerated()), id: \.element.id) { index, course in
                        HStack(spacing: 12) {
                            Text("第\(course.period)节")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.accentColor)
                                .frame(width: 56, alignment: .leading)
                            Text(course.subject)
                                .font(.body.weight(.medium))
                            if !course.teacher.isEmpty {
                                Text(course.teacher)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if !course.classroom.isEmpty {
                                Text(course.classroom)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        if index < todayCourses.count - 1 {
                            Divider().padding(.leading, 80)
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    // MARK: - 今日待办
    private var todoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("今日待办")
                    .font(.headline)
                Spacer()
                Button {
                    showingAddTodo = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(.accentColor)
                }
            }

            let pending = viewModel.pendingTodos
            if pending.isEmpty {
                Text("没有待办事项")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(pending.enumerated()), id: \.element.id) { index, todo in
                        HStack(spacing: 12) {
                            Button {
                                viewModel.toggleTodo(todo)
                            } label: {
                                Image(systemName: "circle")
                                    .foregroundColor(.secondary)
                            }
                            Text(todo.title)
                                .font(.body)
                            Spacer()
                            Button {
                                viewModel.deleteTodo(todo)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        if index < pending.count - 1 {
                            Divider().padding(.leading, 44)
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }
}
