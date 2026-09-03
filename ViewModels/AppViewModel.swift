import Foundation
import SwiftUI
import Combine

// 全局应用状态：真数据、本地持久化、无假数据
class AppViewModel: ObservableObject {
    // MARK: - 数据
    @Published var classInfo: ClassInfo
    @Published var students: [Student]
    @Published var exams: [Exam]
    @Published var scoreRecords: [ScoreRecord]
    @Published var courses: [Course]
    @Published var dutyGroups: [DutyGroup]
    @Published var todos: [TodoItem]

    @Published var currentDutyIndex: Int = 0

    private var cancellables = Set<AnyCancellable>()
    private let dataManager = DataManager.shared

    init() {
        if DataManager.shared.hasSavedData {
            self.classInfo = DataManager.shared.loadClassInfo() ?? .default
            self.students = DataManager.shared.loadStudents() ?? []
            self.exams = DataManager.shared.loadExams() ?? []
            self.scoreRecords = DataManager.shared.loadScores() ?? []
            self.courses = DataManager.shared.loadCourses() ?? []
            self.dutyGroups = DataManager.shared.loadDutyGroups() ?? []
            self.todos = DataManager.shared.loadTodos() ?? []
        } else {
            self.classInfo = .default
            self.students = []
            self.exams = []
            self.scoreRecords = []
            self.courses = []
            self.dutyGroups = []
            self.todos = []
        }
        setupAutoSave()
    }

    // MARK: - 自动保存
    private func setupAutoSave() {
        $classInfo.dropFirst().debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] in self?.dataManager.saveClassInfo($0) }.store(in: &cancellables)
        $students.dropFirst().debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] in self?.dataManager.saveStudents($0) }.store(in: &cancellables)
        $exams.dropFirst().debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] in self?.dataManager.saveExams($0) }.store(in: &cancellables)
        $scoreRecords.dropFirst().debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] in self?.dataManager.saveScores($0) }.store(in: &cancellables)
        $courses.dropFirst().debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] in self?.dataManager.saveCourses($0) }.store(in: &cancellables)
        $dutyGroups.dropFirst().debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] in self?.dataManager.saveDutyGroups($0) }.store(in: &cancellables)
        $todos.dropFirst().debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] in self?.dataManager.saveTodos($0) }.store(in: &cancellables)
    }

    // MARK: - 班级
    func updateClassInfo(className: String, grade: String, headTeacher: String, subjects: [String]) {
        classInfo = ClassInfo(className: className, grade: grade, headTeacher: headTeacher, subjects: subjects.isEmpty ? classInfo.subjects : subjects)
    }

    // MARK: - 学生
    func addStudent(_ student: Student) { students.append(student) }
    func deleteStudent(_ student: Student) {
        students.removeAll { $0.id == student.id }
        scoreRecords.removeAll { $0.studentId == student.id }
    }
    func updateStudent(_ student: Student) {
        if let i = students.firstIndex(where: { $0.id == student.id }) { students[i] = student }
    }
    func studentName(for id: UUID) -> String { students.first { $0.id == id }?.name ?? "未知" }
    func student(id: UUID) -> Student? { students.first { $0.id == id } }

    // MARK: - 考试
    func addExam(name: String, type: Exam.ExamType, subjects: [String]) {
        exams.append(Exam(name: name, type: type, subjects: subjects))
    }
    func deleteExam(_ exam: Exam) {
        exams.removeAll { $0.id == exam.id }
        scoreRecords.removeAll { $0.examId == exam.id }
    }
    func examName(id: UUID) -> String { exams.first { $0.id == id }?.name ?? "未知考试" }

    // MARK: - 成绩
    // 某考试某科目的成绩（按学生顺序）
    func scores(for examId: UUID, subject: String) -> [ScoreRecord] {
        scoreRecords.filter { $0.examId == examId && $0.subject == subject }
    }
    // 保存/更新单个学生的成绩
    func setScore(studentId: UUID, examId: UUID, subject: String, score: Double) {
        if let i = scoreRecords.firstIndex(where: { $0.studentId == studentId && $0.examId == examId && $0.subject == subject }) {
            scoreRecords[i].score = score
        } else {
            scoreRecords.append(ScoreRecord(studentId: studentId, subject: subject, examId: examId, score: score))
        }
    }
    // 某学生的总分
    func totalScore(of studentId: UUID, examId: UUID) -> Double {
        scoreRecords.filter { $0.studentId == studentId && $0.examId == examId }.reduce(0) { $0 + $1.score }
    }
    // 某科目平均分
    func averageScore(examId: UUID, subject: String) -> Double {
        let records = scores(for: examId, subject: subject)
        guard !records.isEmpty else { return 0 }
        return records.reduce(0) { $0 + $1.score } / Double(records.count)
    }
    // 某科目及格率（>=60 占比）
    func passRate(examId: UUID, subject: String) -> Double {
        let records = scores(for: examId, subject: subject)
        guard !records.isEmpty else { return 0 }
        let pass = records.filter { $0.score >= 60 }.count
        return Double(pass) / Double(records.count) * 100
    }
    // 总分排名
    func totalRanking(for examId: UUID) -> [(student: Student, total: Double)] {
        students
            .map { (student: $0, total: totalScore(of: $0.id, examId: examId)) }
            .filter { $0.total > 0 }
            .sorted { $0.total > $1.total }
    }

    // MARK: - 课程
    func courses(for dayOfWeek: Int) -> [Course] {
        courses.filter { $0.dayOfWeek == dayOfWeek }.sorted { $0.period < $1.period }
    }
    func addCourse(_ course: Course) { courses.append(course) }
    func deleteCourse(_ course: Course) { courses.removeAll { $0.id == course.id } }
    // 今天星期几（1=周一 ... 7=周日）
    var todayDayOfWeek: Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return (weekday + 5) % 7 + 1
    }
    func todayCourses() -> [Course] { courses(for: todayDayOfWeek) }

    // MARK: - 值日
    var currentDutyGroup: DutyGroup? {
        guard !dutyGroups.isEmpty else { return nil }
        return dutyGroups[currentDutyIndex % dutyGroups.count]
    }
    func nextDutyGroup() {
        guard !dutyGroups.isEmpty else { return }
        currentDutyIndex = (currentDutyIndex + 1) % dutyGroups.count
    }
    func addDutyGroup(_ group: DutyGroup) { dutyGroups.append(group) }
    func deleteDutyGroup(_ group: DutyGroup) { dutyGroups.removeAll { $0.id == group.id } }
    func dutyStudentNames(of group: DutyGroup) -> String {
        group.studentIds.compactMap { student(id: $0)?.name }.joined(separator: "、")
    }

    // MARK: - 待办
    func addTodo(title: String) {
        todos.append(TodoItem(title: title))
    }
    func toggleTodo(_ todo: TodoItem) {
        if let i = todos.firstIndex(where: { $0.id == todo.id }) { todos[i].isCompleted.toggle() }
    }
    func deleteTodo(_ todo: TodoItem) { todos.removeAll { $0.id == todo.id } }
    var pendingTodos: [TodoItem] { todos.filter { !$0.isCompleted } }

    // MARK: - 数据管理
    func clearAllData() {
        dataManager.clearAllData()
        classInfo = .default
        students = []
        exams = []
        scoreRecords = []
        courses = []
        dutyGroups = []
        todos = []
        currentDutyIndex = 0
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
}
