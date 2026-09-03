import Foundation
import UIKit

// 数据持久化管理器 - 所有数据存本地 Documents 目录
class DataManager {
    static let shared = DataManager()
    
    private let fileManager = FileManager.default
    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var dataURL: URL {
        documentsURL.appendingPathComponent("ClassTeacherData")
    }
    
    private var imagesURL: URL {
        dataURL.appendingPathComponent("Images")
    }
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private init() {
        createDirectories()
        encoder.outputFormatting = .prettyPrinted
    }
    
    // 创建目录
    private func createDirectories() {
        do {
            try fileManager.createDirectory(at: dataURL, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: imagesURL, withIntermediateDirectories: true)
        } catch {
            print("创建目录失败: \(error)")
        }
    }
    
    // MARK: - 通用保存/加载
    
    private func fileURL(for fileName: String) -> URL {
        dataURL.appendingPathComponent(fileName)
    }
    
    private func save<T: Encodable>(_ data: T, fileName: String) {
        do {
            let encoded = try encoder.encode(data)
            try encoded.write(to: fileURL(for: fileName))
        } catch {
            print("保存 \(fileName) 失败: \(error)")
        }
    }
    
    private func load<T: Decodable>(_ fileName: String, type: T.Type) -> T? {
        do {
            let data = try Data(contentsOf: fileURL(for: fileName))
            return try decoder.decode(type, from: data)
        } catch {
            print("加载 \(fileName) 失败: \(error)")
            return nil
        }
    }
    
    // MARK: - 学生数据
    
    func saveStudents(_ students: [Student]) {
        save(students, fileName: "students.json")
    }
    
    func loadStudents() -> [Student]? {
        load("students.json", type: [Student].self)
    }
    
    // MARK: - 成绩数据
    
    func saveScores(_ scores: [ScoreRecord]) {
        save(scores, fileName: "scores.json")
    }
    
    func loadScores() -> [ScoreRecord]? {
        load("scores.json", type: [ScoreRecord].self)
    }
    
    // MARK: - 课程数据
    
    func saveCourses(_ courses: [Course]) {
        save(courses, fileName: "courses.json")
    }
    
    func loadCourses() -> [Course]? {
        load("courses.json", type: [Course].self)
    }
    
    // MARK: - 值日数据
    
    func saveDutyGroups(_ groups: [DutyGroup]) {
        save(groups, fileName: "dutyGroups.json")
    }
    
    func loadDutyGroups() -> [DutyGroup]? {
        load("dutyGroups.json", type: [DutyGroup].self)
    }
    
    // MARK: - 待办数据
    
    func saveTodos(_ todos: [TodoItem]) {
        save(todos, fileName: "todos.json")
    }
    
    func loadTodos() -> [TodoItem]? {
        load("todos.json", type: [TodoItem].self)
    }
    
    // MARK: - 相册数据（元数据）
    
    func saveAlbumPhotos(_ photos: [AlbumPhoto]) {
        // 保存时不包含 imageData，图片单独存文件
        let metadata = photos.map { photo -> AlbumPhoto in
            var p = photo
            // imageData 不存 JSON，存在单独文件
            return p
        }
        save(metadata, fileName: "albumPhotos.json")
    }
    
    func loadAlbumPhotos() -> [AlbumPhoto]? {
        guard var photos = load("albumPhotos.json", type: [AlbumPhoto].self) else { return nil }
        // 从文件加载图片数据
        for i in 0..<photos.count {
            photos[i].imageData = loadImageData(for: photos[i].id)
        }
        return photos
    }
    
    // MARK: - 班级信息
    
    func saveClassInfo(_ info: ClassInfo) {
        save(info, fileName: "classInfo.json")
    }
    
    func loadClassInfo() -> ClassInfo? {
        load("classInfo.json", type: ClassInfo.self)
    }
    
    // MARK: - 图片存储
    
    func saveImage(_ image: UIImage, for id: UUID) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        let fileName = "\(id.uuidString).jpg"
        let fileURL = imagesURL.appendingPathComponent(fileName)
        do {
            try data.write(to: fileURL)
            return fileName
        } catch {
            print("保存图片失败: \(error)")
            return nil
        }
    }
    
    func loadImageData(for id: UUID) -> Data? {
        let fileName = "\(id.uuidString).jpg"
        let fileURL = imagesURL.appendingPathComponent(fileName)
        return try? Data(contentsOf: fileURL)
    }
    
    func loadImage(for id: UUID) -> UIImage? {
        guard let data = loadImageData(for: id) else { return nil }
        return UIImage(data: data)
    }
    
    func deleteImage(for id: UUID) {
        let fileName = "\(id.uuidString).jpg"
        let fileURL = imagesURL.appendingPathComponent(fileName)
        try? fileManager.removeItem(at: fileURL)
    }
    
    // MARK: - 考试数据
    
    func saveExams(_ exams: [Exam]) {
        save(exams, fileName: "exams.json")
    }
    
    func loadExams() -> [Exam]? {
        load("exams.json", type: [Exam].self)
    }
    
    // MARK: - 通知数据
    
    func saveNotifications(_ notifications: [NotificationItem]) {
        save(notifications, fileName: "notifications.json")
    }
    
    func loadNotifications() -> [NotificationItem]? {
        load("notifications.json", type: [NotificationItem].self)
    }
    
    // MARK: - 相册分类数据
    
    func saveAlbumFolders(_ folders: [AlbumFolder]) {
        save(folders, fileName: "albumFolders.json")
    }
    
    func loadAlbumFolders() -> [AlbumFolder]? {
        load("albumFolders.json", type: [AlbumFolder].self)
    }
    
    // MARK: - 全部数据
    
    func saveAll(students: [Student], scores: [ScoreRecord], courses: [Course],
                 dutyGroups: [DutyGroup], todos: [TodoItem], photos: [AlbumPhoto],
                 classInfo: ClassInfo) {
        saveStudents(students)
        saveScores(scores)
        saveCourses(courses)
        saveDutyGroups(dutyGroups)
        saveTodos(todos)
        saveAlbumPhotos(photos)
        saveClassInfo(classInfo)
    }
    
    // 检查是否已有保存的数据
    var hasSavedData: Bool {
        fileManager.fileExists(atPath: fileURL(for: "students.json").path)
    }
    
    // 清除所有数据（恢复示例数据用）
    func clearAllData() {
        do {
            try fileManager.removeItem(at: dataURL)
            createDirectories()
        } catch {
            print("清除数据失败: \(error)")
        }
    }
}
