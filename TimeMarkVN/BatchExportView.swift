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
                                    Text(NSLocalizedString("Đang xử lý...", comment: ""))
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
                                    .foregroundStyle(message.contains("thành công") || message.contains("Đã") || message.contains("Successfully") ? .yellow : .white.opacity(0.6))
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
                            Text(selected.isEmpty ? NSLocalizedString("Chọn ảnh cần xuất", comment: "") : String(format: NSLocalizedString("Xuất %d ảnh đã chọn", comment: ""), selected.count))
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
            .navigationTitle(NSLocalizedString("Batch export", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(NSLocalizedString("Hủy", comment: "")) {
                        dismiss()
                    }
                    .foregroundStyle(.white.opacity(0.8))
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(NSLocalizedString("Chọn tất cả", comment: "")) {
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

    private func getAddress(for location: CLLocation?, completion: @escaping (String) -> Void) {
        guard let location = location else {
            completion(NSLocalizedString("Không có vị trí", comment: ""))
            return
        }
        CLGeocoder().reverseGeocodeLocation(location) { places, _ in
            if let p = places?.first {
                let parts = [p.name, p.subLocality, p.locality, p.administrativeArea].compactMap { $0 }
                completion(parts.joined(separator: ", "))
            } else {
                completion(String(format: "%.6f, %.6f", location.coordinate.latitude, location.coordinate.longitude))
            }
        }
    }

    private func export() {
        guard store.isPro else {
            message = NSLocalizedString("Batch Export là tính năng Pro.", comment: "")
            return
        }

        exporting = true
        message = ""
        let targets = assets.filter { selected.contains($0.localIdentifier) }
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true

        var index = 0
        
        func processNext() {
            guard index < targets.count else {
                DispatchQueue.main.async {
                    self.exporting = false
                    self.message = String(format: NSLocalizedString("Đã đóng dấu thành công %d ảnh vào Thư viện.", comment: ""), targets.count)
                }
                return
            }
            
            let asset = targets[index]
            
            PHImageManager.default().requestImage(
                for: asset, targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFit, options: options
            ) { image, _ in
                guard let image = image else {
                    index += 1
                    processNext()
                    return
                }
                
                let assetLoc = asset.location
                let assetDate = asset.creationDate ?? assetLoc?.timestamp ?? Date()
                
                self.getAddress(for: assetLoc) { address in
                    let telemetry = EXIFTelemetry(
                        coordinate: assetLoc?.coordinate,
                        address: address,
                        altitude: assetLoc?.altitude ?? 0,
                        gpsTimestamp: assetDate
                    )
                    
                    let stamped = StampRenderer.render(
                        image: image,
                        location: telemetry,
                        style: self.stamp.style,
                        logo: self.stamp.logo,
                        map: nil
                    )
                    
                    UIImageWriteToSavedPhotosAlbum(stamped, nil, nil, nil)
                    
                    DispatchQueue.main.async {
                        self.progress = Double(index + 1) / Double(targets.count)
                        index += 1
                        processNext()
                    }
                }
            }
        }
        
        processNext()
    }
}

struct EXIFTelemetry: TelemetryData {
    var coordinate: CLLocationCoordinate2D?
    var address: String
    var altitude: Double
    var heading: Double = 0
    var accuracy: Double = 0
    var temperature: String = "--°C"
    var weatherText: String = ""
    var isTimeSpoofed: Bool = false
    var isGpsSimulated: Bool = false
    var gpsTimestamp: Date?
    var isOffline: Bool = false
}
}
