import SwiftUI

// 班级课表（周视图网格 - 对齐网页版）
struct ScheduleView: View {
    @EnvironmentObject var viewModel: AppViewModel
    
    let days = ["周一", "周二", "周三", "周四", "周五"]
    let periods = [
        (1, "08:00", "08:45"), (2, "08:55", "09:40"),
        (3, "10:00", "10:45"), (4, "10:55", "11:40"),
        (5, "14:00", "14:45"), (6, "14:55", "15:40"),
        (7, "15:50", "16:35"), (8, "16:45", "17:30")
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("2026-2027学年 上学期")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top)
                
                VStack(spacing: 2) {
                    HStack(spacing: 2) {
                        Text("").frame(width: 60, height: 50)
                        ForEach(days, id: \.self) { day in
                            Text(day).font(.subheadline).fontWeight(.medium)
                                .frame(maxWidth: .infinity).frame(height: 50)
                                .background(Color(.systemGray6))
                        }
                    }
                    
                    ForEach(0..<8, id: \.self) { periodIndex in
                        if periodIndex == 4 {
                            HStack(spacing: 2) {
                                Text("午休").font(.caption).foregroundColor(.orange).frame(width: 60, height: 30)
                                Text("午 休").font(.subheadline).fontWeight(.medium).foregroundColor(.orange)
                                    .frame(maxWidth: .infinity).frame(height: 30)
                                    .background(Color.orange.opacity(0.1))
                            }
                        }
                        
                        HStack(spacing: 2) {
                            VStack(spacing: 2) {
                                Text("第\(periods[periodIndex].0)节").font(.caption2).fontWeight(.medium)
                                Text(periods[periodIndex].1).font(.system(size: 8)).foregroundColor(.secondary)
                                Text(periods[periodIndex].2).font(.system(size: 8)).foregroundColor(.secondary)
                            }
                            .frame(width: 60, height: 60).background(Color(.systemGray6))
                            
                            ForEach(1...5, id: \.self) { day in
                                if let course = viewModel.course(for: day, period: periods[periodIndex].0) {
                                    courseCell(course)
                                } else {
                                    Color.clear.frame(maxWidth: .infinity).frame(height: 60)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("图例").font(.caption).foregroundColor(.secondary)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                        ForEach(subjectColors, id: \.name) { item in
                            HStack(spacing: 4) {
                                Circle().fill(item.color).frame(width: 10, height: 10)
                                Text(item.name).font(.caption2)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("班级课表")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func courseCell(_ course: Course) -> some View {
        let isMyCourse = viewModel.isMyCourse(course)
        return VStack(spacing: 2) {
            Text(course.subject).font(.caption).fontWeight(.medium)
                .foregroundColor(isMyCourse ? .white : subjectColor(course.subject))
            if isMyCourse {
                Image(systemName: "star.fill").font(.system(size: 8)).foregroundColor(.yellow)
            }
        }
        .frame(maxWidth: .infinity).frame(height: 60)
        .background(isMyCourse ? Color.orange : subjectColor(course.subject).opacity(0.15))
        .cornerRadius(6)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(isMyCourse ? Color.orange : Color.clear, lineWidth: 2))
    }
    
    private func subjectColor(_ subject: String) -> Color {
        subjectColors.first { $0.name == subject }?.color ?? .gray
    }
    
    private var subjectColors: [(name: String, color: Color)] {
        [
            ("语文", .red), ("数学", .blue), ("英语", .green),
            ("物理", .orange), ("化学", .purple), ("生物", .mint),
            ("政治", .pink), ("历史", .brown), ("地理", .teal),
            ("体育", .indigo), ("音乐", .cyan), ("美术", .yellow),
            ("信息", .blue), ("劳动", .green), ("自习", .gray), ("班会", .orange)
        ]
    }
}
