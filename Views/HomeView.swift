import SwiftUI

// 首页 - 工作台（iOS 原生系统样式）
struct HomeView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showingAddTodo = false
    @State private var newTodoTitle = ""
    @State private var showingSettings = false
    
    // 8个功能入口
    let features: [(name: String, icon: String, color: Color, destination: FeatureDestination)] = [
        ("学生名册", "person.2.fill", .blue, .studentList),
        ("成绩管理", "chart.bar.fill", .green, .examList),
        ("座位排布", "chair.fill", .purple, .seat),
        ("发通知", "megaphone.fill", .orange, .sendNotification),
        ("班级课表", "calendar.fill", .cyan, .schedule),
        ("值日表", "brush.fill", .mint, .duty),
        ("总分排名", "trophy.fill", .yellow, .ranking),
        ("通知记录", "doc.text.fill", .brown, .notificationList)
    ]
    
    enum FeatureDestination {
        case studentList, examList, seat, sendNotification, schedule, duty, ranking, notificationList
    }
    
    var body: some View {
        List {
            // 数据概览
            Section {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                    statCard(value: "\(viewModel.classInfo.studentCount)", label: "班级学生", systemImage: "person.2.fill", color: .blue)
                    statCard(value: "\(viewModel.pendingScoreCount())", label: "待录成绩", systemImage: "square.and.pencil", color: .orange)
                    statCard(value: "\(viewModel.classInfo.subjects.count)", label: "开设科目", systemImage: "book.fill", color: .green)
                }
                .padding(.vertical, 8)
            }
            
            // 常用功能
            Section {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 16) {
                    ForEach(features, id: \.name) { feature in
                        featureButton(feature)
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("常用功能")
            }
            
            // 下周一值日
            Section {
                if let dutyGroup = viewModel.currentDutyGroup {
                    HStack {
                        Image(systemName: "brush.fill")
                            .foregroundColor(.mint)
                            .frame(width: 32)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("第\(dutyGroup.groupNumber)组")
                                .font(.headline)
                            Text(viewModel.dutyStudentNames(for: dutyGroup))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        Button("下一组") {
                            viewModel.nextDutyGroup()
                        }
                        .font(.subheadline)
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("下周一值日")
            }
            
            // 今日课程
            Section {
                let todayCourses = viewModel.myCourses(for: viewModel.todayDayOfWeek)
                if todayCourses.isEmpty {
                    Label("今日无我的课程", systemImage: "cup.and.saucer.fill")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(todayCourses) { course in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Text("第\(course.period)节")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                )
                            VStack(alignment: .leading, spacing: 2) {
                                Text(course.subject)
                                    .font(.headline)
                                Text("\(course.startTime)-\(course.endTime) · \(course.classroom)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                        }
                        .padding(.vertical, 4)
                    }
                }
            } header: {
                Text("今日课程（我的课）")
            }
            
            // 今日待办
            Section {
                ForEach(viewModel.todos) { todo in
                    Button(action: { viewModel.toggleTodo(todo) }) {
                        HStack(spacing: 12) {
                            Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(todo.isCompleted ? .green : .gray)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(todo.title)
                                    .font(.body)
                                    .strikethrough(todo.isCompleted)
                                    .foregroundColor(todo.isCompleted ? .secondary : .primary)
                                if let related = todo.relatedInfo {
                                    Text(related)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            priorityIcon(todo.priority)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: deleteTodo)
                
                Button(action: { showingAddTodo = true }) {
                    Label("添加待办", systemImage: "plus.circle.fill")
                        .foregroundColor(.orange)
                }
            } header: {
                Text("今日待办")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("工作台")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape.fill")
                }
            }
        }
        .sheet(isPresented: $showingAddTodo) {
            addTodoSheet
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
    
    // MARK: - 组件
    private func statCard(value: String, label: String, systemImage: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundColor(color)
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundColor(.primary)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
    
    private func featureButton(_ feature: (name: String, icon: String, color: Color, destination: FeatureDestination)) -> some View {
        NavigationLink(destination: destinationView(for: feature.destination)) {
            VStack(spacing: 8) {
                Image(systemName: feature.icon)
                    .font(.title2)
                    .foregroundColor(feature.color)
                    .frame(width: 48, height: 48)
                    .background(feature.color.opacity(0.15))
                    .cornerRadius(12)
                Text(feature.name)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
    
    private func priorityIcon(_ priority: TodoItem.Priority) -> some View {
        Group {
            switch priority {
            case .high: Image(systemName: "exclamationmark.circle.fill").foregroundColor(.red)
            case .medium: Image(systemName: "circle.fill").foregroundColor(.orange)
            case .low: Image(systemName: "circle.fill").foregroundColor(.gray)
            }
        }
    }
    
    private func deleteTodo(at offsets: IndexSet) {
        offsets.forEach { index in
            viewModel.todos.remove(at: index)
        }
    }
    
    // MARK: - 目标页面
    @ViewBuilder
    private func destinationView(for destination: FeatureDestination) -> some View {
        switch destination {
        case .studentList: StudentListView()
        case .examList: ExamListView()
        case .seat: SeatView()
        case .sendNotification: SendNotificationView()
        case .schedule: ScheduleView()
        case .duty: DutyView()
        case .ranking: RankingView()
        case .notificationList: NotificationListView()
        }
    }
    
    // MARK: - 添加待办
    private var addTodoSheet: some View {
        NavigationStack {
            Form {
                Section("待办内容") {
                    TextField("输入待办事项", text: $newTodoTitle)
                }
            }
            .navigationTitle("添加待办")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { showingAddTodo = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("添加") {
                        if !newTodoTitle.isEmpty {
                            viewModel.addTodo(title: newTodoTitle)
                            newTodoTitle = ""
                            showingAddTodo = false
                        }
                    }
                    .disabled(newTodoTitle.isEmpty)
                }
            }
        }
    }
}
