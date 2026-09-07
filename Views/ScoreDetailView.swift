import SwiftUI
import Charts

// 成绩录入详情 — 带图表版
struct ScoreDetailView: View {
    @EnvironmentObject var viewModel: AppViewModel
    let exam: Exam

    @State private var selectedSubject: String
    @State private var showingRanking = false
    @State private var showingChartDetail = false

    init(exam: Exam) {
        self.exam = exam
        _selectedSubject = State(initialValue: exam.subjects.first ?? "")
    }

    private var subjectBinding: Binding<String> {
        Binding(
            get: {
                if exam.subjects.contains(selectedSubject) { return selectedSubject }
                return exam.subjects.first ?? ""
            },
            set: { selectedSubject = $0 }
        )
    }

    private var records: [ScoreRecord] {
        guard !selectedSubject.isEmpty else { return [] }
        return viewModel.scores(for: exam.id, subject: selectedSubject)
    }

    // 分数分布数据
    private var scoreDistribution: [ScoreBucket] {
        let buckets = [
            ScoreBucket(range: "0-59", label: "不及格", min: 0, max: 59.99, count: 0),
            ScoreBucket(range: "60-69", label: "及格", min: 60, max: 69.99, count: 0),
            ScoreBucket(range: "70-79", label: "中等", min: 70, max: 79.99, count: 0),
            ScoreBucket(range: "80-89", label: "良好", min: 80, max: 89.99, count: 0),
            ScoreBucket(range: "90-100", label: "优秀", min: 90, max: 1000, count: 0)
        ]
        return buckets.map { bucket in
            var b = bucket
            b.count = records.filter { $0.score >= bucket.min && $0.score <= bucket.max }.count
            return b
        }
    }

    // 班级均分趋势（同科目历次考试）
    private var averageTrend: [TrendPoint] {
        let sameSubjectExams = viewModel.exams
            .filter { $0.subjects.contains(selectedSubject) }
            .sorted { $0.date < $1.date }
        return sameSubjectExams.map { exam in
            TrendPoint(
                examName: exam.name,
                date: exam.date,
                average: viewModel.averageScore(examId: exam.id, subject: selectedSubject)
            )
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 科目选择
                if exam.subjects.count > 1 {
                    Picker("科目", selection: subjectBinding) {
                        ForEach(exam.subjects, id: \.self) { subject in
                            Text(subject).tag(subject)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                }

                // 统计卡片
                statsBar
                    .padding(.horizontal, 18)

                // 分数分布图表
                if !records.isEmpty {
                    scoreDistributionChart
                        .padding(.horizontal, 18)
                }

                // 班级趋势图表
                if averageTrend.count >= 2 {
                    averageTrendChart
                        .padding(.horizontal, 18)
                }

                // 成绩录入列表
                if viewModel.students.isEmpty {
                    EmptyStateView(
                        systemImage: "person.2",
                        title: "还没有学生",
                        message: "请先在「学生名册」中添加学生"
                    )
                    .padding(.top, 40)
                } else {
                    VStack(spacing: 8) {
                        ForEach(viewModel.students) { student in
                            ScoreInputRow(
                                student: student,
                                examId: exam.id,
                                subject: selectedSubject,
                                initialScore: score(of: student.id)
                            )
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 32)
                    .id(selectedSubject)
                }
            }
        }
        .background(AppTheme.Colors.background)
        .navigationTitle(exam.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingRanking = true
                    } label: {
                        Label("总分排名", systemImage: "list.number")
                    }
                    Button {
                        printScores()
                    } label: {
                        Label("打印成绩单", systemImage: "printer")
                    }
                    .disabled(records.isEmpty)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .disabled(viewModel.students.isEmpty)
            }
        }
        .sheet(isPresented: $showingRanking) {
            NavigationStack {
                RankingView(exam: exam)
            }
        }
    }

    private func printScores() {
        let students = viewModel.students.map { student -> (name: String, number: String, scores: [Double?]) in
            let scores = exam.subjects.map { subject -> Double? in
                viewModel.scores(for: exam.id, subject: subject)
                    .first(where: { $0.studentId == student.id })?.score
            }
            return (student.name, student.studentNumber, scores)
        }
        PrintService.shared.printScores(
            examName: exam.name,
            className: viewModel.classInfo.className,
            subjects: exam.subjects,
            students: students
        )
    }

