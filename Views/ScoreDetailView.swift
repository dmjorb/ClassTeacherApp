import SwiftUI

// 考试成绩详情
struct ScoreDetailView: View {
    let exam: Exam
    @EnvironmentObject var viewModel: AppViewModel
    @State private var selectedSubject: String
    @State private var showingInput = false
    @State private var sortOrder: SortOrder = .scoreDesc
    
    enum SortOrder { case scoreDesc, scoreAsc, name }
    
    init(exam: Exam) {
        self.exam = exam
        _selectedSubject = State(initialValue: exam.subjects.first ?? "语文")
    }
    
    var sortedRecords: [(student: Student, record: ScoreRecord?)] {
        var result: [(Student, ScoreRecord?)] = []
        for student in viewModel.students {
            let record = viewModel.scoreRecords.first {
                $0.studentId == student.id && $0.examName == exam.name && $0.subject == selectedSubject
            }
            result.append((student, record))
        }
        switch sortOrder {
        case .scoreDesc: result.sort { ($0.1?.score ?? 0) > ($1.1?.score ?? 0) }
        case .scoreAsc: result.sort { ($0.1?.score ?? 0) < ($1.1?.score ?? 0) }
        case .name: result.sort { $0.0.name < $1.0.name }
        }
        return result
    }
    
    var averageScore: Double {
        let scores = sortedRecords.compactMap { $0.1?.score }
        return scores.isEmpty ? 0 : scores.reduce(0, +) / Double(scores.count)
    }
    
    var body: some View {
        List {
            Section {
                Picker("科目", selection: $selectedSubject) {
                    ForEach(exam.subjects, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.menu)
            }
            
            Section {
                HStack(spacing: 12) {
                    statItem(title: "平均分", value: String(format: "%.1f", averageScore), color: .blue)
                    statItem(title: "最高分", value: String(format: "%.0f", sortedRecords.compactMap { $0.1?.score }.max() ?? 0), color: .green)
                    statItem(title: "已录入", value: "\(sortedRecords.filter { $0.1 != nil }.count)/\(viewModel.students.count)", color: .orange)
                }
                .padding(.vertical, 8)
            }
            
            Section {
                Picker("排序", selection: $sortOrder) {
                    Text("分数从高到低").tag(SortOrder.scoreDesc)
                    Text("分数从低到高").tag(SortOrder.scoreAsc)
                    Text("按姓名").tag(SortOrder.name)
                }
                .pickerStyle(.segmented)
            }
            
            Section(header: Text("成绩列表")) {
                ForEach(Array(sortedRecords.enumerated()), id: \.element.student.id) { index, item in
                    HStack(spacing: 12) {
                        Text("\(index + 1)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(index < 3 ? .orange : .secondary)
                            .frame(width: 28)
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 36, height: 36)
                            .overlay(Text(String(item.student.name.prefix(1))).font(.caption).foregroundColor(.white))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.student.name).font(.subheadline)
                            Text("#\(item.student.studentNumber.suffix(3))").font(.caption2).foregroundColor(.secondary)
                        }
                        Spacer()
                        if let record = item.record {
                            Text(String(format: "%.0f", record.score))
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(record.score >= 90 ? .green : (record.score >= 60 ? .blue : .red))
                        } else {
                            Text("未录入").font(.subheadline).foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle(exam.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingInput = true }) {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
        .sheet(isPresented: $showingInput) {
            ScoreInputView(examName: exam.name, subject: selectedSubject)
        }
    }
    
    private func statItem(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.headline).foregroundColor(color)
            Text(title).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// 成绩录入
struct ScoreInputView: View {
    let examName: String
    let subject: String
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: AppViewModel
    @State private var scores: [UUID: String] = [:]
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("\(examName) - \(subject) 成绩录入")) {
                    ForEach(viewModel.students) { student in
                        HStack {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 32, height: 32)
                                .overlay(Text(String(student.name.prefix(1))).font(.caption2).foregroundColor(.white))
                            Text(student.name).font(.subheadline)
                            Spacer()
                            TextField("分数", text: Binding(
                                get: { scores[student.id] ?? "" },
                                set: { scores[student.id] = $0 }
                            ))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .textFieldStyle(.roundedBorder)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("录入成绩")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") { saveScores(); dismiss() }
                }
            }
        }
    }
    
    private func saveScores() {
        for (studentId, scoreString) in scores {
            guard let score = Double(scoreString), !scoreString.isEmpty else { continue }
            if let index = viewModel.scoreRecords.firstIndex(where: {
                $0.studentId == studentId && $0.examName == examName && $0.subject == subject
            }) {
                viewModel.scoreRecords[index].score = score
            } else {
                viewModel.scoreRecords.append(ScoreRecord(
                    studentId: studentId, subject: subject, examName: examName, score: score, fullScore: 100
                ))
            }
        }
    }
}
