import Foundation

// 数据持久化管理：所有数据存 Documents 目录 JSON 文件
class DataManager {
    static let shared = DataManager()

    private let fileManager = FileManager.default

    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private func fileURL(_ name: String) -> URL {
        documentsURL.appendingPathComponent("\(name).json")
    }

    // MARK: - 通用读写
    private func load<T: Decodable>(_ name: String) -> T? {
        let url = fileURL(name)
        guard fileManager.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private func save<T: Encodable>(_ value: T, to name: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        try? data.write(to: fileURL(name), options: .atomic)
    }

    // 是否已有保存数据（用于判断首次启动）
    var hasSavedData: Bool {
        fileManager.fileExists(atPath: fileURL("classInfo").path)
    }

    // MARK: - 各数据读写
    func loadClassInfo() -> ClassInfo? { load("classInfo") }
    func saveClassInfo(_ v: ClassInfo) { save(v, to: "classInfo") }

    func loadStudents() -> [Student]? { load("students") }
    func saveStudents(_ v: [Student]) { save(v, to: "students") }

    func loadSemesters() -> [Semester]? { load("semesters") }
    func saveSemesters(_ v: [Semester]) { save(v, to: "semesters") }

    func loadExams() -> [Exam]? { load("exams") }
    func saveExams(_ v: [Exam]) { save(v, to: "exams") }

    func loadScores() -> [ScoreRecord]? { load("scores") }
    func saveScores(_ v: [ScoreRecord]) { save(v, to: "scores") }

    func loadCourses() -> [Course]? { load("courses") }
    func saveCourses(_ v: [Course]) { save(v, to: "courses") }

    func loadDutyGroups() -> [DutyGroup]? { load("dutyGroups") }
    func saveDutyGroups(_ v: [DutyGroup]) { save(v, to: "dutyGroups") }

    func loadTodos() -> [TodoItem]? { load("todos") }
    func saveTodos(_ v: [TodoItem]) { save(v, to: "todos") }

    func loadNotifications() -> [NotificationItem]? { load("notifications") }
    func saveNotifications(_ v: [NotificationItem]) { save(v, to: "notifications") }

    func loadNotificationTemplates() -> [NotificationTemplate]? { load("notificationTemplates") }
    func saveNotificationTemplates(_ v: [NotificationTemplate]) { save(v, to: "notificationTemplates") }

    func loadAlbumFolders() -> [AlbumFolder]? { load("albumFolders") }
    func saveAlbumFolders(_ v: [AlbumFolder]) { save(v, to: "albumFolders") }

    func loadAlbumPhotos() -> [AlbumPhoto]? { load("albumPhotos") }
    func saveAlbumPhotos(_ v: [AlbumPhoto]) { save(v, to: "albumPhotos") }

    // MARK: - 照片二进制（单独存文件，避免 JSON 过大）
    private var photosDirectory: URL {
        documentsURL.appendingPathComponent("Photos", isDirectory: true)
    }

    func savePhotoData(_ data: Data, id: UUID) {
        let dir = photosDirectory
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        try? data.write(to: dir.appendingPathComponent(id.uuidString), options: .atomic)
    }

    func loadPhotoData(id: UUID) -> Data? {
        try? Data(contentsOf: photosDirectory.appendingPathComponent(id.uuidString))
    }

    func deletePhotoData(id: UUID) {
        try? fileManager.removeItem(at: photosDirectory.appendingPathComponent(id.uuidString))
    }

    private func deleteAllPhotoFiles() {
        try? fileManager.removeItem(at: photosDirectory)
    }

    // MARK: - 数据管理
    // 导出全部数据为 JSON（用于备份/迁移，包含照片二进制）
    func exportAllData() -> Data? {
        var photoFiles: [String: Data] = [:]
        if let photos = loadAlbumPhotos() {
            for photo in photos {
                if let data = loadPhotoData(id: photo.id) {
                    photoFiles[photo.id.uuidString] = data
                }
            }
        }
        let backup = AllDataBackup(
            classInfo: loadClassInfo() ?? .default,
            students: loadStudents() ?? [],
            exams: loadExams() ?? [],
            scoreRecords: loadScores() ?? [],
            courses: loadCourses() ?? [],
            dutyGroups: loadDutyGroups() ?? [],
            todos: loadTodos() ?? [],
            notifications: loadNotifications() ?? [],
            albumFolders: loadAlbumFolders() ?? [],
            albumPhotos: loadAlbumPhotos() ?? [],
            photoFiles: photoFiles
        )
        return try? JSONEncoder().encode(backup)
    }

    // 导入备份：写回照片文件
    func importPhotoFiles(_ files: [String: Data]) {
        for (id, data) in files {
            guard let uuid = UUID(uuidString: id) else { continue }
            savePhotoData(data, id: uuid)
        }
    }

    // 清空全部数据
    func clearAllData() {
        for name in ["classInfo", "students", "exams", "scores", "courses", "dutyGroups", "todos", "notifications", "albumFolders", "albumPhotos"] {
            try? fileManager.removeItem(at: fileURL(name))
        }
        deleteAllPhotoFiles()
    }
}