    private func score(of studentId: UUID) -> String {
        guard let record = records.first(where: { $0.studentId == studentId }) else { return "" }
        return record.score.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(record.score)) : String(record.score)
    }

    // MARK: - 统计栏
    private var statsBar: some View {
        HStack(spacing: 10) {
            StatCard(value: "\(records.count)", label: "已录入", systemImage: "checkmark.circle", color: .blue)
            StatCard(value: String(format: "%.1f", viewModel.averageScore(examId: exam.id, subject: selectedSubject)), label: "平均分", systemImage: "sum", color: AppTheme.Colors.accent)
            StatCard(value: String(format: "%.0f%%", viewModel.passRate(examId: exam.id, subject: selectedSubject)), label: "及格率", systemImage: "checkmark.seal", color: .green)
        }
    }

    // MARK: - 分数分布柱状图
    private var scoreDistributionChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("分数分布")
                    .font(AppTheme.Fonts.title3)
                    .foregroundColor(AppTheme.Colors.primaryText)
                Spacer()
                Text("\(records.count) 人")
                    .font(AppTheme.Fonts.caption)
                    .foregroundColor(AppTheme.Colors.tertiaryText)
            }

            Chart(scoreDistribution) { bucket in
                BarMark(
                    x: .value("分数段", bucket.label),
                    y: .value("人数", bucket.count)
                )
                .cornerRadius(6)
                .foregroundStyle(
                    bucket.range == "90-100" ? AppTheme.Colors.accent :
                    bucket.range == "0-59" ? .red :
                    Color.gray.opacity(0.5)
                )
                .annotation(position: .top) {
                    if bucket.count > 0 {
                        Text("\(bucket.count)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AppTheme.Colors.primaryText)
                    }
                }
            }
            .frame(height: 160)
            .chartXAxis {
                AxisMarks(position: .bottom) { _ in
                    AxisGridLine().foregroundStyle(Color.clear)
                    AxisTick().foregroundStyle(Color.clear)
                    AxisValueLabel()
                        .font(.system(size: 10))
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                }
            }
            .chartYAxis(.hidden)
            .padding(.vertical, 8)
        }
        .padding(16)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                .stroke(AppTheme.Colors.separator, lineWidth: 0.5)
        )
        .rdShadow(AppTheme.Shadows.sm)
    }

    // MARK: - 班级均分趋势图
    private var averageTrendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("班级均分趋势")
                    .font(AppTheme.Fonts.title3)
                    .foregroundColor(AppTheme.Colors.primaryText)
                Spacer()
                Text("\(selectedSubject)")
                    .font(AppTheme.Fonts.caption)
                    .foregroundColor(AppTheme.Colors.tertiaryText)
            }

            Chart(averageTrend) { point in
                LineMark(
                    x: .value("考试", point.examName),
                    y: .value("均分", point.average)
                )
                .foregroundStyle(AppTheme.Colors.accent)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))

                PointMark(
                    x: .value("考试", point.examName),
                    y: .value("均分", point.average)
                )
                .foregroundStyle(.white)
                .symbolSize(50)

                PointMark(
                    x: .value("考试", point.examName),
                    y: .value("均分", point.average)
                )
                .foregroundStyle(AppTheme.Colors.accent)
                .symbolSize(30)

                AreaMark(
                    x: .value("考试", point.examName),
                    y: .value("均分", point.average)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppTheme.Colors.accent.opacity(0.2), AppTheme.Colors.accent.opacity(0.02)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
            }
            .frame(height: 160)
            .chartXAxis {
                AxisMarks(position: .bottom) { _ in
                    AxisGridLine().foregroundStyle(Color.clear)
                    AxisTick().foregroundStyle(Color.clear)
                    AxisValueLabel()
                        .font(.system(size: 10))
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine().foregroundStyle(AppTheme.Colors.separator)
                    AxisTick().foregroundStyle(Color.clear)
                    AxisValueLabel()
                        .font(.system(size: 10))
                        .foregroundStyle(AppTheme.Colors.tertiaryText)
                }
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .padding(.vertical, 8)
        }
        .padding(16)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                .stroke(AppTheme.Colors.separator, lineWidth: 0.5)
        )
        .rdShadow(AppTheme.Shadows.sm)
    }
}

// MARK: - 图表数据模型
struct ScoreBucket: Identifiable {
    let id = UUID()
    var range: String
    var label: String
    var min: Double
    var max: Double
    var count: Int
}

struct TrendPoint: Identifiable {
    let id = UUID()
    var examName: String
    var date: Date
    var average: Double
}

// 单个学生成绩输入行
struct ScoreInputRow: View {
    @EnvironmentObject var viewModel: AppViewModel
    let student: Student
    let examId: UUID
    let subject: String
    let initialScore: String

    @State private var text: String

    init(student: Student, examId: UUID, subject: String, initialScore: String) {
        self.student = student
        self.examId = examId
        self.subject = subject
        self.initialScore = initialScore
        _text = State(initialValue: initialScore)
    }

    private var scoreValue: Double? {
        guard let v = Double(text), !text.isEmpty else { return nil }
        return v
    }

    private var scoreColor: Color {
        guard let v = scoreValue else { return AppTheme.Colors.tertiaryText }
        if v >= 90 { return .green }
        if v >= 60 { return AppTheme.Colors.accent }
        return .red
    }

