import SwiftUI

// 座位排布
struct SeatView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var editMode: EditMode = .inactive
    @State private var draggingStudent: Student?
    @State private var showingSettings = false
    
    // 教室布局：7排 x 5列（35个座位）
    let rows = 7
    let columns = 5
    
    var body: some View {
        Group {
            if viewModel.students.isEmpty {
                emptyState
            } else {
                seatLayout
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("座位排布")
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.editMode, $editMode)
        .sheet(isPresented: $showingSettings) {
            SeatSettingsView()
        }
    }
    
    // 空状态
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "grid")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("还没有学生数据")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("先在学生名册中添加学生，才能排座位")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    // 座位布局
    private var seatLayout: some View {
        VStack(spacing: 0) {
            // 讲台
            HStack {
                Spacer()
                Text("讲 台")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(width: 120, height: 36)
                    .background(Color.brown)
                    .cornerRadius(8)
                Spacer()
            }
            .padding(.vertical, 16)
            
            // 座位网格
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(1...rows, id: \.self) { row in
                        HStack(spacing: 8) {
                            // 过道
                            if row == 4 {
                                Spacer().frame(width: 20)
                            }
                            
                            ForEach(1...columns, id: \.self) { col in
                                seatCell(row: row, col: col)
                            }
                        }
                    }
                }
                .padding()
            }
            
            // 底部工具栏
            HStack {
                Button(action: {
                    withAnimation {
                        editMode = editMode == .active ? .inactive : .active
                    }
                }) {
                    Label(editMode == .active ? "完成" : "调整座位", systemImage: editMode == .active ? "checkmark" : "slider.horizontal.3")
                        .font(.subheadline)
                }
                
                Spacer()
                
                Button(action: { showingSettings = true }) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.subheadline)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .shadow(radius: 1)
        }
    }
    
    private func seatCell(row: Int, col: Int) -> some View {
        let student = viewModel.studentAt(row: row, col: col)
        
        return ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(student != nil ? seatColor(for: student!) : Color(.systemGray5))
                .frame(width: 56, height: 56)
            
            if let student = student {
                VStack(spacing: 2) {
                    Text(String(student.name.prefix(1)))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(student.gender == .male ? .blue : .pink)
                    Text(student.name)
                        .font(.system(size: 10))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
            } else {
                Text("空")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(editMode == .active ? Color.blue : Color.clear, lineWidth: 2)
        )
        .onTapGesture {
            if editMode == .active {
                // 点击交换座位
            }
        }
    }
    
    private func seatColor(for student: Student) -> Color {
        switch student.groupNumber {
        case 1: return Color.blue.opacity(0.1)
        case 2: return Color.green.opacity(0.1)
        case 3: return Color.orange.opacity(0.1)
        case 4: return Color.purple.opacity(0.1)
        case 5: return Color.pink.opacity(0.1)
        default: return Color.gray.opacity(0.1)
        }
    }
}

// 座位设置
struct SeatSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: AppViewModel
    
    var body: some View {
        NavigationStack {
            List {
                Section("快速排座") {
                    Button(action: {
                        randomizeSeats()
                    }) {
                        Label("随机排座", systemImage: "shuffle")
                    }
                    
                    Button(action: {
                        arrangeByGroup()
                    }) {
                        Label("按小组排座", systemImage: "rectangle.grid.2x2")
                    }
                    
                    Button(action: {
                        arrangeByScore()
                    }) {
                        Label("按成绩排座", systemImage: "chart.bar")
                    }
                }
                
                Section("小组颜色") {
                    ForEach(1...5, id: \.self) { group in
                        HStack {
                            Circle()
                                .fill(groupColor(group))
                                .frame(width: 20, height: 20)
                            Text("第\(group)组")
                            Spacer()
                            Text("\(viewModel.students(in: group).count)人")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("排座设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
    
    private func groupColor(_ group: Int) -> Color {
        switch group {
        case 1: return .blue
        case 2: return .green
        case 3: return .orange
        case 4: return .purple
        case 5: return .pink
        default: return .gray
        }
    }
    
    private func randomizeSeats() {
        let shuffled = viewModel.students.shuffled()
        for (index, student) in shuffled.enumerated() {
            let row = (index % 7) + 1
            let col = (index / 7) + 1
            viewModel.updateSeat(studentId: student.id, row: row, col: col)
        }
    }
    
    private func arrangeByGroup() {
        var index = 0
        for group in 1...5 {
            let students = viewModel.students(in: group)
            for student in students {
                let row = (index % 7) + 1
                let col = (index / 7) + 1
                viewModel.updateSeat(studentId: student.id, row: row, col: col)
                index += 1
            }
        }
    }
    
    private func arrangeByScore() {
        // 按月考总分排序
        let sorted = viewModel.students.sorted { student1, student2 in
            let score1 = viewModel.scoreRecords.filter { $0.studentId == student1.id }.reduce(0) { $0 + $1.score }
            let score2 = viewModel.scoreRecords.filter { $0.studentId == student2.id }.reduce(0) { $0 + $1.score }
            return score1 > score2
        }
        
        for (index, student) in sorted.enumerated() {
            let row = (index % 7) + 1
            let col = (index / 7) + 1
            viewModel.updateSeat(studentId: student.id, row: row, col: col)
        }
    }
}

#Preview {
    NavigationStack {
        SeatView()
            .environmentObject(AppViewModel())
    }
}
