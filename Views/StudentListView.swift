import SwiftUI
import UIKit

// 学生名册
struct StudentListView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.openURL) private var openURL
    @State private var searchText = ""
    @State private var showingAdd = false

    private var filteredStudents: [Student] {
        guard !searchText.isEmpty else { return viewModel.students }
        return viewModel.students.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.studentNumber.localizedCaseInsensitiveContains(searchText)
                || $0.phone.contains(searchText)
                || $0.parentPhone.contains(searchText)
        }
    }

    var body: some View {
        Group {
            if filteredStudents.isEmpty {
                EmptyStateView(
                    systemImage: "person.2",
                    title: searchText.isEmpty ? "还没有学生" : "未找到学生",
                    message: searchText.isEmpty ? "点击右上角 + 添加学生" : "换个关键词试试"
                )
            } else {
                List {
                    ForEach(filteredStudents) { student in
                        NavigationLink {
                            StudentDetailView(studentId: student.id)
                        } label: {
                            StudentRow(student: student)
                        }
                        .contextMenu {
                            if !student.phone.isEmpty, let url = telURL(student.phone) {
                                Button {
                                    openURL(url)
                                } label: {
                                    Label("拨打学生电话 \(student.phone)", systemImage: "phone.fill")
                                }
                            }
                            if !student.parentPhone.isEmpty, let url = telURL(student.parentPhone) {
                                Button {
                                    openURL(url)
                                } label: {
                                    Label("拨打家长电话 \(student.parentPhone)", systemImage: "phone.arrow.right.left")
                                }
                            }
                            Button(role: .destructive) {
                                viewModel.deleteStudent(student)
                            } label: {
                                Label("删除学生", systemImage: "trash")
                            }
                        }
                    }
                    .onDelete(perform: deleteStudents)
                }
            }
        }
        .navigationTitle("学生名册")
        .searchable(text: $searchText, prompt: "搜索姓名/学号/电话")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    printRoster()
                } label: {
                    Image(systemName: "printer")
                }
                .disabled(filteredStudents.isEmpty)
                Button {
                    showingAdd = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            NavigationStack {
                StudentFormView(mode: .add)
            }
        }
    }

    private func deleteStudents(at offsets: IndexSet) {
        for index in offsets {
            viewModel.deleteStudent(filteredStudents[index])
        }
    }

    private func telURL(_ phone: String) -> URL? {
        let digits = phone.filter { "0123456789+".contains($0) }
        guard !digits.isEmpty else { return nil }
        return URL(string: "tel://" + digits)
    }

    // 真实打印：系统打印面板输出名册
    private func printRoster() {
        var rows = ""
        for student in filteredStudents {
            let seat = student.seatRow > 0 ? "第\(student.seatRow)排第\(student.seatCol)座" : "未分配"
            let phone = student.phone.isEmpty ? "—" : student.phone
            let parent = student.parentPhone.isEmpty ? "—" : student.parentPhone
            rows += "<tr><td>\(student.studentNumber)</td><td>\(student.name)</td><td>\(student.gender.rawValue)</td>"
            rows += "<td>\(phone)</td><td>\(parent)</td><td>第\(student.groupNumber)组</td><td>\(seat)</td></tr>"
        }
        let html = """
        <html><head><meta charset="utf-8"><style>
        body { font-family: -apple-system; font-size: 12px; }
        h2 { text-align: center; }
        table { width: 100%; border-collapse: collapse; }
        th, td { border: 1px solid #999; padding: 6px; text-align: center; }
        th { background-color: #eee; }
        </style></head><body>
        <h2>\(viewModel.classInfo.className) 学生名册</h2>
        <p style="text-align:center">共 \(filteredStudents.count) 人 · 打印日期 \(Date().formatted(.dateTime.year().month().day()))</p>
        <table>
        <tr><th>学号</th><th>姓名</th><th>性别</th><th>学生电话</th><th>家长电话</th><th>小组</th><th>座位</th></tr>
        \(rows)
        </table></body></html>
        """
        let formatter = UIMarkupTextPrintFormatter(markupText: html)
        formatter.perPageContentInsets = UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40)
        let controller = UIPrintInteractionController.shared
        controller.printFormatter = formatter
        controller.present(animated: true)
    }
}

// 列表行
struct StudentRow: View {
    let student: Student

