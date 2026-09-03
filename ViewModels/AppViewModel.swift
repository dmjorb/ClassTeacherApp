import Foundation
import SwiftUI
import Combine

// 全局应用状态 - 支持本地持久化，数据变化自动保存
class AppViewModel: ObservableObject {
    @Published var students: [Student]
    @Published var courses: [Course]
    @Published var dutyGroups: [DutyGroup]
    @Published var todos: [TodoItem]
    @Published var scoreRecords: [ScoreRecord]
    @Published var albumPhotos: [AlbumPhoto]
    @Published var classInfo: ClassInfo
    @Published var exams: [Exam]
    @Published var notifications: [NotificationItem]
    @Published var albumFolders: [AlbumFolder]
    
    @Published var currentDutyIndex: Int = 0
    
    private var cancellables = Set<AnyCancellable>()
    private let dataManager = DataManager.shared
    
    init() {
        if DataManager.shared.hasSavedData {
            self.students = DataManager.shared.loadStudents() ?? MockData.shared.students
            self.courses = DataManager.shared.loadCourses() ?? MockData.shared.courses
            self.dutyGroups = DataManager.shared.loadDutyGroups() ?? MockData.shared.dutyGroups
            self.todos = DataManager.shared.loadTodos() ?? MockData.shared.todos
            self.scoreRecords = DataManager.shared.loadScores() ?? MockData.shared.scoreRecords
            self.albumPhotos = DataManager.shared.loadAlbumPhotos() ?? MockData.shared.albumPhotos
            self.classInfo = DataManager.shared.loadClassInfo() ?? .default
            self.exams = DataManager.shared.loadExams() ?? []
            self.notifications = DataManager.shared.loadNotifications() ?? []
            self.albumFolders = DataManager.shared.loadAlbumFolders() ?? MockData.shared.albumFolders
        } else {
            let mock = MockData.shared
            self.students = mock.students
            self.courses = mock.courses
            self.dutyGroups = mock.dutyGroups
            self.todos = mock.todos
            self.scoreRecords = mock.scoreRecords
            self.albumPhotos = mock.albumPhotos
            self.classInfo = .default
            self.exams = []
            self.notifications = []
            self.albumFolders = mock.albumFolders
        }
        setupAutoSave()
    }
    
