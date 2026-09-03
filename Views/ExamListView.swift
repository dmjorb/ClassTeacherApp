import SwiftUI

// 考试列表
struct ExamListView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showingAdd = false
    @State private var typeFilter: Exam.ExamType?

    private var sortedExams: [Exam] {
        viewModel.exams.sorted { $0.date > $1.date }
    }

    private var filteredExams: [Exam] {
        guard let type = typeFilter else { return sortedExams }
        return sortedExams.filter { $0.type == type }
    }

    var body: some View {
        Group {
            if viewModel.exams.isEmpty {
                EmptyStateView(
                    systemImage: "doc.text",
                    title: "还没有考试",
                    message: "点击右上角 + 新建考试，然后录入成绩"
                )
            } else {
                List {
                    Section {
                        Picker("类型", selection: $typeFilter) {
                            Text("全部").tag(Optional<Exam.ExamType>.none)
                            ForEach(Exam.ExamType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(Optional(type))
                            }
                        }
                        .pickerStyle(.segmented)
                        .listRowBackground(Color.clear)
                    }
                    ForEach(filteredExams) { exam in
                        NavigationLink {
                            ScoreDetailView(exam: exam)
                        } label: {
                            ExamRow(exam: exam)
                        }
                    }
                    .onDelete(perform: deleteExams)
                }
            }
        }
        .navigationTitle("成绩管理")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAdd = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            NavigationStack {
                ExamFormView()
            }
        }
    }

    private func deleteExams(at offsets: IndexSet) {
        for index in offsets {
            viewModel.deleteExam(filteredExams[index])
        }
    }
}

// 考试行
struct ExamRow: View {
    let exam: Exam

    var body: some View {
        HStack(spacing: 12) {
            Text(ExamTypeIcon.symbol(for: exam.type))
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(ExamTypeIcon.color(for: exam.type).opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(exam.name)
                    .font(.body.weight(.semibold))
                Text("\(exam.type.rawValue) · \(exam.subjects.count) 科")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(exam.date.formatted(.dateTime.month().day()))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

// 类型图标工具
enum ExamTypeIcon {
    static func symbol(for type: Exam.ExamType) -> String {
        switch type {
        case .unitTest: return "square.grid.2x2"
        case .monthly: return "calendar"
        case .midterm: return "book.closed"
        case .final: return "graduationcap"
        }
    }
    static func color(for type: Exam.ExamType) -> Color {
        switch type {
        case .unitTest: return .blue
        case .monthly: return .orange
        case .midterm: return .purple
        case .final: return .green
        }
    }
}

// 新建考试表单
struct ExamFormView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var type: Exam.ExamType = .monthly
    @State private var date = Date()
    @State private var selectedSubjects: Set<String> = []

    private var allSubjects: [String] {
        viewModel.classInfo.subjects
    }

    var body: some View {
        Form {
            Section("考试信息") {
                TextField("考试名称", text: $name, prompt: Text("如：第一次月考"))
                Picker("类型", selection: $type) {
                    ForEach(Exam.ExamType.allCases, id: \.self) { t in
                        Text(t.rawValue).tag(t)
                    }
                }
                DatePicker("日期", selection: $date, displayedComponents: .date)
            }
            Section("选择科目") {
                if allSubjects.isEmpty {
                    Text("请先在「班级设置」中添加科目")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(allSubjects, id: \.self) { subject in
                        Toggle(subject, isOn: Binding(
                            get: { selectedSubjects.contains(subject) },
                            set: { isOn in
                                if isOn {
                                    selectedSubjects.insert(subject)
                                } else {
                                    selectedSubjects.remove(subject)
                                }
                            }
                        ))
                    }
                }
            }
        }
        .navigationTitle("新建考试")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("创建") {
                    let trimmed = name.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty, !selectedSubjects.isEmpty else { return }
                    viewModel.addExam(name: trimmed, type: type, subjects: Array(selectedSubjects))
                    dismiss()
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || selectedSubjects.isEmpty)
            }
        }
    }
}
