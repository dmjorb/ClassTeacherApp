import SwiftUI

// 成绩录入详情
struct ScoreDetailView: View {
    @EnvironmentObject var viewModel: AppViewModel
    let exam: Exam

    @State private var selectedSubject: String
    @State private var showingRanking = false

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

    var body: some View {
        VStack(spacing: 0) {
            // 科目选择
            if exam.subjects.count > 1 {
                Picker("科目", selection: subjectBinding) {
                    ForEach(exam.subjects, id: \.self) { subject in
                        Text(subject).tag(subject)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 10)
            }

            // 统计
            statsBar

            // 成绩列表
            if viewModel.students.isEmpty {
                EmptyStateView(
                    systemImage: "person.2",
                    title: "还没有学生",
                    message: "请先在「学生名册」中添加学生"
                )
            } else {
                List {
                    ForEach(viewModel.students) { student in
                        ScoreInputRow(
                            student: student,
                            examId: exam.id,
                            subject: selectedSubject,
                            initialScore: score(of: student.id)
                        )
                    }
                }
                .listStyle(.insetGrouped)
                // 切换科目时强制重建输入行，避免显示上一个科目的分数
                .id(selectedSubject)
            }
        }
        .navigationTitle(exam.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingRanking = true
                } label: {
                    Image(systemName: "list.number")
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

    private func score(of studentId: UUID) -> String {
        guard let record = records.first(where: { $0.studentId == studentId }) else { return "" }
        return record.score.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(record.score)) : String(record.score)
    }

    private var statsBar: some View {
        HStack(spacing: 12) {
            StatCard(value: "\(records.count)", label: "已录入", systemImage: "checkmark.circle", color: .blue)
            StatCard(value: String(format: "%.1f", viewModel.averageScore(examId: exam.id, subject: selectedSubject)), label: "平均分", systemImage: "sum", color: .orange)
            StatCard(value: String(format: "%.0f%%", viewModel.passRate(examId: exam.id, subject: selectedSubject)), label: "及格率", systemImage: "checkmark.seal", color: .green)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
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

    var body: some View {
        HStack(spacing: 12) {
            StudentAvatar(name: student.name, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(student.name)
                    .font(.body.weight(.medium))
                Text("#\(student.studentNumber)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
            TextField("分数", text: $text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 90)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(.systemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .onChange(of: text) { newValue in
                    let cleaned = newValue.filter { "0123456789.".contains($0) }
                    if cleaned != newValue { text = cleaned }
                    if cleaned.isEmpty {
                        // 清空输入框 = 删除该成绩
                        viewModel.removeScore(studentId: student.id, examId: examId, subject: subject)
                    } else {
                        saveIfValid(cleaned)
                    }
                }
        }
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
                List {
                    ForEach(Array(ranking.enumerated()), id: \.element.student.id) { index, item in
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(.headline)
                                .foregroundColor(index < 3 ? .orange : .secondary)
                                .frame(width: 32, alignment: .center)
                            Text(item.student.name)
                                .font(.body.weight(.medium))
                            Spacer()
                            Text(String(format: "%.0f", item.total))
                                .font(.body.weight(.semibold))
                                .foregroundColor(.accentColor)
                        }
                        .padding(.vertical, 2)
                    }
                }
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
}