    private func setupAutoSave() {
        $students.dropFirst().debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] in self?.dataManager.saveStudents($0) }.store(in: &cancellables)
        $scoreRecords.dropFirst().debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] in self?.dataManager.saveScores($0) }.store(in: &cancellables)
        $courses.dropFirst().debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] in self?.dataManager.saveCourses($0) }.store(in: &cancellables)
        $dutyGroups.dropFirst().debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] in self?.dataManager.saveDutyGroups($0) }.store(in: &cancellables)
        $todos.dropFirst().debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] in self?.dataManager.saveTodos($0) }.store(in: &cancellables)
        $albumPhotos.dropFirst().debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] in self?.dataManager.saveAlbumPhotos($0) }.store(in: &cancellables)
        $classInfo.dropFirst().debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] in self?.dataManager.saveClassInfo($0) }.store(in: &cancellables)
        $exams.dropFirst().debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] in self?.dataManager.saveExams($0) }.store(in: &cancellables)
        $notifications.dropFirst().debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] in self?.dataManager.saveNotifications($0) }.store(in: &cancellables)
        $albumFolders.dropFirst().debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] in self?.dataManager.saveAlbumFolders($0) }.store(in: &cancellables)
    }
    
    func resetToMockData() {
        dataManager.clearAllData()
        let mock = MockData.shared
        students = mock.students
        courses = mock.courses
        dutyGroups = mock.dutyGroups
        todos = mock.todos
        scoreRecords = mock.scoreRecords
        albumPhotos = mock.albumPhotos
        classInfo = .default
        exams = []
        notifications = []
        albumFolders = mock.albumFolders
    }
    
    // MARK: - 学生
    func studentName(for id: UUID) -> String { students.first { $0.id == id }?.name ?? "未知" }
    func students(in group: Int) -> [Student] { students.filter { $0.groupNumber == group } }
    func students(inRow row: Int) -> [Student] { students.filter { $0.seatRow == row }.sorted { $0.seatCol < $1.seatCol } }
    func deleteStudent(_ student: Student) {
        students.removeAll { $0.id == student.id }
        scoreRecords.removeAll { $0.studentId == student.id }
    }
    
    // MARK: - 成绩
    func scores(for studentId: UUID, examName: String) -> [ScoreRecord] {
        scoreRecords.filter { $0.studentId == studentId && $0.examName == examName }
    }
    func averageScore(subject: String, examName: String) -> Double {
        let records = scoreRecords.filter { $0.subject == subject && $0.examName == examName }
        guard !records.isEmpty else { return 0 }
        return records.reduce(0) { $0 + $1.score } / Double(records.count)
    }
    func pendingScoreCount() -> Int {
        // 找到最近一次考试，计算该考试中待录成绩数
        guard let latestExam = exams.sorted(by: { $0.date > $1.date }).first else {
            // 没有考试时，按班级科目数估算
            return max(0, students.count * classInfo.subjects.count - scoreRecords.count)
        }
        let expected = students.count * latestExam.subjects.count
        let recorded = scoreRecords.filter { $0.examName == latestExam.name }.count
        return max(0, expected - recorded)
    }
    func totalRanking(for examName: String) -> [(student: Student, total: Double, average: Double, rank: Int)] {
        var result: [(student: Student, total: Double, average: Double, rank: Int)] = []
        for student in students {
            let scores = scoreRecords.filter { $0.studentId == student.id && $0.examName == examName }
            let total = scores.reduce(0) { $0 + $1.score }
            let average = scores.isEmpty ? 0 : total / Double(scores.count)
            result.append((student: student, total: total, average: average, rank: 0))
        }
        result.sort { $0.total > $1.total }
        for i in 0..<result.count { result[i].rank = i + 1 }
        return result
    }
    
    // MARK: - 考试
    func addExam(name: String, type: Exam.ExamType, subjects: [String], date: Date = Date()) {
        exams.append(Exam(name: name, type: type, date: date, subjects: subjects))
    }
    func deleteExam(_ exam: Exam) {
        exams.removeAll { $0.id == exam.id }
        scoreRecords.removeAll { $0.examName == exam.name }
    }
    func exams(ofType type: Exam.ExamType?) -> [Exam] {
        guard let type = type else { return exams }
        return exams.filter { $0.type == type }
    }
    
    // MARK: - 课程
    func courses(for dayOfWeek: Int) -> [Course] {
        courses.filter { $0.dayOfWeek == dayOfWeek }.sorted { $0.period < $1.period }
    }
    func course(for dayOfWeek: Int, period: Int) -> Course? {
        courses.first { $0.dayOfWeek == dayOfWeek && $0.period == period }
    }
    func myCourses(for dayOfWeek: Int) -> [Course] {
        courses.filter { $0.dayOfWeek == dayOfWeek && isMyCourse($0) }.sorted { $0.period < $1.period }
    }
    // 班主任教的科目（默认语文+英语，可根据实际修改）
    var mySubjects: [String] { ["语文", "英语"] }
    func isMyCourse(_ course: Course) -> Bool {
        course.teacher == classInfo.headTeacher || mySubjects.contains(course.subject)
    }
    
    // MARK: - 值日
    var currentDutyGroup: DutyGroup? {
        guard currentDutyIndex < dutyGroups.count else { return nil }
        return dutyGroups[currentDutyIndex]
    }
    func nextDutyGroup() { currentDutyIndex = (currentDutyIndex + 1) % max(dutyGroups.count, 1) }
    func dutyStudentNames(for group: DutyGroup) -> String {
        group.studentIds.map { studentName(for: $0) }.joined(separator: "、")
    }
    
    // MARK: - 待办
    func toggleTodo(_ todo: TodoItem) {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) { todos[index].isCompleted.toggle() }
    }
    func addTodo(title: String, priority: TodoItem.Priority = .medium, relatedInfo: String? = nil) {
        todos.append(TodoItem(title: title, priority: priority, relatedInfo: relatedInfo))
    }
    func deleteTodo(_ todo: TodoItem) { todos.removeAll { $0.id == todo.id } }
    var pendingTodos: [TodoItem] { todos.filter { !$0.isCompleted } }
    
    // MARK: - 座位
    func studentAt(row: Int, col: Int) -> Student? { students.first { $0.seatRow == row && $0.seatCol == col } }
    func updateSeat(studentId: UUID, row: Int, col: Int) {
        if let index = students.firstIndex(where: { $0.id == studentId }) {
            students[index].seatRow = row
            students[index].seatCol = col
        }
    }
    
    // MARK: - 通知
    func sendNotification(title: String, content: String, target: String = "全班") {
        notifications.insert(NotificationItem(title: title, content: content, target: target), at: 0)
    }
    func togglePin(_ notification: NotificationItem) {
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) { notifications[index].isPinned.toggle() }
    }
    func markAsRead(_ notification: NotificationItem) {
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) { notifications[index].isRead = true }
    }
    func deleteNotification(_ notification: NotificationItem) { notifications.removeAll { $0.id == notification.id } }
    var pinnedNotifications: [NotificationItem] { notifications.filter { $0.isPinned } }
    var unreadCount: Int { notifications.filter { !$0.isRead }.count }
    
    // MARK: - 相册
    func addPhoto(_ image: UIImage, title: String, description: String = "", folderId: UUID? = nil) {
        let photoId = UUID()
        _ = dataManager.saveImage(image, for: photoId)
        let imageData = dataManager.loadImageData(for: photoId)
        albumPhotos.append(AlbumPhoto(id: photoId, imageName: title, imageData: imageData, title: title, description: description))
        if let folderId = folderId, let index = albumFolders.firstIndex(where: { $0.id == folderId }) {
            albumFolders[index].photoIds.append(photoId)
        }
    }
    func deletePhoto(_ photo: AlbumPhoto) {
        albumPhotos.removeAll { $0.id == photo.id }
        dataManager.deleteImage(for: photo.id)
        for i in 0..<albumFolders.count { albumFolders[i].photoIds.removeAll { $0 == photo.id } }
    }
    func loadImage(for photo: AlbumPhoto) -> UIImage? {
        if let data = photo.imageData { return UIImage(data: data) }
        return dataManager.loadImage(for: photo.id)
    }
    func photos(in folder: AlbumFolder) -> [AlbumPhoto] { albumPhotos.filter { folder.photoIds.contains($0.id) } }
    func addAlbumFolder(name: String, category: String, coverGradient: [String]) {
        albumFolders.append(AlbumFolder(name: name, category: category, coverGradient: coverGradient))
    }
    func toggleFolderPin(_ folder: AlbumFolder) {
        if let index = albumFolders.firstIndex(where: { $0.id == folder.id }) { albumFolders[index].isPinned.toggle() }
    }
    
    // MARK: - 日期
    var todayString: String {
        let f = DateFormatter(); f.locale = Locale(identifier: "zh_CN"); f.dateFormat = "M月d日"
        return f.string(from: Date())
    }
    var weekdayString: String {
        let f = DateFormatter(); f.locale = Locale(identifier: "zh_CN"); f.dateFormat = "EEEE"
        return f.string(from: Date())
    }
    // 今天是星期几（1=周一, 2=周二, ..., 7=周日）
    var todayDayOfWeek: Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        // Calendar: 1=周日, 2=周一, ..., 7=周六
        // 转换为: 1=周一, ..., 5=周五, 6=周六, 7=周日
        return (weekday + 5) % 7 + 1
    }
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour { case 5..<12: return "上午好"; case 12..<14: return "中午好"; case 14..<18: return "下午好"; default: return "晚上好" }
    }
    var nextMonday: Date {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        let days = (9 - weekday) % 7
        return calendar.date(byAdding: .day, value: days == 0 ? 7 : days, to: Date())!
    }
    var nextMondayString: String {
        let f = DateFormatter(); f.locale = Locale(identifier: "zh_CN"); f.dateFormat = "M月d日"
        return f.string(from: nextMonday)
    }
}
