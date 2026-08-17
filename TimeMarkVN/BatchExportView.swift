import SwiftUI
import Photos

struct BatchExportView: View {
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
            VStack {
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 3), spacing: 3) {
                        ForEach(assets, id: \.localIdentifier) { asset in
                            AssetThumbnail(asset: asset)
                                .overlay(alignment: .topTrailing) {
                                    Image(systemName: selected.contains(asset.localIdentifier) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selected.contains(asset.localIdentifier) ? .yellow : .white)
                                        .padding(6)
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

                if exporting { ProgressView(value: progress).padding() }
                if !message.isEmpty { Text(message).font(.caption).foregroundStyle(.secondary) }

                Button("Xuất \(selected.count) ảnh") { export() }
                    .buttonStyle(.borderedProminent)
                    .disabled(selected.isEmpty || exporting)
                    .padding()
            }
            .navigationTitle("Batch Export")
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
            message = "Đã xuất \(images.count) ảnh."
        }
    }
}
