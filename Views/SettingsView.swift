import SwiftUI

// 班级设置
struct SettingsView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var className = ""
    @State private var grade = ""
    @State private var headTeacher = ""
    @State private var subjects: [String] = []
    @State private var newSubject = ""

    var body: some View {
        Form {
            Section("班级信息") {
                TextField("班级名（如：高一（2）班）", text: $className)
                TextField("年级（如：高一）", text: $grade)
                TextField("班主任姓名", text: $headTeacher)
            }
            Section("开设科目") {
                ForEach(subjects, id: \.self) { subject in
                    Text(subject)
                }
                .onDelete(perform: deleteSubject)

                HStack {
                    TextField("添加科目", text: $newSubject)
                    Button("添加") {
                        let trimmed = newSubject.trimmingCharacters(in: .whitespaces)
                        if !trimmed.isEmpty && !subjects.contains(trimmed) {
                            subjects.append(trimmed)
                        }
                        newSubject = ""
                    }
                    .disabled(newSubject.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            Section {
                Button("保存设置") {
                    viewModel.updateClassInfo(
                        className: className.trimmingCharacters(in: .whitespaces),
                        grade: grade.trimmingCharacters(in: .whitespaces),
                        headTeacher: headTeacher.trimmingCharacters(in: .whitespaces),
                        subjects: subjects
                    )
                    dismiss()
                }
                .disabled(className.trimmingCharacters(in: .whitespaces).isEmpty)
            } footer: {
                Text("科目将用于考试、课表等功能的选择。保存后立即生效并自动持久化。")
            }
        }
        .navigationTitle("班级设置")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: load)
    }

    private func load() {
        className = viewModel.classInfo.className
        grade = viewModel.classInfo.grade
        headTeacher = viewModel.classInfo.headTeacher
        subjects = viewModel.classInfo.subjects
    }

    private func deleteSubject(at offsets: IndexSet) {
        subjects.remove(atOffsets: offsets)
    }
}
