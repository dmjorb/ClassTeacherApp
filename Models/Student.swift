import Foundation

// 学生模型
struct Student: Identifiable, Codable {
    let id: UUID
    var name: String
    var studentNumber: String      // 学号
    var gender: Gender
    var age: Int
    var phone: String              // 学生电话
    var parentPhone: String        // 家长电话
    var address: String            // 家庭住址
    var groupNumber: Int           // 小组编号
    var seatRow: Int               // 座位行
    var seatCol: Int               // 座位列
    var dormitory: String          // 宿舍号
    var notes: String              // 备注
    var latitude: Double?          // 家庭住址纬度
    var longitude: Double?         // 家庭住址经度
    
    enum Gender: String, Codable, CaseIterable {
        case male = "男"
        case female = "女"
    }
    
    init(id: UUID = UUID(), name: String, studentNumber: String, gender: Gender, age: Int, phone: String = "", parentPhone: String = "", address: String = "", groupNumber: Int, seatRow: Int, seatCol: Int, dormitory: String = "", notes: String = "", latitude: Double? = nil, longitude: Double? = nil) {
        self.id = id
        self.name = name
        self.studentNumber = studentNumber
        self.gender = gender
        self.age = age
        self.phone = phone
        self.parentPhone = parentPhone
        self.address = address
        self.groupNumber = groupNumber
        self.seatRow = seatRow
        self.seatCol = seatCol
        self.dormitory = dormitory
        self.notes = notes
        self.latitude = latitude
        self.longitude = longitude
    }
}

// 成绩记录
struct ScoreRecord: Identifiable, Codable {
    let id: UUID
    var studentId: UUID
    var subject: String
    var examName: String           // 考试名称，如"月考"
    var score: Double
    var fullScore: Double
    var classRank: Int?
    var gradeRank: Int?
    var examDate: Date
    
    init(id: UUID = UUID(), studentId: UUID, subject: String, examName: String, score: Double, fullScore: Double = 100, classRank: Int? = nil, gradeRank: Int? = nil, examDate: Date = Date()) {
        self.id = id
        self.studentId = studentId
        self.subject = subject
        self.examName = examName
        self.score = score
        self.fullScore = fullScore
        self.classRank = classRank
        self.gradeRank = gradeRank
        self.examDate = examDate
    }
}

// 课程
struct Course: Identifiable, Codable {
    let id: UUID
    var subject: String
    var dayOfWeek: Int             // 1=周一 ... 7=周日
    var period: Int                // 第几节
    var startTime: String
    var endTime: String
    var classroom: String
    var teacher: String
    
    init(id: UUID = UUID(), subject: String, dayOfWeek: Int, period: Int, startTime: String, endTime: String, classroom: String = "", teacher: String = "段老师") {
        self.id = id
        self.subject = subject
        self.dayOfWeek = dayOfWeek
        self.period = period
        self.startTime = startTime
        self.endTime = endTime
        self.classroom = classroom
        self.teacher = teacher
    }
}

// 值日组
struct DutyGroup: Identifiable, Codable {
    let id: UUID
    var groupNumber: Int
    var studentIds: [UUID]
    var dutyDate: Date?            // 值日日期，nil表示轮换
    
    init(id: UUID = UUID(), groupNumber: Int, studentIds: [UUID], dutyDate: Date? = nil) {
        self.id = id
        self.groupNumber = groupNumber
        self.studentIds = studentIds
        self.dutyDate = dutyDate
    }
}

// 待办事项
struct TodoItem: Identifiable, Codable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var dueDate: Date?
    var priority: Priority
    var relatedInfo: String?       // 关联信息，如"满分：100 已录入：0/35"
    
    enum Priority: String, Codable, CaseIterable {
        case high = "高"
        case medium = "中"
        case low = "低"
    }
    
    init(id: UUID = UUID(), title: String, isCompleted: Bool = false, dueDate: Date? = nil, priority: Priority = .medium, relatedInfo: String? = nil) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.priority = priority
        self.relatedInfo = relatedInfo
    }
}

// 相册照片
struct AlbumPhoto: Identifiable, Codable {
    let id: UUID
    var imageName: String          // 图片资源名（占位用）
    var imageData: Data?           // 真实图片数据
    var title: String
    var date: Date
    var description: String
    
    init(id: UUID = UUID(), imageName: String, imageData: Data? = nil, title: String, date: Date = Date(), description: String = "") {
        self.id = id
        self.imageName = imageName
        self.imageData = imageData
        self.title = title
        self.date = date
        self.description = description
    }
}

// 班级信息
struct ClassInfo: Codable {
    var className: String
    var grade: String
    var headTeacher: String
    var studentCount: Int
    var subjects: [String]
    
    static let `default` = ClassInfo(
        className: "高一（2）班",
        grade: "高一",
        headTeacher: "段老师",
        studentCount: 35,
        subjects: ["语文", "数学", "英语", "物理", "化学", "生物", "政治", "历史", "地理"]
    )
}

// 考试
struct Exam: Identifiable, Codable {
    let id: UUID
    var name: String              // 考试名称，如"第一次月考"
    var type: ExamType            // 考试类型
    var semester: String          // 学期，如"第1学期"
    var date: Date                // 考试日期
    var subjects: [String]        // 考试科目
    var isCompleted: Bool         // 是否全部录入完成
    
    enum ExamType: String, Codable, CaseIterable {
        case unitTest = "单元测"
        case monthly = "月考"
        case midterm = "期中考"
        case final = "期末考"
    }
    
    init(id: UUID = UUID(), name: String, type: ExamType, semester: String = "第1学期", date: Date = Date(), subjects: [String] = [], isCompleted: Bool = false) {
        self.id = id
        self.name = name
        self.type = type
        self.semester = semester
        self.date = date
        self.subjects = subjects
        self.isCompleted = isCompleted
    }
}

// 通知
class NotificationItem: Identifiable, Codable, ObservableObject {
    let id: UUID
    var title: String
    var content: String
    var date: Date
    var target: String            // 接收范围，如"全班"、"第1组"
    var isPinned: Bool            // 是否置顶
    var isRead: Bool              // 是否已读
    
    init(id: UUID = UUID(), title: String, content: String, date: Date = Date(), target: String = "全班", isPinned: Bool = false, isRead: Bool = false) {
        self.id = id
        self.title = title
        self.content = content
        self.date = date
        self.target = target
        self.isPinned = isPinned
        self.isRead = isRead
    }
}

// 相册分类
struct AlbumFolder: Identifiable, Codable {
    let id: UUID
    var name: String              // 相册名称，如"班级活动"
    var category: String          // 分类，如"班级活动"、"学习日常"、"荣誉墙"
    var coverGradient: [String]   // 封面渐变色（hex颜色数组）
    var date: Date                // 日期
    var isPinned: Bool            // 是否置顶
    var photoIds: [UUID]          // 照片ID列表
    
    init(id: UUID = UUID(), name: String, category: String = "班级活动", coverGradient: [String] = ["#FF6B6B", "#FFE66D"], date: Date = Date(), isPinned: Bool = false, photoIds: [UUID] = []) {
        self.id = id
        self.name = name
        self.category = category
        self.coverGradient = coverGradient
        self.date = date
        self.isPinned = isPinned
        self.photoIds = photoIds
    }
}
