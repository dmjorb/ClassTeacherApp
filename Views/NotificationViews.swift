import SwiftUI

// 发通知
struct SendNotificationView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: AppViewModel
    
    @State private var title = ""
    @State private var content = ""
    @State private var target = "全班"
    
    let targets = ["全班", "第1组", "第2组", "第3组", "第4组", "第5组", "男生", "女生"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("通知标题") {
                    TextField("请输入通知标题", text: $title)
                }
                Section("通知内容") {
                    TextEditor(text: $content)
                        .frame(minHeight: 120)
                }
                Section("接收范围") {
                    Picker("接收范围", selection: $target) {
                        ForEach(targets, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                }
                Section {
                    Button(action: {
                        if !title.isEmpty && !content.isEmpty {
                            viewModel.sendNotification(title: title, content: content, target: target)
                            dismiss()
                        }
                    }) {
                        Text("发布通知")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(12)
                    }
                    .listRowBackground(Color.clear)
                    .disabled(title.isEmpty || content.isEmpty)
                }
            }
            .navigationTitle("发通知")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("取消") { dismiss() } }
            }
        }
    }
}

// 通知记录
struct NotificationListView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var selectedNotification: NotificationItem?
    
    var body: some View {
        Group {
            if viewModel.notifications.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "bell.slash")
                        .font(.system(size: 64))
                        .foregroundColor(.gray)
                    Text("暂无通知记录")
                        .font(.title2)
                        .fontWeight(.medium)
                    Text("发布的通知会显示在这里")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
            } else {
                List {
                    ForEach(viewModel.notifications) { notification in
                        Button(action: {
                            selectedNotification = notification
                            viewModel.markAsRead(notification)
                        }) {
                            notificationRow(notification)
                        }
                    }
                    .onDelete(perform: deleteNotification)
                }
                .listStyle(.plain)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("通知记录")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedNotification) { notification in
            NotificationDetailView(notification: notification)
        }
    }
    
    private func notificationRow(_ notification: NotificationItem) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(notification.isPinned ? Color.orange : Color.blue)
                .frame(width: 40, height: 40)
                .overlay(Image(systemName: notification.isPinned ? "pin.fill" : "bell.fill").foregroundColor(.white).font(.caption))
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notification.title)
                        .font(.headline)
                        .lineLimit(1)
                    if notification.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                    if !notification.isRead {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                    }
                }
                Text(notification.content)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                HStack {
                    Text(notification.target)
                        .font(.caption)
                        .foregroundColor(.blue)
                    Spacer()
                    Text(formattedDate(notification.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func deleteNotification(at offsets: IndexSet) {
        offsets.forEach { index in
            viewModel.deleteNotification(viewModel.notifications[index])
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M/d HH:mm"
        return f.string(from: date)
    }
}

// 通知详情
struct NotificationDetailView: View {
    let notification: NotificationItem
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(notification.title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    HStack {
                        Text(notification.target)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        Spacer()
                        Text(formattedDate(notification.date))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    Text(notification.content)
                        .font(.body)
                        .lineSpacing(8)
                }
                .padding()
            }
            .background(Color(.systemBackground))
            .navigationTitle("通知详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { viewModel.togglePin(notification) }) {
                            Label(notification.isPinned ? "取消置顶" : "置顶", systemImage: notification.isPinned ? "pin.slash" : "pin")
                        }
                        Button(role: .destructive, action: {
                            viewModel.deleteNotification(notification)
                            dismiss()
                        }) {
                            Label("删除", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "yyyy年M月d日 HH:mm"
        return f.string(from: date)
    }
}