    var body: some View {
        HStack(spacing: 12) {
            StudentAvatar(name: student.name, size: 44)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(student.name)
                        .font(.body.weight(.semibold))
                    Text("#\(student.studentNumber)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                HStack(spacing: 10) {
                    if !student.phone.isEmpty {
                        Label(student.phone, systemImage: "phone")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    Text("第\(student.groupNumber)组")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

// 学生详情（编辑后实时刷新）
struct StudentDetailView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    let studentId: UUID
    @State private var editing = false

    // 从 viewModel 实时读取，编辑/排座后详情立即更新
    private var student: Student? { viewModel.student(id: studentId) }

    var body: some View {
        Group {
            if let student = student {
                detailBody(student)
            } else {
                EmptyStateView(systemImage: "person.slash", title: "学生不存在", message: "该学生可能已被删除")
            }
        }
        .navigationTitle(student?.name ?? "学生详情")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $editing) {
            if let student = student {
                NavigationStack {
                    StudentFormView(mode: .edit(student))
                }
            }
        }
    }

    @ViewBuilder
    private func detailBody(_ student: Student) -> some View {
        Form {
            Section("基本信息") {
                LabeledContent("姓名", value: student.name)
                LabeledContent("学号", value: student.studentNumber.isEmpty ? "—" : student.studentNumber)
                LabeledContent("性别", value: student.gender.rawValue)
                LabeledContent("小组", value: "第\(student.groupNumber)组")
            }
            Section("联系方式") {
                if !student.phone.isEmpty {
                    Button {
                        if let url = telURL(student.phone) { openURL(url) }
                    } label: {
                        Label("学生电话 \(student.phone)", systemImage: "phone.fill")
                    }
                }
                if !student.parentPhone.isEmpty {
                    Button {
                        if let url = telURL(student.parentPhone) { openURL(url) }
                    } label: {
                        Label("家长电话 \(student.parentPhone)", systemImage: "phone.arrow.right.left")
                    }
                }
                if student.phone.isEmpty && student.parentPhone.isEmpty {
                    Text("暂无联系方式")
                        .foregroundColor(.secondary)
                }
                if !student.address.isEmpty {
                    LabeledContent("家庭住址", value: student.address)
                }
            }
            Section("座位与宿舍") {
                LabeledContent("座位", value: student.seatRow > 0 ? "第\(student.seatRow)排第\(student.seatCol)座" : "未分配")
                LabeledContent("宿舍", value: student.dormitory.isEmpty ? "—" : student.dormitory)
            }
            if !student.notes.isEmpty {
                Section("备注") {
                    Text(student.notes)
                }
            }
            Section {
                Button {
                    editing = true
                } label: {
                    Label("编辑资料", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    viewModel.deleteStudent(student)
                    dismiss()
                } label: {
                    Label("删除学生", systemImage: "trash")
                }
            }
        }
    }

    private func telURL(_ phone: String) -> URL? {
        let digits = phone.filter { "0123456789+".contains($0) }
        guard !digits.isEmpty else { return nil }
        return URL(string: "tel://" + digits)
    }
}

// 学生添加/编辑表单
struct StudentFormView: View {
    enum Mode {
        case add
        case edit(Student)
    }

    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    let mode: Mode

    @State private var name = ""
    @State private var studentNumber = ""
    @State private var gender: Student.Gender = .male
    @State private var phone = ""
    @State private var parentPhone = ""
    @State private var address = ""
    @State private var groupNumber = 1
    @State private var dormitory = ""
    @State private var notes = ""

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    var body: some View {
        Form {
            Section("基本信息") {
                TextField("姓名", text: $name)
                TextField("学号", text: $studentNumber)
                Picker("性别", selection: $gender) {
                    ForEach(Student.Gender.allCases, id: \.self) { g in
                        Text(g.rawValue).tag(g)
                    }
                }
                Picker("小组", selection: $groupNumber) {
                    ForEach(1...6, id: \.self) { n in
                        Text("第\(n)组").tag(n)
                    }
                }
            }
            Section("联系方式") {
                TextField("学生电话", text: $phone)
                    .keyboardType(.phonePad)
                TextField("家长电话", text: $parentPhone)
                    .keyboardType(.phonePad)
                TextField("家庭住址", text: $address)
            }
            Section("宿舍") {
                TextField("宿舍号", text: $dormitory)
            }
            Section("备注") {
                TextField("备注（选填）", text: $notes, axis: .vertical)
            }
        }
        .navigationTitle(isEditing ? "编辑学生" : "添加学生")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") { save() }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .onAppear {
            if case .edit(let student) = mode {
                name = student.name
                studentNumber = student.studentNumber
                gender = student.gender
                phone = student.phone
                parentPhone = student.parentPhone
                address = student.address
                groupNumber = student.groupNumber
                dormitory = student.dormitory
                notes = student.notes
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        switch mode {
        case .add:
            viewModel.addStudent(Student(
                name: trimmed, studentNumber: studentNumber, gender: gender,
                phone: phone, parentPhone: parentPhone, address: address,
                groupNumber: groupNumber, dormitory: dormitory, notes: notes
            ))
        case .edit(let student):
            var updated = student
            updated.name = trimmed
            updated.studentNumber = studentNumber
            updated.gender = gender
            updated.phone = phone
            updated.parentPhone = parentPhone
            updated.address = address
            updated.groupNumber = groupNumber
            updated.dormitory = dormitory
            updated.notes = notes
            viewModel.updateStudent(updated)
        }
        dismiss()
    }
}
