import SwiftUI
import Photos

struct GalleryView: View {
    @State private var assets: [PHAsset] = []
    @State private var selected: PHAsset?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 3), spacing: 3) {
                    ForEach(assets, id: \.localIdentifier) { asset in
                        AssetThumbnail(asset: asset)
                            .onTapGesture { selected = asset }
                    }
                }
            }
            .navigationTitle("Thư viện")
            .toolbar { Button("Làm mới") { load() } }
            .task { load() }
            .sheet(isPresented: Binding(
                get: { selected != nil },
                set: { if !$0 { selected = nil } }
            )) {
                if let asset = selected {
                    AssetDetailView(asset: asset)
                }
            }
        }
    }

    private func load() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            guard status == .authorized || status == .limited else { return }
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            options.fetchLimit = 200
            let result = PHAsset.fetchAssets(with: .image, options: options)
            var list: [PHAsset] = []
            result.enumerateObjects { asset, _, _ in list.append(asset) }
            DispatchQueue.main.async { assets = list }
        }
    }
}

struct AssetThumbnail: View {
    let asset: PHAsset
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image { Image(uiImage: image).resizable().scaledToFill() }
            else { Color.gray.opacity(0.2) }
        }
        .frame(height: 125)
        .clipped()
        .task {
            let options = PHImageRequestOptions()
            options.deliveryMode = .fastFormat
            options.isNetworkAccessAllowed = true
            PHImageManager.default().requestImage(
                for: asset, targetSize: CGSize(width: 500, height: 500),
                contentMode: .aspectFill, options: options
            ) { image, _ in self.image = image }
        }
    }
}

struct AssetDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let asset: PHAsset
    @State private var image: UIImage?
    @State private var share = false

    var body: some View {
        NavigationStack {
            Group {
                if let image { Image(uiImage: image).resizable().scaledToFit() }
                else { ProgressView() }
            }
            .background(.black)
            .navigationTitle("Ảnh")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Đóng") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Chia sẻ") { share = true }
                }
            }
            .task {
                PHImageManager.default().requestImage(
                    for: asset, targetSize: PHImageManagerMaximumSize,
                    contentMode: .aspectFit, options: nil
                ) { image, _ in self.image = image }
            }
            .sheet(isPresented: $share) {
                if let image { ShareSheet(items: [image]) }
            }
        }
    }
}
