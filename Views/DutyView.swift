import SwiftUI

// 值日表（彩色卡片 - 对齐网页版）
struct DutyView: View {
    @EnvironmentObject var viewModel: AppViewModel
    
    let dayColors: [(bg: Color, border: Color, text: Color)] = [
        (Color.green.opacity(0.1), Color.green.opacity(0.3), Color.green),
        (Color.green.opacity(0.08), Color.green.opacity(0.2), Color.green),
        (Color.yellow.opacity(0.15), Color.yellow.opacity(0.4), Color.orange),
        (Color.purple.opacity(0.1), Color.purple.opacity(0.3), Color.purple),
        (Color.pink.opacity(0.1), Color.pink.opacity(0.3), Color.pink)
    ]
    
    let days = ["周一", "周二", "周三", "周四", "周五"]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("本周值日安排")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("周一至周五 · 每天一组轮流")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                .padding(.horizontal)
                
                if viewModel.dutyGroups.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checklist")
                            .font(.system(size: 64))
                            .foregroundColor(.gray)
                        Text("还没有值日安排")
                            .font(.title2)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else {
                    ForEach(0..<min(5, viewModel.dutyGroups.count), id: \.self) { index in
                        dutyDayCard(day: days[index], group: viewModel.dutyGroups[index], colors: dayColors[index])
                    }
                    
                    Text("周六、周日无值日安排")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("值日表")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func dutyDayCard(day: String, group: DutyGroup, colors: (bg: Color, border: Color, text: Color)) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(day)
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Text("第\(group.groupNumber)组")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(colors.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(colors.bg)
                    .cornerRadius(8)
            }
            
            HStack {
                FlexibleView(data: group.studentIds.map { viewModel.studentName(for: $0) }) { name in
                    Text(name)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white)
                        .cornerRadius(8)
                }
                Spacer()
                Text("\(group.studentIds.count)人")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(colors.bg)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(colors.border, lineWidth: 1)
        )
        .padding(.horizontal)
    }
}

// 流式布局（使用 iOS 16 Layout 协议，更稳定）
struct FlexibleView<Data: Collection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let content: (Data.Element) -> Content
    
    var body: some View {
        WrappingHStackLayout {
            ForEach(Array(data), id: \.self) { item in
                content(item)
                    .padding(.trailing, 8)
                    .padding(.bottom, 8)
            }
        }
    }
}

// 自动换行的 HStack Layout
struct WrappingHStackLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 300
        var height: CGFloat = 0
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > width && rowWidth > 0 {
                height += rowHeight
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width
            rowHeight = max(rowHeight, size.height)
        }
        height += rowHeight
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                x = bounds.minX
                y += rowHeight
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width
            rowHeight = max(rowHeight, size.height)
        }
    }
}
