import SwiftUI
import PhotosUI
import UIKit

// 班级相册列表
struct AlbumListView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showingNewAlbum = false
    @State private var newAlbumName = ""
    @State private var newAlbumCategory = "班级活动"

    private var sortedFolders: [AlbumFolder] {
        viewModel.albumFolders.sorted {
            if $0.isPinned != $1.isPinned { return $0.isPinned }
            return $0.id.uuidString < $1.id.uuidString
        }
    }

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        Group {
            if sortedFolders.isEmpty {
                EmptyStateView(
                    systemImage: "photo.on.rectangle.angled",
                    title: "还没有相册",
                    message: "点击右上角 + 新建相册，记录班级点滴"
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(sortedFolders) { folder in
                            NavigationLink {
                                AlbumDetailView(folderId: folder.id)
                            } label: {
                                AlbumCard(folder: folder)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    viewModel.deleteAlbum(folder)
                                } label: {
                                    Label("删除相册", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
            }
        }
        .navigationTitle("班级相册")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNewAlbum = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("新建相册", isPresented: $showingNewAlbum) {
            TextField("相册名称", text: $newAlbumName)
            Button("取消", role: .cancel) {
                newAlbumName = ""
            }
            Button("创建") {
                let name = newAlbumName.trimmingCharacters(in: .whitespaces)
                if !name.isEmpty {
                    viewModel.addAlbum(name: name, category: newAlbumCategory)
                }
                newAlbumName = ""
            }
        } message: {
            Text("为相册起一个名字，创建后可以添加照片。")
        }
    }
}

// 相册卡片（渐变封面由名称稳定生成）
struct AlbumCard: View {
    @EnvironmentObject var viewModel: AppViewModel
    let folder: AlbumFolder

    private var gradient: LinearGradient {
        let palette: [(Color, Color)] = [
            (.blue, .purple), (.orange, .pink), (.green, .mint), (.purple, .indigo), (.pink, .red)
        ]
        var hash = 0
        for scalar in folder.name.unicodeScalars {
            hash = (hash &* 31 &+ Int(scalar.value)) & 0x7fffffff
        }
        let pair = palette[hash % palette.count]
        return LinearGradient(colors: [pair.0, pair.1], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(gradient)
                    .frame(height: 90)
                    .overlay(
                        Image(systemName: "photo.stack.fill")
                            .font(.title)
                            .foregroundColor(.white.opacity(0.6))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    )
                if folder.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(6)
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(folder.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text("\(viewModel.photos(in: folder).count) 张照片 · \(folder.category)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 4)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// 相册详情（照片网格 + 添加照片）
struct AlbumDetailView: View {
    @EnvironmentObject var viewModel: AppViewModel
    let folderId: UUID

    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var viewingPhotoId: UUID?
    @State private var isAdding = false

    private var folder: AlbumFolder? { viewModel.albumFolders.first { $0.id == folderId } }
    private var photos: [AlbumPhoto] {
        guard let folder = folder else { return [] }
        return viewModel.photos(in: folder)
    }

    private let columns = [GridItem(.flexible(), spacing: 4), GridItem(.flexible(), spacing: 4), GridItem(.flexible(), spacing: 4)]

    var body: some View {
        Group {
            if let folder = folder {
                Group {
                    if photos.isEmpty {
                        EmptyStateView(
                            systemImage: "photo.badge.plus",
                            title: "相册还是空的",
                            message: "点击右上角 + 从相册选择照片"
                        )
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 4) {
                                ForEach(photos) { photo in
                                    Button {
                                        viewingPhotoId = photo.id
                                    } label: {
                                        PhotoThumbView(photoId: photo.id)
                                            .frame(height: 110)
                                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding()
                        }
                        .background(Color(.systemGroupedBackground))
                    }
                }
                .navigationTitle(folder.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        PhotosPicker(selection: $pickerItems, maxSelectionCount: 9, matching: .images) {
                            Image(systemName: "plus")
                        }
                        .disabled(isAdding)
                    }
                }
                .onChange(of: pickerItems) { items in
                    guard !items.isEmpty else { return }
                    isAdding = true
                    let folderId = folder.id
                    Task {
                        for item in items {
                            if let data = try? await item.loadTransferable(type: Data.self) {
                                await MainActor.run {
                                    viewModel.addPhoto(data: data, folderId: folderId)
                                }
                            }
                        }
                        await MainActor.run {
                            pickerItems = []
                            isAdding = false
                        }
                    }
                }
                .sheet(item: Binding(
                    get: { viewingPhotoId.map { PhotoRef(id: $0) } },
                    set: { viewingPhotoId = $0?.id }
                )) { ref in
                    NavigationStack {
                        PhotoDetailView(photoId: ref.id)
                    }
                }
            } else {
                EmptyStateView(systemImage: "photo.on.rectangle.angled", title: "相册不存在", message: "该相册可能已被删除")
            }
        }
    }
}

// sheet item 包装（UUID 不满足 Identifiable 的关联需求时保持稳定标识）
private struct PhotoRef: Identifiable {
    let id: UUID
}

// 照片缩略图（从本地存储加载）
struct PhotoThumbView: View {
    @EnvironmentObject var viewModel: AppViewModel
    let photoId: UUID
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(Color(.tertiarySystemGroupedBackground))
                    .overlay(ProgressView())
            }
        }
        .onAppear {
            if image == nil {
                image = viewModel.photoData(id: photoId).flatMap(UIImage.init(data:))
            }
        }
    }
}

// 照片详情（大图 + 备注 + 删除）
struct PhotoDetailView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    let photoId: UUID

    @State private var note = ""
    @State private var showingDeleteConfirm = false

    private var photo: AlbumPhoto? { viewModel.albumPhotos.first { $0.id == photoId } }

    var body: some View {
        Group {
            if let photo = photo {
                VStack(spacing: 16) {
                    PhotoThumbView(photoId: photo.id)
                        .frame(maxHeight: 420)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.horizontal)

                    Form {
                        Section("照片信息") {
                            LabeledContent("添加时间", value: photo.date.formatted(.dateTime.year().month().day().hour().minute()))
                            TextField("备注（如：运动会入场式）", text: $note, axis: .vertical)
                        }
                        Section {
                            Button("保存备注") {
                                var updated = photo
                                updated.note = note
                                viewModel.updatePhoto(updated)
                            }
                            .disabled(note == photo.note)
                        }
                    }
                    .frame(maxHeight: 220)
                }
                .padding(.top)
                .navigationTitle("照片详情")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button(role: .destructive) {
                            showingDeleteConfirm = true
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
                .confirmationDialog("删除这张照片？", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
                    Button("删除", role: .destructive) {
                        viewModel.deletePhoto(photo)
                        dismiss()
                    }
                    Button("取消", role: .cancel) {}
                }
                .onAppear {
                    note = photo.note
                }
            } else {
                EmptyStateView(systemImage: "photo", title: "照片不存在", message: "该照片可能已被删除")
            }
        }
    }
}
