import SwiftUI
import Photos

struct BatchExportView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var stamp: StampStore
    @EnvironmentObject var location: LocationManager
    @EnvironmentObject var store: ProStore
    @State private var assets: [PHAsset] = []
    @State private var selected = Set<String>()
    @State private var exporting = false
    @State private var progress = 0.0
    @State private var message = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.06, green: 0.06, blue: 0.06).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Image Grid
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 3), spacing: 3) {
                            ForEach(assets, id: \.localIdentifier) { asset in
                                AssetThumbnail(asset: asset)
                                    .overlay(alignment: .topTrailing) {
                                        ZStack {
                                            Circle()
                                                .fill(selected.contains(asset.localIdentifier) ? Color.yellow : Color.black.opacity(0.4))
                                                .frame(width: 24, height: 24)
                                                .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 1))
                                            
                                            if selected.contains(asset.localIdentifier) {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundStyle(.black)
                                            }
                                        }
                                        .padding(8)
                                    }
                                    .onTapGesture {
                                        if selected.contains(asset.localIdentifier) {
                                            selected.remove(asset.localIdentifier)
                                        } else {
                                            selected.insert(asset.localIdentifier)
                                        }
                                    }
                            }
                        }
                    }
                    
                    // Export Progress Panel
                    if exporting || !message.isEmpty {
                        VStack(spacing: 12) {
                            if exporting {
                                HStack {
                                    Text("Đang xử lý...")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Text("\(Int(progress * 100))%")
                                        .font(.system(.subheadline, design: .monospaced).bold())
                                        .foregroundStyle(.yellow)
                                }
                                
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(.white.opacity(0.1))
                                            .frame(height: 6)
                                        Capsule()
                                            .fill(
                                                LinearGradient(colors: [.yellow, .orange],
                                                               startPoint: .leading, endPoint: .trailing)
                                            )
                                            .frame(width: geo.size.width * CGFloat(progress), height: 6)
                                            .shadow(color: .yellow.opacity(0.3), radius: 4)
                                    }
                                }
                                .frame(height: 6)
                            }
                            
                            if !message.isEmpty {
                                Text(message)
                                    .font(.caption.bold())
                                    .foregroundStyle(message.contains("thành công") || message.contains("Đã") ? .yellow : .white.opacity(0.6))
                                    .padding(.top, 4)
                            }
                        }
                        .padding(.all, 18)
                        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.08), lineWidth: 1))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    }
                    
                    // Export Action Button
                    Button {
                        export()
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up.fill")
                                .font(.body.bold())
                            Text(selected.isEmpty ? "Chọn ảnh cần xuất" : "Xuất \(selected.count) ảnh đã chọn")
                                .font(.body.bold())
                        }
                        .foregroundStyle(selected.isEmpty || exporting ? .white.opacity(0.3) : .black)
                        .frame(maxWidth: .infinity)
                        .padding(.all, 18)
                        .background(selected.isEmpty || exporting ? Color.white.opacity(0.06) : Color.yellow, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(selected.isEmpty || exporting)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Batch Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Hủy") {
                        dismiss()
                    }
                    .foregroundStyle(.white.opacity(0.8))
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Chọn tất cả") {
                        if selected.count == assets.count {
                            selected.removeAll()
                        } else {
                            selected = Set(assets.map { $0.localIdentifier })
                        }
                    }
                    .foregroundStyle(.yellow)
                }
            }
            .task { load() }
        }
    }

    private func load() {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.fetchLimit = 100
        let result = PHAsset.fetchAssets(with: .image, options: options)
        var list: [PHAsset] = []
        result.enumerateObjects { asset, _, _ in list.append(asset) }
        assets = list
    }

    private func export() {
        guard store.isPro else {
            message = "Batch Export là tính năng Pro."
            return
        }

        exporting = true
        message = ""
        let targets = assets.filter { selected.contains($0.localIdentifier) }
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true

        let group = DispatchGroup()
        var images: [UIImage] = []

        for asset in targets {
            group.enter()
            PHImageManager.default().requestImage(
                for: asset, targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFit, options: options
            ) { image, _ in
                if let image { images.append(image) }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            for (index, image) in images.enumerated() {
                let stamped = StampRenderer.render(image: image, location: location,
                                                    style: stamp.style, logo: stamp.logo, map: nil)
                UIImageWriteToSavedPhotosAlbum(stamped, nil, nil, nil)
                progress = Double(index + 1) / Double(max(images.count, 1))
            }
            exporting = false
            message = "Đã đóng dấu thành công \(images.count) ảnh vào Thư viện."
        }
    }
}
