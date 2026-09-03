import SwiftUI
import PhotosUI

// 相册列表（多相册 - 对齐网页版）
struct AlbumListView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var selectedFolder: AlbumFolder?
    @State private var showingNewFolder = false
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var showingFolderSelection = false
    @State private var targetFolderId: UUID?
    @State private var showingPhotoPicker = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("\(viewModel.albumFolders.count)相册 \(viewModel.albumPhotos.count)图片")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top)
                    .padding(.horizontal)
                
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                    // 新建相册
                    Button(action: { showingNewFolder = true }) {
                        VStack(spacing: 12) {
                            Image(systemName: "square.on.square")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("新建相册")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                                .foregroundColor(.gray.opacity(0.3))
                        )
                    }
                    
                    // 相册列表
                    ForEach(viewModel.albumFolders) { folder in
                        Button(action: { selectedFolder = folder }) {
                            albumCard(folder)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("班级相册")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .bottomTrailing) {
            Button(action: {
                if viewModel.albumFolders.isEmpty {
                    showingNewFolder = true
                } else if viewModel.albumFolders.count == 1 {
                    targetFolderId = viewModel.albumFolders.first?.id
                    showingPhotoPicker = true
                } else {
                    showingFolderSelection = true
                }
            }) {
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
        .sheet(item: $selectedFolder) { folder in
            AlbumDetailView(folder: folder)
        }
        .sheet(isPresented: $showingNewFolder) {
            NewAlbumFolderView()
        }
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoPickerSheet(photoPickerItem: $photoPickerItem)
        }
        .confirmationDialog("选择相册", isPresented: $showingFolderSelection, titleVisibility: .visible) {
            ForEach(viewModel.albumFolders) { folder in
                Button(folder.name) {
                    targetFolderId = folder.id
                    showingPhotoPicker = true
                }
            }
            Button("取消", role: .cancel) {}
        }
        .onChange(of: photoPickerItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    viewModel.addPhoto(image, title: "照片 \(viewModel.albumPhotos.count + 1)", folderId: targetFolderId)
                    targetFolderId = nil
                }
                photoPickerItem = nil
            }
        }
    }
    
    private func albumCard(_ folder: AlbumFolder) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                LinearGradient(
                    gradient: Gradient(colors: folder.coverGradient.compactMap { Color(hex: $0) }),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 160)
                
                if folder.isPinned {
                    Text("顶")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .cornerRadius(12)
                        .padding(8)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Spacer()
                    Text(folder.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text(formattedDate(folder.date))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("\(folder.photoIds.count)张")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.trailing, 12)
                    .padding(.bottom, 12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }
            
            Text(folder.category)
                .font(.subheadline)
                .foregroundColor(.primary)
                .padding(.vertical, 8)
                .padding(.leading, 4)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "yyyy/M/d"
        return f.string(from: date)
    }
}

// 新建相册
struct NewAlbumFolderView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: AppViewModel
    
    @State private var folderName = ""
    @State private var category = "班级活动"
    @State private var selectedColorIndex = 0
    
    let categories = ["班级活动", "学习日常", "荣誉墙"]
    let colorOptions: [[String]] = [
        ["#FF6B6B", "#FFE66D"],
        ["#FF8A5C", "#FFD93D"],
        ["#667EEA", "#764BA2"],
        ["#43E97B", "#38F9D7"],
        ["#FA709A", "#FEE140"]
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("相册信息") {
                    TextField("相册名称", text: $folderName)
                    Picker("分类", selection: $category) {
                        ForEach(categories, id: \.self) { Text($0).tag($0) }
                    }
                }
                Section("封面颜色") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(0..<colorOptions.count, id: \.self) { index in
                                Button(action: { selectedColorIndex = index }) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(LinearGradient(
                                            gradient: Gradient(colors: colorOptions[index].compactMap { Color(hex: $0) }),
                                            startPoint: .topLeading, endPoint: .bottomTrailing
                                        ))
                                        .frame(width: 60, height: 60)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(selectedColorIndex == index ? Color.blue : Color.clear, lineWidth: 3)
                                        )
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("新建相册")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("创建") {
                        if !folderName.isEmpty {
                            viewModel.addAlbumFolder(name: folderName, category: category, coverGradient: colorOptions[selectedColorIndex])
                            dismiss()
                        }
                    }
                    .disabled(folderName.isEmpty)
                }
            }
        }
    }
}

// Color hex 扩展
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        let scanner = Scanner(string: hex)
        scanner.scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            // 格式错误时返回灰色，避免崩溃
            (a, r, g, b) = (255, 128, 128, 128)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

// 照片选择器 Sheet
struct PhotoPickerSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var photoPickerItem: PhotosPickerItem?
    
    var body: some View {
        NavigationStack {
            VStack {
                PhotosPicker(selection: $photoPickerItem, matching: .images) {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 64))
                            .foregroundColor(.blue)
                        Text("选择照片")
                            .font(.title2)
                            .fontWeight(.medium)
                        Text("点击从相册选择照片")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("选择照片")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
            .onChange(of: photoPickerItem) { _ in
                if photoPickerItem != nil {
                    dismiss()
                }
            }
        }
    }
}
