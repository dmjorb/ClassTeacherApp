import SwiftUI
import MapKit

// 学生名册（iOS 原生系统样式）
struct StudentListView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var searchText = ""
    @State private var selectedStudent: Student?
    @State private var showingAddStudent = false
    @State private var filterRow: Int? = nil
    
    var filteredStudents: [Student] {
        var result = viewModel.students
        if let row = filterRow {
            result = result.filter { $0.seatRow == row }
        }
        if !searchText.isEmpty {
            result = result.filter { $0.name.contains(searchText) || $0.studentNumber.contains(searchText) }
        }
        return result.sorted { $0.seatRow < $1.seatRow || ($0.seatRow == $1.seatRow && $0.seatCol < $1.seatCol) }
    }
    
    var body: some View {
        Group {
            if viewModel.students.isEmpty {
                emptyState
            } else {
                studentList
            }
        }
        .navigationTitle("学生名册")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddStudent = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(item: $selectedStudent) { StudentDetailView(student: $0) }
        .sheet(isPresented: $showingAddStudent) { AddStudentView() }
    }
    
    // 学生列表（系统样式）
    private var studentList: some View {
        List {
            // 按排筛选
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        filterButton(title: "全部", row: nil)
                        ForEach(1...5, id: \.self) { row in
                            filterButton(title: "第\(row)排", row: row)
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
            }
            
            // 学生列表
            Section {
                ForEach(filteredStudents) { student in
                    studentRow(student)
                }
                .onDelete(perform: deleteStudent)
            } header: {
                Text("共 \(filteredStudents.count) 人")
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, prompt: "搜索学生姓名或学号")
    }
    
    // 学生行（系统样式）
    private func studentRow(_ student: Student) -> some View {
        Button(action: { selectedStudent = student }) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.orange.gradient)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(String(student.name.prefix(1)))
                            .font(.headline.weight(.bold))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(student.name)
                        .font(.headline)
                    Text("#\(student.studentNumber.suffix(3)) · \(student.seatRow)排\(student.seatCol)座")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !student.parentPhone.isEmpty {
                    Button(action: {
                        if let url = URL(string: "tel://\(student.parentPhone)") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Image(systemName: "phone.fill")
                            .foregroundColor(.green)
                            .frame(width: 36, height: 36)
                            .background(Color.green.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(action: {
                if !student.parentPhone.isEmpty, let url = URL(string: "tel://\(student.parentPhone)") {
                    UIApplication.shared.open(url)
                }
            }) {
                Label("拨打家长电话", systemImage: "phone.fill")
            }
            Button(action: { selectedStudent = student }) {
                Label("查看详情", systemImage: "info.circle")
            }
        }
    }
    
    private func filterButton(title: String, row: Int?) -> some View {
        Button(action: { filterRow = row }) {
            Text(title)
                .font(.subheadline.weight(filterRow == row ? .semibold : .regular))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(filterRow == row ? Color.orange : Color(.systemGray6))
                .foregroundColor(filterRow == row ? .white : .primary)
                .cornerRadius(.greatestFiniteMagnitude)
        }
        .buttonStyle(.plain)
    }
    
    private func deleteStudent(at offsets: IndexSet) {
        offsets.forEach { index in
            viewModel.deleteStudent(filteredStudents[index])
        }
    }
    
    // 空状态
    private var emptyState: some View {
        EmptyStateView(
            systemImage: "person.2.slash",
            title: "还没有学生",
            message: "添加第一位学生，开始管理班级",
            buttonTitle: "添加学生",
            buttonAction: { showingAddStudent = true }
        )
    }
}

// 学生详情
struct StudentDetailView: View {
    let student: Student
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    
    @State private var editName = ""
    @State private var editStudentNumber = ""
    @State private var editGender: Student.Gender = .male
    @State private var editAge = 16
    @State private var editPhone = ""
    @State private var editParentPhone = ""
    @State private var editAddress = ""
    @State private var editGroupNumber = 1
    @State private var editDormitory = ""
    @State private var editNotes = ""
    @State private var editLatitude = ""
    @State private var editLongitude = ""
    
    var body: some View {
        NavigationStack {
            List {
                if isEditing {
                    editingForm
                } else {
                    detailContent
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(isEditing ? "编辑学生" : "学生详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditing {
                        Button("取消") { isEditing = false; loadStudentData() }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        Button("保存") { saveChanges(); isEditing = false }
                    } else {
                        Button("编辑") { isEditing = true; loadStudentData() }
                    }
                }
            }
            .onAppear { loadStudentData() }
            .alert("确认删除", isPresented: $showingDeleteAlert) {
                Button("取消", role: .cancel) {}
                Button("删除", role: .destructive) { viewModel.deleteStudent(student); dismiss() }
            } message: { Text("删除该学生将同时删除其所有成绩数据，无法恢复。") }
        }
    }
    
    private var detailContent: some View {
        Group {
            Section("基本信息") {
                HStack {
                    Circle()
                        .fill(Color.orange.gradient)
                        .frame(width: 48, height: 48)
                        .overlay(Text(String(student.name.prefix(1))).font(.title3.weight(.bold)).foregroundColor(.white))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(student.name).font(.title3.weight(.semibold))
                        if !student.notes.isEmpty {
                            Text(student.notes).font(.caption).foregroundColor(.orange)
                        }
                    }
                }
                .padding(.vertical, 4)
                infoRow(title: "学号", value: student.studentNumber)
                infoRow(title: "性别", value: student.gender.rawValue)
                infoRow(title: "年龄", value: "\(student.age)岁")
                infoRow(title: "小组", value: "第\(student.groupNumber)组")
                infoRow(title: "座位", value: "第\(student.seatRow)排 第\(student.seatCol)列")
                infoRow(title: "宿舍", value: student.dormitory.isEmpty ? "未分配" : student.dormitory)
            }
            
            Section("联系方式") {
                if !student.phone.isEmpty {
                    Button(action: { if let url = URL(string: "tel://\(student.phone)") { UIApplication.shared.open(url) } }) {
                        Label(student.phone, systemImage: "phone.fill").foregroundColor(.blue)
                    }
                } else { infoRow(title: "学生电话", value: "未填写") }
                if !student.parentPhone.isEmpty {
                    Button(action: { if let url = URL(string: "tel://\(student.parentPhone)") { UIApplication.shared.open(url) } }) {
                        Label("家长：\(student.parentPhone)", systemImage: "phone.fill").foregroundColor(.blue)
                    }
                } else { infoRow(title: "家长电话", value: "未填写") }
                infoRow(title: "家庭住址", value: student.address.isEmpty ? "未填写" : student.address)
            }
            
            if let lat = student.latitude, let lon = student.longitude {
                Section("家庭位置") {
                    Map(coordinateRegion: .constant(MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )), annotationItems: [StudentLocation(student: student, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))]) { loc in
                        MapAnnotation(coordinate: loc.coordinate) {
                            Image(systemName: "mappin.circle.fill").foregroundColor(.red).font(.title)
                        }
                    }
                    .frame(height: 180)
                    .cornerRadius(12)
                    .listRowInsets(EdgeInsets())
                    infoRow(title: "纬度", value: String(format: "%.6f", lat))
                    infoRow(title: "经度", value: String(format: "%.6f", lon))
                }
            }
            
            Section("备注") {
                Text(student.notes.isEmpty ? "暂无备注" : student.notes)
                    .foregroundColor(student.notes.isEmpty ? .secondary : .primary)
            }
            
            Section {
                Button(role: .destructive, action: { showingDeleteAlert = true }) {
                    Label("删除学生", systemImage: "trash").foregroundColor(.red)
                }
            }
        }
    }
    
    private var editingForm: some View {
        Group {
            Section("基本信息") {
                TextField("姓名", text: $editName)
                TextField("学号", text: $editStudentNumber)
                Picker("性别", selection: $editGender) { Text("男").tag(Student.Gender.male); Text("女").tag(Student.Gender.female) }
                Stepper("年龄：\(editAge)岁", value: $editAge, in: 10...20)
                Picker("小组", selection: $editGroupNumber) { ForEach(1...5, id: \.self) { Text("第\($0)组").tag($0) } }
                TextField("宿舍号", text: $editDormitory)
            }
            Section("联系方式") {
                TextField("学生电话", text: $editPhone).keyboardType(.phonePad)
                TextField("家长电话", text: $editParentPhone).keyboardType(.phonePad)
                TextField("家庭住址", text: $editAddress)
            }
            Section("位置信息（选填）") {
                TextField("纬度（如 34.7466）", text: $editLatitude).keyboardType(.decimalPad)
                TextField("经度（如 113.6254）", text: $editLongitude).keyboardType(.decimalPad)
            }
            Section("备注") { TextField("备注信息", text: $editNotes) }
        }
    }
    
    private func infoRow(title: String, value: String) -> some View {
        HStack { Text(title).foregroundColor(.secondary); Spacer(); Text(value) }
    }
    
    private func loadStudentData() {
        editName = student.name
        editStudentNumber = student.studentNumber
        editGender = student.gender
        editAge = student.age
        editPhone = student.phone
        editParentPhone = student.parentPhone
        editAddress = student.address
        editGroupNumber = student.groupNumber
        editDormitory = student.dormitory
        editNotes = student.notes
        editLatitude = student.latitude.map { String($0) } ?? ""
        editLongitude = student.longitude.map { String($0) } ?? ""
    }
    
    private func saveChanges() {
        if let index = viewModel.students.firstIndex(where: { $0.id == student.id }) {
            viewModel.students[index].name = editName
            viewModel.students[index].studentNumber = editStudentNumber
            viewModel.students[index].gender = editGender
            viewModel.students[index].age = editAge
            viewModel.students[index].phone = editPhone
            viewModel.students[index].parentPhone = editParentPhone
            viewModel.students[index].address = editAddress
            viewModel.students[index].groupNumber = editGroupNumber
            viewModel.students[index].dormitory = editDormitory
            viewModel.students[index].notes = editNotes
            viewModel.students[index].latitude = Double(editLatitude)
            viewModel.students[index].longitude = Double(editLongitude)
        }
    }
}

