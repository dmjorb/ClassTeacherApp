import SwiftUI

// 设置页面
struct SettingsView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingResetAlert = false
    @State private var showingClearAlert = false
    @State private var editingClassName = false
    @State private var className = ""
    @State private var headTeacher = ""
    
    var body: some View {
        NavigationStack {
            List {
                // 班级信息
                Section("班级信息") {
                    HStack {
                        Text("班级名称")
                        Spacer()
                        if editingClassName {
                            TextField("", text: $className)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 150)
                        } else {
                            Text(viewModel.classInfo.className)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("班主任")
                        Spacer()
                        if editingClassName {
                            TextField("", text: $headTeacher)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 150)
                        } else {
                            Text(viewModel.classInfo.headTeacher)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if editingClassName {
                        Button("保存") {
                            viewModel.classInfo.className = className
                            viewModel.classInfo.headTeacher = headTeacher
                            editingClassName = false
                        }
                        .foregroundColor(.blue)
                        
                        Button("取消") {
                            editingClassName = false
                            loadClassInfo()
                        }
                        .foregroundColor(.red)
                    } else {
                        Button("编辑班级信息") {
                            editingClassName = true
                            loadClassInfo()
                        }
                    }
                }
                
                // 数据统计
                Section("数据统计") {
                    statRow(title: "学生人数", value: "\(viewModel.students.count)")
                    statRow(title: "成绩记录", value: "\(viewModel.scoreRecords.count)")
                    statRow(title: "课程数量", value: "\(viewModel.courses.count)")
                    statRow(title: "值日小组", value: "\(viewModel.dutyGroups.count)")
                    statRow(title: "待办事项", value: "\(viewModel.todos.count)")
                    statRow(title: "相册照片", value: "\(viewModel.albumPhotos.count)")
                }
                
                // 数据管理
                Section("数据管理") {
                    Button(action: {
                        showingResetAlert = true
                    }) {
                        Label("恢复示例数据", systemImage: "arrow.counterclockwise")
                            .foregroundColor(.blue)
                    }
                    
                    Button(role: .destructive, action: {
                        showingClearAlert = true
                    }) {
                        Label("清除所有数据", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }
                
                // 关于
                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("开发者")
                        Spacer()
                        Text("班主任工作台")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
            .onAppear {
                loadClassInfo()
            }
            .alert("恢复示例数据", isPresented: $showingResetAlert) {
                Button("取消", role: .cancel) {}
                Button("恢复", role: .destructive) {
                    viewModel.resetToMockData()
                }
            } message: {
                Text("当前所有数据将被替换为示例数据，此操作不可撤销。")
            }
            .alert("清除所有数据", isPresented: $showingClearAlert) {
                Button("取消", role: .cancel) {}
                Button("清除", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("所有学生、成绩、课程、照片等数据将被永久删除，此操作不可撤销。")
            }
        }
    }
    
    private func statRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
    
    private func loadClassInfo() {
        className = viewModel.classInfo.className
        headTeacher = viewModel.classInfo.headTeacher
    }
    
    private func clearAllData() {
        viewModel.students = []
        viewModel.scoreRecords = []
        viewModel.courses = []
        viewModel.dutyGroups = []
        viewModel.todos = []
        viewModel.albumPhotos = []
        DataManager.shared.clearAllData()
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppViewModel())
}
