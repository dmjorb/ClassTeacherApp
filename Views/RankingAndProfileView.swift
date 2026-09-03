import SwiftUI
import UniformTypeIdentifiers

// 我的页面
struct ProfileView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showingClearConfirm = false
    @State private var showingRestoreConfirm = false
    @State private var showingAbout = false
    @State private var showingImport = false
    @State private var exportURL: URL?
    @State private var importResultMessage: String?
    @State private var showingImportResult = false

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
                LabeledContent("成绩记录", value: "\(viewModel.scoreRecords.count) 条")
                LabeledContent("通知", value: "\(viewModel.notifications.count) 条")
                LabeledContent("相册照片", value: "\(viewModel.albumPhotos.count) 张")
                LabeledContent("待办", value: "\(viewModel.pendingTodos.count) 项")
            }

            // 数据管理
            Section {
                if let url = exportURL {
                    ShareLink(item: url) {
                        Label("导出数据（JSON 备份）", systemImage: "square.and.arrow.up")
                    }
                } else {
                    Label("导出数据（准备中…）", systemImage: "square.and.arrow.up")
                        .foregroundColor(.secondary)
                }
                Button {
                    showingImport = true
                } label: {
                    Label("导入数据（JSON 备份）", systemImage: "square.and.arrow.down")
                }
                Button {
                    showingRestoreConfirm = true
                } label: {
                    Label("恢复示例数据", systemImage: "sparkles")
                }
            } header: {
                Text("数据管理")
            } footer: {
                Text("导出/导入会包含全部数据（学生、成绩、课表、通知、相册及照片）。恢复示例数据会覆盖当前全部数据。")
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
        .task {
            prepareExportFile()
        }
        .fileImporter(isPresented: $showingImport, allowedContentTypes: [.json], allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                let accessing = url.startAccessingSecurityScopedResource()
                defer { if accessing { url.stopAccessingSecurityScopedResource() } }
                let ok = viewModel.importBackup(from: url)
                importResultMessage = ok ? "导入成功，数据已恢复。" : "导入失败：文件格式不正确。"
                showingImportResult = true
                prepareExportFile()
            case .failure:
                break
            }
        }
        .alert("清除所有数据？", isPresented: $showingClearConfirm) {
            Button("取消", role: .cancel) {}
            Button("确认清除", role: .destructive) {
                viewModel.clearAllData()
                prepareExportFile()
            }
        } message: {
            Text("将删除全部学生、成绩、课表、值日、通知、相册、待办数据，且无法恢复。")
        }
        .confirmationDialog("恢复示例数据？", isPresented: $showingRestoreConfirm, titleVisibility: .visible) {
            Button("恢复示例数据", role: .destructive) {
                viewModel.restoreSampleData()
                prepareExportFile()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("将用一套完整的示例班级数据覆盖当前全部数据。")
        }
        .alert("导入结果", isPresented: $showingImportResult) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(importResultMessage ?? "")
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
    }

    // 把备份写到临时文件供分享
    private func prepareExportFile() {
        if let data = viewModel.makeBackupData() {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("ClassTeacherApp-backup.json")
            do {
                try data.write(to: url, options: .atomic)
                exportURL = url
            } catch {
                exportURL = nil
            }
        } else {
            exportURL = nil
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
