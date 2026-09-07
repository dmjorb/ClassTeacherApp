import SwiftUI

// 总分排名：选择考试 → 前三名 + 完整排名
struct RankingListView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var selectedExamId: UUID?

    private var sortedExams: [Exam] {
        viewModel.exams.sorted { $0.date > $1.date }
    }

    private var selectedExam: Exam? {
        guard let id = selectedExamId else { return nil }
        return viewModel.exams.first { $0.id == id }
    }

    var body: some View {
        Group {
            if viewModel.exams.isEmpty {
                EmptyStateView(
                    systemImage: "chart.bar",
                    title: "还没有考试",
                    message: "先在「成绩管理」中新建考试并录入成绩"
                )
            } else {
                VStack(spacing: 0) {
                    Picker("考试", selection: $selectedExamId) {
                        ForEach(sortedExams) { exam in
                            Text(exam.name).tag(Optional(exam.id))
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.vertical, 6)

                    if let exam = selectedExam {
                        rankingBody(for: exam)
                    }
                }
            }
        }
        .navigationTitle("总分排名")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if selectedExamId == nil {
                selectedExamId = sortedExams.first?.id
            }
        }
    }

    @ViewBuilder
    private func rankingBody(for exam: Exam) -> some View {
        let ranking = viewModel.totalRanking(for: exam.id)
        if ranking.isEmpty {
            EmptyStateView(
                systemImage: "list.number",
                title: "暂无成绩",
                message: "这场考试还没有录入成绩"
            )
        } else {
            ScrollView {
                VStack(spacing: 16) {
                    if ranking.count >= 3 {
                        podium(of: Array(ranking.prefix(3)))
                    } else {
                        Text("有成绩的学生不足 3 人，直接查看下方排名")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    fullList(of: ranking)
                }
                .padding()
            }
            .background(AppTheme.Colors.background)
        }
    }

    // 前三名领奖台
    private struct PodiumEntry: Identifiable {
        let rank: Int
        let student: Student
        let total: Double
        var id: Int { rank }
    }

    private func podium(of top3: [(student: Student, total: Double)]) -> some View {
        // 排列顺序：第2、第1、第3
        let entries: [PodiumEntry] = [
            PodiumEntry(rank: 2, student: top3[1].student, total: top3[1].total),
            PodiumEntry(rank: 1, student: top3[0].student, total: top3[0].total),
            PodiumEntry(rank: 3, student: top3[2].student, total: top3[2].total),
        ]
        let barHeight: [Int: CGFloat] = [1: 48, 2: 28, 3: 12]
        let colors: [Int: Color] = [1: .yellow, 2: .gray, 3: .orange]

        return HStack(alignment: .bottom, spacing: 12) {
            ForEach(entries) { entry in
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(colors[entry.rank]?.opacity(0.2) ?? .gray.opacity(0.2))
                            .frame(width: 56, height: 56)
                        StudentAvatar(name: entry.student.name, size: 44)
                        Text("\(entry.rank)")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.white)
                            .frame(width: 18, height: 18)
                            .background(Circle().fill(colors[entry.rank] ?? .gray))
                            .offset(x: 20, y: -20)
                    }
                    Text(entry.student.name)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text(String(format: "%.0f 分", entry.total))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Rectangle()
                        .fill((colors[entry.rank] ?? .gray).opacity(0.25))
                        .frame(height: barHeight[entry.rank] ?? 12)
                }
                .frame(maxWidth: .infinity)
                .background(AppTheme.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    // 完整排名列表
    private func fullList(of ranking: [(student: Student, total: Double)]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("完整排名（\(ranking.count) 人）")
                .font(.headline)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(Array(ranking.enumerated()), id: \.element.student.id) { index, item in
                    HStack(spacing: 12) {
                        Text("\(index + 1)")
                            .font(.headline)
                            .foregroundColor(index < 3 ? .orange : .secondary)
                            .frame(width: 30, alignment: .center)
                        StudentAvatar(name: item.student.name, size: 34)
                        Text(item.student.name)
                            .font(.body.weight(.medium))
                        Spacer()
                        Text(String(format: "%.0f", item.total))
                            .font(.body.weight(.semibold))
                            .foregroundColor(.accentColor)
                        Text("分")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    if index < ranking.count - 1 {
                        Divider().padding(.leading, 60)
                    }
                }
            }
            .background(AppTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}
