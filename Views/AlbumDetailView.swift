import SwiftUI
import PhotosUI

// 相册详情（渐变封面+按日期分组 - 对齐网页版）
struct AlbumDetailView: View {
    let folder: AlbumFolder
    @EnvironmentObject var viewModel: AppViewModel
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var selectedPhoto: AlbumPhoto?
    
    var photos: [AlbumPhoto] {
        viewModel.photos(in: folder)
    }
    
    var groupedPhotos: [(date: String, photos: [AlbumPhoto])] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年MM月dd日"
        
        let grouped = Dictionary(grouping: photos) { formatter.string(from: $0.date) }
        return grouped.sorted { $0.key > $1.key }.map { (date: $0.key, photos: $0.value) }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 渐变封面
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(
                        gradient: Gradient(colors: folder.coverGradient.compactMap { Color(hex: $0) }),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 280)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(folder.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text(formattedDate(folder.date))
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.9))
                        HStack(spacing: 8) {
                            Text(folder.category)
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(12)
                            Image(systemName: "photo")
                                .foregroundColor(.white)
                            Text("\(photos.count)张")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // 照片列表
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(groupedPhotos, id: \.date) { group in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(group.date)
                                .font(.title3)
                                .fontWeight(.bold)
                                .padding(.top, 8)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 8),
                                GridItem(.flexible(), spacing: 8),
                                GridItem(.flexible(), spacing: 8)
                            ], spacing: 8) {
                                ForEach(group.photos) { photo in
                                    Button(action: { selectedPhoto = photo }) {
                                        photoCell(photo)
                                    }
                                }
                            }
                        }
                    }
                    
                    if photos.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 64))
                                .foregroundColor(.gray)
                            Text("还没有照片")
                                .font(.title2)
                                .fontWeight(.medium)
                            Text("点击右下角按钮添加照片")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    }
                }
                .padding()
                .background(Color(.systemGroupedBackground))
                .cornerRadius(24, corners: [.topLeft, .topRight])
                .offset(y: -20)
            }
        }
        .background(Color(.systemGroupedBackground))
        .ignoresSafeArea(edges: .top)
        .navigationBarHidden(true)
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 16) {
                Button(action: {}) {
                    Image(systemName: "checkmark.circle")
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
                Button(action: {}) {
                    Image(systemName: "calendar")
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
            }
            .padding(.trailing, 16)
            .padding(.top, 60)
        }
        .overlay(alignment: .topLeading) {
            Button(action: {}) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
            .padding(.leading, 16)
            .padding(.top, 60)
        }
        .overlay(alignment: .bottomTrailing) {
            PhotosPicker(selection: $photoPickerItem, matching: .images) {
                Image(systemName: "plus")
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.blue)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
        .sheet(item: $selectedPhoto) { photo in
            PhotoDetailView(photo: photo)
        }
        .onChange(of: photoPickerItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    viewModel.addPhoto(image, title: "照片 \(photos.count + 1)", folderId: folder.id)
                }
                photoPickerItem = nil
            }
        }
    }
    
    private func photoCell(_ photo: AlbumPhoto) -> some View {
        ZStack(alignment: .bottomLeading) {
            if let image = viewModel.loadImage(for: photo) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 120)
                    .clipped()
            } else {
                LinearGradient(
                    gradient: Gradient(colors: [.orange, .yellow]),
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .frame(height: 120)
                .overlay(
                    VStack(spacing: 4) {
                        Text(photo.title).font(.caption).fontWeight(.medium).foregroundColor(.white)
                        Text(formattedDate(photo.date)).font(.system(size: 10)).foregroundColor(.white.opacity(0.8))
                    }
                )
            }
        }
        .cornerRadius(8)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "yyyy/M/d"
        return f.string(from: date)
    }
}

// 圆角扩展
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
