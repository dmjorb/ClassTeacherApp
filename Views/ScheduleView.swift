import SwiftUI

// 班级课表（周视图）
struct ScheduleView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var selectedSlot: ScheduleSlot?

    private let weekdays = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
    private let colWidth: CGFloat = 46

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(spacing: 2) {
                // 表头
                HStack(spacing: 2) {
                    Text("节")
                        .font(.caption.weight(.bold))
                        .frame(width: 30, height: 34)
                    ForEach(1...7, id: \.self) { weekday in
                        Text(weekdays[weekday - 1])
                            .font(.caption.weight(.semibold))
                            .frame(width: colWidth, height: 34)
                            .background(weekday == viewModel.todayDayOfWeek ? Color.accentColor.opacity(0.2) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                }
                // 节次
                ForEach(1...8, id: \.self) { period in
                    HStack(spacing: 2) {
                        Text("\(period)")
                            .font(.caption2.weight(.medium))
                            .foregroundColor(.secondary)
                            .frame(width: 30, height: 52)
                        ForEach(1...7, id: \.self) { weekday in
                            cell(weekday: weekday, period: period)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("班级课表")
        .sheet(item: $selectedSlot) { slot in
            CourseEditSheet(weekday: slot.weekday, period: slot.period)
        }
    }

    @ViewBuilder
    private func cell(weekday: Int, period: Int) -> some View {
        let course = viewModel.courses(for: weekday).first { $0.period == period }
        Button {
            selectedSlot = ScheduleSlot(weekday: weekday, period: period)
        } label: {
            Group {
                if let course = course {
                    VStack(spacing: 2) {
                        Text(course.subject)
                            .font(.caption2.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        if !course.teacher.isEmpty {
                            Text(course.teacher)
                                .font(.system(size: 9))
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                        }
                    }
                    .frame(width: colWidth, height: 52)
                    .background(courseColor(course.subject).opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(courseColor(course.subject), lineWidth: 1))
                } else {
                    Rectangle()
                        .fill(Color(.secondarySystemGroupedBackground))
                        .frame(width: colWidth, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func courseColor(_ subject: String) -> Color {
        let palette: [Color] = [.blue, .orange, .purple, .green, .pink, .teal, .indigo, .brown]
        var hash = 0
        for scalar in subject.unicodeScalars {
            hash = (hash &* 31 &+ Int(scalar.value)) & 0x7fffffff
        }
        return palette[hash % palette.count]
    }
}

// 可选的课表格
struct ScheduleSlot: Identifiable {
    let id = UUID()
    let weekday: Int
    let period: Int
}

// 课程添加/编辑弹窗
struct CourseEditSheet: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    let weekday: Int
    let period: Int

    @State private var subject = ""
    @State private var classroom = ""
    @State private var teacher = ""

    private var existing: Course? {
        viewModel.courses(for: weekday).first { $0.period == period }
    }

    var body: some View {
        NavigationStack {
            Form {
                if existing != nil {
                    Section("第\(period)节 · 已有课程") {
                        Picker("科目", selection: $subject) {
                            ForEach(viewModel.classInfo.subjects, id: \.self) { s in
                                Text(s).tag(s)
                            }
                        }
                        TextField("教室", text: $classroom)
                        TextField("任课老师", text: $teacher)
                    }
                    Section {
                        Button(role: .destructive) {
                            if let course = existing {
                                viewModel.deleteCourse(course)
                            }
                            dismiss()
                        } label: {
                            Label("删除这节课", systemImage: "trash")
                        }
                    }
                } else {
                    Section("第\(period)节 · 添加课程") {
                        Picker("科目", selection: $subject) {
                            ForEach(viewModel.classInfo.subjects, id: \.self) { s in
                                Text(s).tag(s)
                            }
                        }
                        TextField("教室（选填）", text: $classroom)
                        TextField("任课老师（选填）", text: $teacher)
                    }
                }
            }
            .navigationTitle("\(weekdayName(weekday)) 第\(period)节")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        if let course = existing {
                            var updated = course
                            updated.subject = subject
                            updated.classroom = classroom
                            updated.teacher = teacher
                            viewModel.deleteCourse(course)
                            viewModel.addCourse(updated)
                        } else if !subject.isEmpty {
                            viewModel.addCourse(Course(subject: subject, dayOfWeek: weekday, period: period, classroom: classroom, teacher: teacher))
                        }
                        dismiss()
                    }
                    .disabled(subject.isEmpty)
                }
            }
            .onAppear {
                if let course = existing {
                    subject = course.subject
                    classroom = course.classroom
                    teacher = course.teacher
                } else if let first = viewModel.classInfo.subjects.first {
                    subject = first
                }
            }
        }
    }

    private func weekdayName(_ weekday: Int) -> String {
        ["周一", "周二", "周三", "周四", "周五", "周六", "周日"][weekday - 1]
    }
}
