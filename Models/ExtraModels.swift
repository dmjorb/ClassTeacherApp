import Foundation

// MARK: - 通知
struct NotificationItem: Identifiable, Codable {
    let id: UUID
    var title: String
    var content: String
    var date: Date
    var audience: String        // 接收范围：全班 / 家长 / 班干部
    var isPinned: Bool
    var isRead: Bool

    static let audiences = ["全班", "家长", "班干部"]

    init(id: UUID = UUID(), title: String, content: String, date: Date = Date(),
         audience: String = "全班", isPinned: Bool = false, isRead: Bool = false) {
        self.id = id
        self.title = title
        self.content = content
        self.date = date
        self.audience = audience
        self.isPinned = isPinned
        self.isRead = isRead
    }
}

// MARK: - 相册分类
struct AlbumFolder: Identifiable, Codable {
    let id: UUID
    var name: String
    var category: String        // 如：班级活动、运动会、日常
    var isPinned: Bool
    var photoIds: [UUID]

    init(id: UUID = UUID(), name: String, category: String = "班级活动",
         isPinned: Bool = false, photoIds: [UUID] = []) {
        self.id = id
        self.name = name
        self.category = category
        self.isPinned = isPinned
        self.photoIds = photoIds
    }
}

// MARK: - 相册照片（图片二进制按 id 存 Documents/Photos 目录）
struct AlbumPhoto: Identifiable, Codable {
    let id: UUID
    var folderId: UUID
    var title: String
    var date: Date
    var note: String

    init(id: UUID = UUID(), folderId: UUID, title: String = "", date: Date = Date(), note: String = "") {
        self.id = id
        self.folderId = folderId
        self.title = title
        self.date = date
        self.note = note
    }
}

// MARK: - 全量备份（导出/导入用）
struct AllDataBackup: Codable {
    var classInfo: ClassInfo
    var students: [Student]
    var exams: [Exam]
    var scoreRecords: [ScoreRecord]
    var courses: [Course]
    var dutyGroups: [DutyGroup]
    var todos: [TodoItem]
    var notifications: [NotificationItem]
    var albumFolders: [AlbumFolder]
    var albumPhotos: [AlbumPhoto]
    var photoFiles: [String: Data]
}
