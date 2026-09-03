import SwiftUI

// 通知记录列表
struct NotificationListView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showingCompose = false

    private var sortedNotifications: [NotificationItem] {
        viewModel.notifications.sorted {
            if $0.isPinned != $1.isPinned { return $0.isPinned }
            return $0.date > $1.date
        }
    }

    var body: some View {
        Group {
            if sortedNotifications.isEmpty {
                EmptyStateView(
                    systemImage: "bell",
                    title: "还没有通知",
                    message: "点击右上角 + 发布一条通知"
                )
            } else {
                List {
                    ForEach(sortedNotifications) { item in
                        NavigationLink {
                            NotificationDetailView(notificationId: item.id)
                        } label: {
                            NotificationRow(item: item)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                viewModel.deleteNotification(item)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                            Button {
                                viewModel.togglePinNotification(item)
                            } label: {
                                Label(item.isPinned ? "取消置顶" : "置顶", systemImage: "pin")
                            }
                            .tint(.orange)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("通知记录")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingCompose = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCompose) {
            NavigationStack {
                NotificationComposeView()
            }
        }
    }
}

// 通知行
struct NotificationRow: View {
    @EnvironmentObject var viewModel: AppViewModel
    let item: NotificationItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.isPinned ? "pin.fill" : "bell.fill")
                .foregroundColor(item.isPinned ? .orange : .accentColor)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    if !item.isRead {
                        Circle().fill(Color.red).frame(width: 8, height: 8)
                    }
                    Text(item.title)
                        .font(.body.weight(.semibold))
                        .lineLimit(1)
                    PillTag(title: item.audience)
                }
                Text(item.content)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Text(item.date.formatted(.dateTime.month().day()))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

// 通知详情（打开即标记已读，数据实时读取）
struct NotificationDetailView: View {
    @EnvironmentObject var viewModel: AppViewModel
    let notificationId: UUID

    private var item: NotificationItem? { viewModel.notification(id: notificationId) }

    var body: some View {
        Group {
            if let item = item {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            PillTag(title: item.audience)
                            if item.isPinned {
                                Label("已置顶", systemImage: "pin.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                            Spacer()
                            Text(item.date.formatted(.dateTime.year().month().day().hour().minute()))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text(item.title)
                            .font(.title3.weight(.bold))
                        Text(item.content)
                            .font(.body)
                            .lineSpacing(4)
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
                .onAppear { viewModel.markNotificationRead(item) }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            viewModel.togglePinNotification(item)
                        } label: {
                            Image(systemName: item.isPinned ? "pin.slash" : "pin")
                        }
                    }
                }
            } else {
                EmptyStateView(systemImage: "bell.slash", title: "通知不存在", message: "该通知可能已被删除")
            }
        }
        .navigationTitle("通知详情")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// 发通知表单
struct NotificationComposeView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var content = ""
    @State private var audience = "全班"

    var body: some View {
        NavigationStack {
            Form {
                Section("通知内容") {
                    TextField("标题", text: $title)
                    TextField("内容", text: $content, axis: .vertical)
                        .lineLimit(4...8)
                }
                Section("接收范围") {
                    Picker("发送给", selection: $audience) {
                        ForEach(NotificationItem.audiences, id: \.self) { a in
                            Text(a).tag(a)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("发通知")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("发布") {
                        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        let c = content.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !t.isEmpty, !c.isEmpty else { return }
                        viewModel.addNotification(title: t, content: c, audience: audience)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                              || content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
