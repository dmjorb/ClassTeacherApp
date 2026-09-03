import SwiftUI

// 座位表（网格排座）
struct SeatView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var selectingCell: SeatCell?
    @State private var occupiedStudent: Student?
    @State private var showingSeatDialog = false

    private let rows = 7
    private let cols = 5

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                // 讲台
                Text("讲台")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: 260)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .padding(.bottom, 8)

                // 座位网格
                VStack(spacing: 6) {
                    ForEach(1...rows, id: \.self) { row in
                        HStack(spacing: 6) {
                            ForEach(1...cols, id: \.self) { col in
                                cell(row: row, col: col)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("座位表")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("自动排座") {
                    autoAssign()
                }
                .disabled(viewModel.students.isEmpty)
            }
        }
        .sheet(item: $selectingCell) { cell in
            NavigationStack {
                SeatPickView(cell: cell)
            }
        }
        .confirmationDialog("\(occupiedStudent?.name ?? "") 的座位", isPresented: $showingSeatDialog, titleVisibility: .visible) {
            Button("移出座位") {
                if let student = occupiedStudent {
                    clearSeat(of: student)
                }
            }
            Button("取消", role: .cancel) {}
        }
    }

    @ViewBuilder
    private func cell(row: Int, col: Int) -> some View {
        let student = viewModel.students.first { $0.seatRow == row && $0.seatCol == col }
        Button {
            if let student = student {
                occupiedStudent = student
                showingSeatDialog = true
            } else {
                selectingCell = SeatCell(row: row, col: col)
            }
        } label: {
            Group {
                if let student = student {
                    VStack(spacing: 2) {
                        Text(student.name)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        Text("#\(student.studentNumber)")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.accentColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.accentColor.opacity(0.4), lineWidth: 1))
                } else {
                    Rectangle()
                        .fill(Color(.secondarySystemGroupedBackground))
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func assign(_ student: Student, to row: Int, col: Int) {
        if let i = viewModel.students.firstIndex(where: { $0.id == student.id }) {
            viewModel.students[i].seatRow = row
            viewModel.students[i].seatCol = col
        }
    }

    private func clearSeat(of student: Student) {
        if let i = viewModel.students.firstIndex(where: { $0.id == student.id }) {
            viewModel.students[i].seatRow = 0
            viewModel.students[i].seatCol = 0
        }
    }

    // 把未排座的学生按顺序填入空位
    private func autoAssign() {
        let unassigned = viewModel.students.filter { $0.seatRow == 0 && $0.seatCol == 0 }
        var emptySlots: [(Int, Int)] = []
        for row in 1...rows {
            for col in 1...cols {
                let occupied = viewModel.students.contains { $0.seatRow == row && $0.seatCol == col }
                if !occupied { emptySlots.append((row, col)) }
            }
        }
        for (index, student) in unassigned.prefix(emptySlots.count).enumerated() {
            assign(student, to: emptySlots[index].0, col: emptySlots[index].1)
        }
    }
}

// 座位格子标识
struct SeatCell: Identifiable {
    let id = UUID()
    let row: Int
    let col: Int
}

// 选择学生放入座位
struct SeatPickView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    let cell: SeatCell

    private var candidates: [Student] {
        viewModel.students.filter { $0.seatRow == 0 && $0.seatCol == 0 }
    }

    var body: some View {
        Group {
            if candidates.isEmpty {
                EmptyStateView(
                    systemImage: "person.crop.circle.badge.plus",
                    title: "没有可安排的学生",
                    message: "所有学生都已排座，或请先在「学生名册」添加学生"
                )
            } else {
                List(candidates) { student in
                    Button {
                        if let i = viewModel.students.firstIndex(where: { $0.id == student.id }) {
                            viewModel.students[i].seatRow = cell.row
                            viewModel.students[i].seatCol = cell.col
                        }
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            StudentAvatar(name: student.name, size: 36)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(student.name)
                                Text("#\(student.studentNumber)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.forward")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("安排到 第\(cell.row)排\(cell.col)座")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") { dismiss() }
            }
        }
    }
}