    var body: some View {
        HStack(spacing: 12) {
            StudentAvatar(name: student.name, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(student.name)
                    .font(AppTheme.Fonts.body.weight(.medium))
                    .foregroundColor(AppTheme.Colors.primaryText)
                Text("#\(student.studentNumber)")
                    .font(AppTheme.Fonts.caption2)
                    .foregroundColor(AppTheme.Colors.tertiaryText)
            }
            Spacer()
            TextField("分数", text: $text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppTheme.Colors.subtleBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button, style: .continuous))
                .font(.system(size: 16, weight: .bold).monospacedDigit())
                .foregroundColor(scoreColor)
                .onChange(of: text) { newValue in
                    let cleaned = newValue.filter { "0123456789.".contains($0) }
                    if cleaned != newValue { text = cleaned }
                    if cleaned.isEmpty {
                        viewModel.removeScore(studentId: student.id, examId: examId, subject: subject)
                    } else {
                        saveIfValid(cleaned)
                    }
                }
        }
        .padding(14)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.element, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.element, style: .continuous)
                .stroke(AppTheme.Colors.separator, lineWidth: 0.5)
        )
    }

    private func saveIfValid(_ value: String) {
        guard let score = Double(value), (0...1000).contains(score) else { return }
        viewModel.setScore(studentId: student.id, examId: examId, subject: subject, score: score)
    }
}

// 总分排名
struct RankingView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    let exam: Exam

    var body: some View {
        let ranking = viewModel.totalRanking(for: exam.id)
        Group {
            if ranking.isEmpty {
                EmptyStateView(
                    systemImage: "list.number",
                    title: "暂无成绩",
                    message: "录入成绩后才能查看排名"
                )
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        // 前三名领奖台
                        if ranking.count >= 3 {
                            podiumView(of: Array(ranking.prefix(3)))
                                .padding(.top, 16)
                        }

                        // 完整排名
                        VStack(spacing: 0) {
                            ForEach(Array(ranking.enumerated()), id: \.element.student.id) { index, item in
                                HStack(spacing: 12) {
                                    ZStack {
                                        if index < 3 {
                                            Circle()
                                                .fill(podiumColor(index: index))
                                                .frame(width: 32, height: 32)
                                            Text("\(index + 1)")
                                                .font(.system(size: 14, weight: .heavy))
                                                .foregroundColor(.white)
                                        } else {
                                            Text("\(index + 1)")
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundColor(AppTheme.Colors.tertiaryText)
                                                .frame(width: 32)
                                        }
                                    }
                                    StudentAvatar(name: item.student.name, size: 36)
                                    Text(item.student.name)
                                        .font(AppTheme.Fonts.body.weight(.medium))
                                        .foregroundColor(AppTheme.Colors.primaryText)
                                    Spacer()
                                    Text(String(format: "%.0f", item.total))
                                        .font(.system(size: 17, weight: .heavy).monospacedDigit())
                                        .foregroundColor(AppTheme.Colors.accent)
                                    Text("分")
                                        .font(AppTheme.Fonts.caption)
                                        .foregroundColor(AppTheme.Colors.tertiaryText)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                if index < ranking.count - 1 {
                                    Divider()
                                        .background(AppTheme.Colors.separator)
                                        .padding(.leading, 64)
                                }
                            }
                        }
                        .background(AppTheme.Colors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card, style: .continuous)
                                .stroke(AppTheme.Colors.separator, lineWidth: 0.5)
                        )
                        .padding(.horizontal, 18)
                        .padding(.bottom, 32)
                    }
                }
                .background(AppTheme.Colors.background)
            }
        }
        .navigationTitle("总分排名")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("完成") { dismiss() }
            }
        }
    }

    private func podiumColor(index: Int) -> Color {
        switch index {
        case 0: return Color(red: 0.95, green: 0.75, blue: 0.15)  // 金
        case 1: return Color(red: 0.65, green: 0.65, blue: 0.67)   // 银
        case 2: return Color(red: 0.80, green: 0.50, blue: 0.20)  // 铜
        default: return .gray
        }
    }

    private func podiumView(of top3: [(student: Student, total: Double)]) -> some View {
        HStack(alignment: .bottom, spacing: 12) {
            // 第二名
            podiumColumn(rank: 2, student: top3[1].student, total: top3[1].total, height: 80)
            // 第一名
            podiumColumn(rank: 1, student: top3[0].student, total: top3[0].total, height: 110)
            // 第三名
            podiumColumn(rank: 3, student: top3[2].student, total: top3[2].total, height: 60)
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 8)
    }

    private func podiumColumn(rank: Int, student: Student, total: Double, height: CGFloat) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(podiumColor(index: rank - 1).opacity(0.2))
                    .frame(width: 52, height: 52)
                StudentAvatar(name: student.name, size: 44)
                Text("\(rank)")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20)
                    .background(Circle().fill(podiumColor(index: rank - 1)))
                    .offset(x: 16, y: -16)
            }
            Text(student.name)
                .font(AppTheme.Fonts.subheadline.weight(.semibold))
                .foregroundColor(AppTheme.Colors.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(String(format: "%.0f 分", total))
                .font(AppTheme.Fonts.caption)
                .foregroundColor(AppTheme.Colors.secondaryText)
            Rectangle()
                .fill(podiumColor(index: rank - 1).opacity(0.3))
                .frame(height: height)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .frame(maxWidth: .infinity)
    }
}
