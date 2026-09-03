import Foundation

// 示例数据
class MockData {
    static let shared = MockData()
    
    // 35名学生
    var students: [Student] {
        let names = [
            "张伟", "李阳", "刘洋", "赵宇", "王磊", "杨浩", "陈杰",
            "黄敏", "周婷", "吴芳", "徐丽", "孙静", "马超", "朱强",
            "胡军", "郭鹏", "林峰", "何雪", "高燕", "罗琳",
            "梁宇", "宋佳", "郑凯", "谢涛", "韩雪", "唐亮", "冯悦",
            "于洋", "董洁", "萧然", "程曦", "曹阳", "袁梦", "邓超",
            "许晴"
        ]
        
        var result: [Student] = []
        // 郑州市各区域经纬度
        let districts: [(name: String, lat: Double, lon: Double)] = [
            ("金水区", 34.80, 113.67),
            ("二七区", 34.72, 113.63),
            ("中原区", 34.74, 113.58),
            ("管城区", 34.75, 113.68),
            ("惠济区", 34.86, 113.62),
            ("郑东新区", 34.76, 113.75),
            ("高新区", 34.83, 113.52)
        ]
        
        for (index, name) in names.enumerated() {
            let group = (index / 7) + 1
            let row = (index % 7) + 1
            let col = (index / 7) + 1
            let gender: Student.Gender = index % 3 == 1 ? .female : .male
            let district = districts[index % districts.count]
            // 加随机偏移，模拟同区域不同位置
            let latOffset = Double.random(in: -0.02...0.02)
            let lonOffset = Double.random(in: -0.02...0.02)
            let student = Student(
                name: name,
                studentNumber: String(format: "2026%03d", index + 1),
                gender: gender,
                age: 16,
                phone: "138\(String(format: "%08d", 10000000 + index))",
                parentPhone: "139\(String(format: "%08d", 20000000 + index))",
                address: "郑州市\(district.name)\(index + 1)号院",
                groupNumber: group,
                seatRow: row,
                seatCol: col,
                dormitory: index < 18 ? "男生宿舍\((index % 3) + 1)室" : "女生宿舍\((index % 3) + 1)室",
                notes: index == 0 ? "班长" : (index == 5 ? "学习委员" : ""),
                latitude: district.lat + latOffset,
                longitude: district.lon + lonOffset
            )
            result.append(student)
        }
        return result
    }
    
    // 课程表（周一到周五，每天8节）
    var courses: [Course] {
        let subjects = ["语文", "数学", "英语", "物理", "化学", "生物", "政治", "历史", "地理", "体育", "音乐", "美术", "自习"]
        let times = [
            ("08:00", "08:45"), ("08:55", "09:40"), ("10:00", "10:45"), ("10:55", "11:40"),
            ("14:00", "14:45"), ("14:55", "15:40"), ("16:00", "16:45"), ("16:55", "17:40")
        ]
        
        var result: [Course] = []
        // 周一课程
        let mondaySubjects = ["语文", "数学", "英语", "物理", "化学", "语文", "体育", "自习"]
        // 周二
        let tuesdaySubjects = ["数学", "语文", "英语", "化学", "物理", "数学", "音乐", "自习"]
        // 周三
        let wednesdaySubjects = ["英语", "语文", "数学", "生物", "政治", "英语", "美术", "自习"]
        // 周四
        let thursdaySubjects = ["物理", "数学", "语文", "历史", "地理", "物理", "体育", "自习"]
        // 周五
        let fridaySubjects = ["语文", "英语", "数学", "化学", "生物", "班会", "自习", "自习"]
        
        let weekSubjects = [mondaySubjects, tuesdaySubjects, wednesdaySubjects, thursdaySubjects, fridaySubjects]
        
        for day in 0..<5 {
            for period in 0..<8 {
                let (start, end) = times[period]
                let subject = weekSubjects[day][period]
                let teacher = subject == "语文" ? "段老师" : "\(subject)老师"
                let course = Course(
                    subject: subject,
                    dayOfWeek: day + 1,
                    period: period + 1,
                    startTime: start,
                    endTime: end,
                    classroom: "高一2班教室",
                    teacher: teacher
                )
                result.append(course)
            }
        }
        return result
    }
    
    // 值日组（5组，每组7人）
    var dutyGroups: [DutyGroup] {
        let students = self.students
        var groups: [DutyGroup] = []
        for i in 0..<5 {
            let start = i * 7
            let end = min(start + 7, students.count)
            let ids = Array(students[start..<end]).map { $0.id }
            groups.append(DutyGroup(groupNumber: i + 1, studentIds: ids))
        }
        return groups
    }
    
    // 待办事项
    var todos: [TodoItem] {
        [
            TodoItem(title: "录入月考数学成绩", priority: .high, relatedInfo: "满分：100 已录入：0/35"),
            TodoItem(title: "调整第三组座位", priority: .medium),
            TodoItem(title: "发布国庆放假通知", priority: .high),
            TodoItem(title: "批改周末语文作业", priority: .medium),
            TodoItem(title: "准备下周班会材料", priority: .low)
        ]
    }
    
    // 成绩记录（月考成绩）
    var scoreRecords: [ScoreRecord] {
        let students = self.students
        let subjects = ["语文", "数学", "英语", "物理", "化学"]
        var records: [ScoreRecord] = []
        
        for student in students {
            for subject in subjects {
                let score = Double.random(in: 60...98)
                records.append(ScoreRecord(
                    studentId: student.id,
                    subject: subject,
                    examName: "月考",
                    score: score,
                    fullScore: 100
                ))
            }
        }
        return records
    }
    
    // 相册照片
    var albumPhotos: [AlbumPhoto] {
        [
            AlbumPhoto(imageName: "photo1", title: "开学第一天", description: "同学们第一次见面"),
            AlbumPhoto(imageName: "photo2", title: "军训合影", description: "为期一周的军训结束"),
            AlbumPhoto(imageName: "photo3", title: "运动会", description: "班级获得团体第二名"),
            AlbumPhoto(imageName: "photo4", title: "元旦晚会", description: "同学们多才多艺"),
            AlbumPhoto(imageName: "photo5", title: "春游", description: "去植物园踏青"),
            AlbumPhoto(imageName: "photo6", title: "期中考试表彰", description: "表彰进步明显的同学")
        ]
    }
    
    // 相册分类
    var albumFolders: [AlbumFolder] {
        [
            AlbumFolder(
                name: "开学第一课",
                category: "班级活动",
                coverGradient: ["#FF6B6B", "#FFE66D"],
                date: Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 16)) ?? Date(),
                isPinned: true,
                photoIds: Array(albumPhotos.prefix(3).map { $0.id })
            ),
            AlbumFolder(
                name: "秋游",
                category: "学习日常",
                coverGradient: ["#FF8A5C", "#FFD93D"],
                date: Calendar.current.date(from: DateComponents(year: 2026, month: 6, day: 21)) ?? Date(),
                photoIds: Array(albumPhotos.dropFirst(3).prefix(2).map { $0.id })
            ),
            AlbumFolder(
                name: "元旦晚会",
                category: "荣誉墙",
                coverGradient: ["#667EEA", "#764BA2"],
                date: Calendar.current.date(from: DateComponents(year: 2026, month: 9, day: 20)) ?? Date(),
                photoIds: Array(albumPhotos.dropFirst(5).map { $0.id })
            )
        ]
    }
}
