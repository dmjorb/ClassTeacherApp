import SwiftUI

// 总分排名
struct RankingView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var selectedExamName = "月考"
    
    var examNames: [String] {
        Array(Set(viewModel.scoreRecords.map { $0.examName })).sorted()
    }
    
    var ranking: [(student: Student, total: Double, average: Double, rank: Int)] {
        viewModel.totalRanking(for: selectedExamName)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 考试选择
            HStack {
                Text("选择考试")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Picker("考试", selection: $selectedExamName) {
                    ForEach(examNames.isEmpty ? ["月考"] : examNames, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.menu)
            }
            .padding()
            .background(Color(.systemBackground))
            
            if ranking.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "trophy")
                        .font(.system(size: 64))
                        .foregroundColor(.gray)
                    Text("暂无排名数据")
                        .font(.title2)
                        .fontWeight(.medium)
                    Text("先在成绩管理中录入考试成绩")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                // 前三名展示
                HStack(spacing: 16) {
                    if ranking.count >= 2 {
                        topStudentCard(ranking[1], rank: 2)
                    }
                    if ranking.count >= 1 {
                        topStudentCard(ranking[0], rank: 1)
                    }
                    if ranking.count >= 3 {
                        topStudentCard(ranking[2], rank: 3)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                
                // 排名列表
                List {
                    ForEach(ranking, id: \.student.id) { item in
                        rankingRow(item)
                    }
                }
                .listStyle(.plain)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("总分排名")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func topStudentCard(_ item: (student: Student, total: Double, average: Double, rank: Int), rank: Int) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(rankColor(rank))
                    .frame(width: rank == 1 ? 64 : 52, height: rank == 1 ? 64 : 52)
                    .overlay(
                        Text(String(item.student.name.prefix(1)))
                            .font(rank == 1 ? .title : .headline)
                            .foregroundColor(.white)
                    )
                Image(systemName: "crown.fill")
                    .font(rank == 1 ? .title2 : .caption)
                    .foregroundColor(.yellow)
                    .offset(y: rank == 1 ? -36 : -30)
            }
            Text(item.student.name)
                .font(.subheadline)
                .fontWeight(.medium)
            Text(String(format: "%.0f分", item.total))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func rankingRow(_ item: (student: Student, total: Double, average: Double, rank: Int)) -> some View {
        HStack(spacing: 12) {
            Text("\(item.rank)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(item.rank <= 3 ? rankColor(item.rank) : .secondary)
                .frame(width: 32)
            
            Circle()
                .fill(Color.orange)
                .frame(width: 40, height: 40)
                .overlay(Text(String(item.student.name.prefix(1))).font(.caption).foregroundColor(.white))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.student.name).font(.subheadline).fontWeight(.medium)
                Text("#\(item.student.studentNumber.suffix(3))").font(.caption2).foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.0f", item.total))
                    .font(.headline)
                    .fontWeight(.bold)
                Text("均分 \(String(format: "%.1f", item.average))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .secondary
        }
    }
}

// 我的页面
struct ProfileView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showingSettings = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 个人信息卡片
                VStack(spacing: 16) {
                    Circle()
                        .fill(LinearGradient(gradient: Gradient(colors: [.orange, .pink]), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text(String(viewModel.classInfo.headTeacher.prefix(1)))
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )
                    
                    VStack(spacing: 4) {
                        Text(viewModel.classInfo.headTeacher)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("\(viewModel.classInfo.className) 班主任")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .padding(.horizontal)
                .padding(.top, 60)
                
                // 数据统计
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        statItem(title: "学生", value: "\(viewModel.students.count)", color: .blue)
                        statItem(title: "考试", value: "\(viewModel.exams.count)", color: .green)
                        statItem(title: "通知", value: "\(viewModel.notifications.count)", color: .orange)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .padding(.horizontal)
                
                // 功能列表
                VStack(spacing: 0) {
                    menuItem(icon: "gearshape.fill", title: "设置", color: .gray) {
                        showingSettings = true
                    }
                    Divider().padding(.leading, 60)
                    menuItem(icon: "square.and.arrow.up", title: "数据导出", color: .blue) {}
                    Divider().padding(.leading, 60)
                    menuItem(icon: "square.and.arrow.down", title: "数据导入", color: .green) {}
                    Divider().padding(.leading, 60)
                    menuItem(icon: "arrow.counterclockwise", title: "恢复示例数据", color: .orange) {
                        viewModel.resetToMockData()
                    }
                    Divider().padding(.leading, 60)
                    menuItem(icon: "info.circle.fill", title: "关于", color: .purple) {}
                }
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .padding(.horizontal)
                
                Text("版本 1.0.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 40)
            }
        }
        .background(Color(.systemGroupedBackground))
        .ignoresSafeArea(edges: .top)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
    
    private func statItem(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title2).fontWeight(.bold).foregroundColor(color)
            Text(title).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func menuItem(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 32)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
        }
    }
}
