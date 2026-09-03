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

    // MARK: - 数据管理
    // 导出全部数据为 JSON（用于备份/迁移）
    func exportAllData() -> Data? {
        struct AllData: Codable {
            let classInfo: ClassInfo
            let students: [Student]
            let exams: [Exam]
            let scores: [ScoreRecord]
            let courses: [Course]
            let dutyGroups: [DutyGroup]
            let todos: [TodoItem]
        }
        let data = AllData(
            classInfo: loadClassInfo() ?? .default,
            students: loadStudents() ?? [],
            exams: loadExams() ?? [],
            scores: loadScores() ?? [],
            courses: loadCourses() ?? [],
            dutyGroups: loadDutyGroups() ?? [],
            todos: loadTodos() ?? []
        )
        return try? JSONEncoder().encode(data)
    }

    // 清空全部数据
    func clearAllData() {
        for name in ["classInfo", "students", "exams", "scores", "courses", "dutyGroups", "todos"] {
            try? fileManager.removeItem(at: fileURL(name))
        }
    }
}
