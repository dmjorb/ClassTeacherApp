import SwiftUI
import MapKit

// 学生位置标记
struct StudentLocation: Identifiable {
    let id = UUID()
    let student: Student
    var coordinate: CLLocationCoordinate2D
}

// 分布地图 - MapKit 真实地图，显示学生家庭住址
struct MapView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var selectedStudent: Student?
    @State private var mapType: MKMapType = .standard
    @State private var showStats = true
    
    // 有经纬度的学生
    var studentsWithLocation: [StudentLocation] {
        viewModel.students.compactMap { student in
            guard let lat = student.latitude, let lon = student.longitude else { return nil }
            return StudentLocation(student: student, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }
    }
    
    // 地图区域（郑州市中心）
    var mapRegion: MKCoordinateRegion {
        if let first = studentsWithLocation.first {
            return MKCoordinateRegion(
                center: first.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
        }
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 34.7466, longitude: 113.6254),
            span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
        )
    }
    
    // 按区域分组
    var districtGroups: [String: [Student]] {
        var groups: [String: [Student]] = [:]
        for student in viewModel.students {
            let district = extractDistrict(from: student.address)
            groups[district, default: []].append(student)
        }
        return groups
    }
    
    var body: some View {
        Group {
            if viewModel.students.isEmpty {
                emptyState
            } else if studentsWithLocation.isEmpty {
                noLocationState
            } else {
                mapContent
            }
        }
        .navigationTitle("分布地图")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedStudent) { student in
            StudentLocationDetailView(student: student)
        }
    }
    
    // 地图内容
    private var mapContent: some View {
        ZStack(alignment: .top) {
            // 真实地图
            Map(coordinateRegion: .constant(mapRegion), showsUserLocation: false, annotationItems: studentsWithLocation) { location in
                MapAnnotation(coordinate: location.coordinate) {
                    Button(action: {
                        selectedStudent = location.student
                    }) {
                        VStack(spacing: 2) {
                            Circle()
                                .fill(location.student.gender == .male ? Color.blue : Color.pink)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Text(String(location.student.name.prefix(1)))
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                )
                                .shadow(radius: 2)
                            
                            Text(location.student.name)
                                .font(.system(size: 10))
                                .fontWeight(.medium)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.white)
                                .cornerRadius(4)
                                .shadow(radius: 1)
                        }
                    }
                }
            }
            .ignoresSafeArea(edges: .bottom)
            
            // 顶部统计卡片
            if showStats {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        statCard(title: "学生总数", value: "\(viewModel.students.count)", icon: "person.2.fill", color: .blue)
                        statCard(title: "已定位", value: "\(studentsWithLocation.count)", icon: "location.fill", color: .green)
                        statCard(title: "覆盖区域", value: "\(districtGroups.count)", icon: "map.fill", color: .orange)
                        statCard(title: "住校生", value: "\(viewModel.students.filter { !$0.dormitory.isEmpty }.count)", icon: "house.fill", color: .purple)
                    }
                    .padding()
                }
                .background(Color(.systemBackground).opacity(0.95))
                .shadow(radius: 2)
            }
            
            // 右下角工具按钮
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        // 切换地图类型
                        Button(action: {
                            mapType = mapType == .standard ? .satellite : .standard
                        }) {
                            Image(systemName: mapType == .standard ? "globe" : "map")
                                .font(.system(size: 20))
                                .foregroundColor(.primary)
                                .frame(width: 44, height: 44)
                                .background(Color(.systemBackground))
                                .cornerRadius(8)
                                .shadow(radius: 2)
                        }
                        
                        // 显示/隐藏统计
                        Button(action: {
                            withAnimation {
                                showStats.toggle()
                            }
                        }) {
                            Image(systemName: showStats ? "eye.slash" : "eye")
                                .font(.system(size: 20))
                                .foregroundColor(.primary)
                                .frame(width: 44, height: 44)
                                .background(Color(.systemBackground))
                                .cornerRadius(8)
                                .shadow(radius: 2)
                        }
                        
                        // 回到郑州中心
                        Button(action: {
                            // 触发地图更新
                        }) {
                            Image(systemName: "location")
                                .font(.system(size: 20))
                                .foregroundColor(.primary)
                                .frame(width: 44, height: 44)
                                .background(Color(.systemBackground))
                                .cornerRadius(8)
                                .shadow(radius: 2)
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    // 空状态 - 没有学生
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "map")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("还没有学生数据")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("先在学生名册中添加学生，才能查看分布地图")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    // 没有位置信息
    private var noLocationState: some View {
        VStack(spacing: 20) {
            Image(systemName: "location.slash")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("学生没有位置信息")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("在学生详情中填写家庭住址的经纬度，才能在地图上显示")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
            }
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    // 从地址提取区域
    private func extractDistrict(from address: String) -> String {
        if address.isEmpty { return "未填写" }
        if let range = address.range(of: "市") {
            let afterCity = address[range.upperBound...]
            if let districtRange = afterCity.range(of: "区") {
                return String(afterCity[..<districtRange.upperBound])
            }
        }
        return "其他区域"
    }
}

// 学生位置详情
struct StudentLocationDetailView: View {
    let student: Student
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("学生信息") {
                    HStack {
                        Circle()
                            .fill(student.gender == .male ? Color.blue.opacity(0.2) : Color.pink.opacity(0.2))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Text(String(student.name.prefix(1)))
                                    .font(.headline)
                                    .foregroundColor(student.gender == .male ? .blue : .pink)
                            )
                        VStack(alignment: .leading, spacing: 4) {
                            Text(student.name)
                                .font(.headline)
                            Text("学号：\(student.studentNumber)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section("家庭住址") {
                    if !student.address.isEmpty {
                        Label(student.address, systemImage: "location.fill")
                            .font(.subheadline)
                    } else {
                        Text("未填写住址")
                            .foregroundColor(.secondary)
                    }
                    
                    if let lat = student.latitude, let lon = student.longitude {
                        HStack {
                            Text("纬度")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.6f", lat))
                        }
                        HStack {
                            Text("经度")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.6f", lon))
                        }
                        
                        // 小地图预览
                        if #available(iOS 17.0, *) {
                            Map(coordinateRegion: .constant(MKCoordinateRegion(
                                center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                            )), annotationItems: [StudentLocation(student: student, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))]) { loc in
                                MapAnnotation(coordinate: loc.coordinate) {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundColor(.red)
                                        .font(.title)
                                }
                            }
                            .frame(height: 200)
                            .cornerRadius(8)
                            .listRowInsets(EdgeInsets())
                        }
                    } else {
                        Text("未设置经纬度")
                            .foregroundColor(.secondary)
                    }
                }
                
                if !student.parentPhone.isEmpty {
                    Section("联系家长") {
                        Button(action: {
                            if let url = URL(string: "tel://\(student.parentPhone)") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Label("拨打家长电话：\(student.parentPhone)", systemImage: "phone.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("位置详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        MapView()
            .environmentObject(AppViewModel())
    }
}
