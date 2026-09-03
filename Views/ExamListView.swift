import SwiftUI

// 考试列表（成绩Tab首页 - iOS 原生系统样式）
struct ExamListView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var selectedType: Exam.ExamType? = nil
    @State private var showingNewExam = false
    @State private var selectedExam: Exam?
    @State private var selectedSemester = 1
    
    var filteredExams: [Exam] {
        if let type = selectedType {
            return viewModel.exams.filter { $0.type == type }
        }
        return viewModel.exams
    }
    
    var body: some View {
        Group {
            if viewModel.exams.isEmpty {
                emptyState
            } else {
                examList
            }
        }
        .navigationTitle("成绩管理")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingNewExam = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewExam) {
            NewExamView()
        }
        .sheet(item: $selectedExam) { exam in
            ScoreDetailView(exam: exam)
        }
    }
    
    // 考试列表（系统样式）
    private var examList: some View {
        List {
            // 学期选择 + 类型筛选
            Section {
                HStack {
                    Menu {
                        Button("第1学期") { selectedSemester = 1 }
                        Button("第2学期") { selectedSemester = 2 }
                    } label: {
                        HStack(spacing: 4) {
                            Text("第\(selectedSemester)学期")
                            Image(systemName: "chevron.down")
                        }
                        .font(.subheadline)
                    }
                    Spacer()
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        typeButton(title: "全部", type: nil, icon: "square.grid.2x2")
                        typeButton(title: "单元测", type: .unitTest, icon: "doc.text")
                        typeButton(title: "月考", type: .monthly, icon: "calendar")
                        typeButton(title: "期中考", type: .midterm, icon: "pencil")
                        typeButton(title: "期末考", type: .final, icon: "trophy")
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
            
            // 考试列表
            Section {
                ForEach(filteredExams) { exam in
                    Button(action: { selectedExam = exam }) {
                        examRow(exam)
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: deleteExam)
            } header: {
                Text("共 \(filteredExams.count) 场考试")
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private func examRow(_ exam: Exam) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(typeColor(exam.type).gradient)
                .frame(width: 44, height: 44)
                .overlay(Image(systemName: typeIcon(exam.type)).foregroundColor(.white))
            VStack(alignment: .leading, spacing: 4) {
                Text(exam.name)
                    .font(.headline)
                Text("\(exam.type.rawValue) · \(exam.subjects.count)科")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
    
    private func typeButton(title: String, type: Exam.ExamType?, icon: String) -> some View {
        Button(action: { selectedType = type }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.subheadline)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(selectedType == type ? Color.orange.opacity(0.15) : Color(.systemGray6))
            .foregroundColor(selectedType == type ? .orange : .primary)
            .cornerRadius(.greatestFiniteMagnitude)
        }
        .buttonStyle(.plain)
    }
    
    private func typeColor(_ type: Exam.ExamType) -> Color {
        switch type {
        case .unitTest: return .blue
        case .monthly: return .orange
        case .midterm: return .purple
        case .final: return .green
        }
    }
    
    private func typeIcon(_ type: Exam.ExamType) -> String {
        switch type {
        case .unitTest: return "doc.text"
        case .monthly: return "calendar"
        case .midterm: return "pencil"
        case .final: return "trophy"
        }
    }
    
    private func deleteExam(at offsets: IndexSet) {
        offsets.forEach { index in
            viewModel.deleteExam(filteredExams[index])
        }
    }
    
    // 空状态
    private var emptyState: some View {
        EmptyStateView(
            systemImage: "doc.text.magnifyingglass",
            title: "暂无考试记录",
            message: "点击右上角 + 新建第一场考试",
            buttonTitle: "新建考试",
            buttonAction: { showingNewExam = true }
        )
    }
}

// 新建考试
struct NewExamView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: AppViewModel
    
    @State private var examName = ""
    @State private var examType: Exam.ExamType = .monthly
    @State private var selectedSubjects: Set<String> = []
    
    var body: some View {
        NavigationStack {
            Form {
                Section("考试信息") {
                    TextField("考试名称", text: $examName)
                    Picker("考试类型", selection: $examType) {
                        ForEach(Exam.ExamType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }
                Section("选择科目") {
                    ForEach(viewModel.classInfo.subjects, id: \.self) { subject in
                        Button(action: {
                            if selectedSubjects.contains(subject) {
                                selectedSubjects.remove(subject)
                            } else {
                                selectedSubjects.insert(subject)
                            }
                        }) {
                            HStack {
                                Text(subject)
                                Spacer()
                                if selectedSubjects.contains(subject) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("新建考试")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("创建") {
                        if !examName.isEmpty && !selectedSubjects.isEmpty {
                            viewModel.addExam(name: examName, type: examType, subjects: Array(selectedSubjects))
                            dismiss()
                        }
                    }
                    .disabled(examName.isEmpty || selectedSubjects.isEmpty)
                }
            }
        }
    }
}