// 添加学生
struct AddStudentView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: AppViewModel
    
    @State private var name = ""
    @State private var studentNumber = ""
    @State private var gender: Student.Gender = .male
    @State private var age = 16
    @State private var phone = ""
    @State private var parentPhone = ""
    @State private var address = ""
    @State private var groupNumber = 1
    @State private var dormitory = ""
    @State private var notes = ""
    @State private var latitude = ""
    @State private var longitude = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("姓名", text: $name)
                    TextField("学号", text: $studentNumber)
                    Picker("性别", selection: $gender) { Text("男").tag(Student.Gender.male); Text("女").tag(Student.Gender.female) }
                    Stepper("年龄：\(age)岁", value: $age, in: 10...20)
                    Picker("小组", selection: $groupNumber) { ForEach(1...5, id: \.self) { Text("第\($0)组").tag($0) } }
                }
                Section("联系方式") {
                    TextField("学生电话", text: $phone).keyboardType(.phonePad)
                    TextField("家长电话", text: $parentPhone).keyboardType(.phonePad)
                    TextField("家庭住址", text: $address)
                    TextField("宿舍号", text: $dormitory)
                }
                Section("位置信息（选填）") {
                    TextField("纬度（如 34.7466）", text: $latitude).keyboardType(.decimalPad)
                    TextField("经度（如 113.6254）", text: $longitude).keyboardType(.decimalPad)
                }
                Section("备注") { TextField("备注信息", text: $notes) }
            }
            .navigationTitle("添加学生")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") { saveStudent(); dismiss() }
                        .disabled(name.isEmpty || studentNumber.isEmpty)
                }
            }
        }
    }
    
    private func saveStudent() {
        let maxRow = viewModel.students.map { $0.seatRow }.max() ?? 0
        let maxCol = viewModel.students.filter { $0.seatRow == maxRow }.map { $0.seatCol }.max() ?? 0
        var newRow = maxRow
        var newCol = maxCol + 1
        if newCol > 5 {
            newCol = 1
            newRow += 1
        }
        if newRow == 0 { newRow = 1; newCol = 1 }
        
        viewModel.students.append(Student(
            name: name, studentNumber: studentNumber, gender: gender, age: age,
            phone: phone, parentPhone: parentPhone, address: address,
            groupNumber: groupNumber, seatRow: newRow, seatCol: newCol,
            dormitory: dormitory, notes: notes,
            latitude: Double(latitude), longitude: Double(longitude)
        ))
    }
}
