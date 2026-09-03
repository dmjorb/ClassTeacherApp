import SwiftUI

// 我的页面
struct ProfileView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showingClearConfirm = false
    @State private var showingAbout = false

    var body: some View {
        Form {
            // 个人信息
            Section {
                HStack(spacing: 14) {
                    Text(String(viewModel.classInfo.headTeacher.isEmpty ? "班" : String(viewModel.classInfo.headTeacher.prefix(1))))
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.accentColor)
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.classInfo.headTeacher.isEmpty ? "未设置班主任" : viewModel.classInfo.headTeacher)
                            .font(.title3.weight(.semibold))
                        Text(viewModel.classInfo.className.isEmpty ? "未设置班级" : viewModel.classInfo.className)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 6)
            }

            // 数据统计
            Section("数据统计") {
                LabeledContent("学生", value: "\(viewModel.students.count) 人")
                LabeledContent("考试", value: "\(viewModel.exams.count) 场")
                LabeledContent("待办", value: "\(viewModel.pendingTodos.count) 项")
                LabeledContent("已录入成绩", value: "\(viewModel.scoreRecords.count) 条")
            }

            // 功能
            Section("管理") {
                NavigationLink {
                    SettingsView()
                } label: {
                    Label("班级设置", systemImage: "gearshape")
                }
                Button(role: .destructive) {
                    showingClearConfirm = true
                } label: {
                    Label("清除所有数据", systemImage: "trash")
                }
            }

            Section {
                Button("关于") {
                    showingAbout = true
                }
            }
        }
        .navigationTitle("我的")
        .alert("清除所有数据？", isPresented: $showingClearConfirm) {
            Button("取消", role: .cancel) {}
            Button("确认清除", role: .destructive) {
                viewModel.clearAllData()
            }
        } message: {
            Text("将删除全部学生、成绩、课表、值日、待办数据，且无法恢复。")
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
    }
}

// 关于页面
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.accentColor)
                    .padding(.top, 40)
                Text("班主任工作台")
                    .font(.title2.bold())
                Text("版本 1.0.0")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("为班主任打造的日常管理工具：学生名册、成绩管理、课表、值日、座位与待办。所有数据仅保存在本机，不上传。")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Spacer()
            }
            .navigationTitle("关于")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}
