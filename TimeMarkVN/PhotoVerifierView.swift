import SwiftUI
import PhotosUI
import MapKit
import ImageIO

struct PhotoVerifierView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var pickerItem: PhotosPickerItem?
    @State private var pickedImage: UIImage?
    @State private var pickedData: Data?
    
    @State private var gpsCoordinate: CLLocationCoordinate2D?
    @State private var exifDate: String?
    @State private var gpsAltitude: Double?
    @State private var cameraModel: String?
    @State private var isMetadataLoaded = false
    @State private var isGpsFound = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.06, green: 0.06, blue: 0.06).ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        PhotosPicker(selection: $pickerItem, matching: .images) {
                            VStack(spacing: 12) {
                                if let pickedImage {
                                    Image(uiImage: pickedImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxHeight: 250)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                        .shadow(radius: 8)
                                } else {
                                    VStack(spacing: 14) {
                                        Image(systemName: "photo.badge.arrow.down.fill")
                                            .font(.system(size: 40))
                                            .foregroundStyle(.yellow)
                                        
                                        Text(NSLocalizedString("Chọn ảnh cần thẩm định", comment: ""))
                                            .font(.headline.bold())
                                            .foregroundStyle(.white)
                                        
                                        Text(NSLocalizedString("Nhập ảnh hiện trường để kiểm tra độ tin cậy của GPS & thời gian", comment: ""))
                                            .font(.caption)
                                            .foregroundStyle(.white.opacity(0.5))
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 24)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                                    .background(.white.opacity(0.02), in: RoundedRectangle(cornerRadius: 16))
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.08), lineWidth: 1))
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        
                        if isMetadataLoaded {
                            HStack {
                                Image(systemName: isGpsFound ? "checkmark.seal.fill" : "exclamationmark.shield.fill")
                                    .font(.title2)
                                    .foregroundStyle(isGpsFound ? .green : .red)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(isGpsFound ? NSLocalizedString("ẢNH HỢP LỆ", comment: "") : NSLocalizedString("CHƯA ĐƯỢC XÁC THỰC", comment: ""))
                                        .font(.headline.bold())
                                        .foregroundStyle(isGpsFound ? .green : .red)
                                    
                                    Text(isGpsFound ? NSLocalizedString("Dữ liệu vị trí và thời gian EXIF khớp tiêu chuẩn bảo mật.", comment: "") : NSLocalizedString("Không tìm thấy dữ liệu GPS hoặc siêu dữ liệu đã bị xóa.", comment: ""))
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.6))
                                }
                                Spacer()
                            }
                            .padding(.all, 16)
                            .background(isGpsFound ? Color.green.opacity(0.08) : Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(isGpsFound ? Color.green.opacity(0.24) : Color.red.opacity(0.24), lineWidth: 1))
                            .padding(.horizontal, 20)
                            
                            VStack(alignment: .leading, spacing: 14) {
                                Text(NSLocalizedString("SIÊU DỮ LIỆU EXIF", comment: ""))
                                    .font(.system(.caption, design: .monospaced).bold())
                                    .foregroundStyle(.white.opacity(0.4))
                                    .tracking(1.5)
                                
                                VStack(spacing: 12) {
                                    MetadataRow(icon: "calendar", title: NSLocalizedString("Thời gian chụp", comment: ""), value: exifDate ?? NSLocalizedString("N/A", comment: ""))
                                    Divider().background(.white.opacity(0.08))
                                    
                                    MetadataRow(icon: "location.circle", title: NSLocalizedString("Tọa độ GPS", comment: ""), value: gpsCoordinate != nil ? String(format: "%.6f°, %.6f°", gpsCoordinate!.latitude, gpsCoordinate!.longitude) : NSLocalizedString("Không có", comment: ""))
                                    Divider().background(.white.opacity(0.08))
                                    
                                    MetadataRow(icon: "mountain.2", title: NSLocalizedString("Độ cao", comment: ""), value: gpsAltitude != nil ? String(format: "%.1f m", gpsAltitude!) : NSLocalizedString("Không có", comment: ""))
                                    Divider().background(.white.opacity(0.08))
                                    
                                    MetadataRow(icon: "iphone", title: NSLocalizedString("Thiết bị", comment: ""), value: cameraModel ?? NSLocalizedString("N/A", comment: ""))
                                }
                                .padding(.all, 18)
                                .background(.white.opacity(0.02), in: RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.06), lineWidth: 1))
                            }
                            .padding(.horizontal, 20)
                            
                            if let coord = gpsCoordinate {
                                VStack(alignment: .leading, spacing: 14) {
                                    Text(NSLocalizedString("BẢN ĐỒ VỊ TRÍ", comment: ""))
                                        .font(.system(.caption, design: .monospaced).bold())
                                        .foregroundStyle(.white.opacity(0.4))
                                        .tracking(1.5)
                                    
                                    Map(position: .constant(MapCameraPosition.region(MKCoordinateRegion(center: coord, latitudinalMeters: 500, longitudinalMeters: 500)))) {
                                        Marker(NSLocalizedString("Vị trí chụp", comment: ""), coordinate: coord)
                                            .tint(.yellow)
                                    }
                                    .frame(height: 180)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.08), lineWidth: 1))
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle(NSLocalizedString("Thẩm định ảnh", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(NSLocalizedString("Đóng", comment: "")) {
                        dismiss()
                    }
                    .foregroundStyle(.white.opacity(0.8))
                }
            }
            .onChange(of: pickerItem) { oldValue, newValue in
                guard let newValue else { return }
                loadMetadata(from: newValue)
            }
        }
    }

    private func loadMetadata(from item: PhotosPickerItem) {
        item.loadTransferable(type: Data.self) { result in
            switch result {
            case .success(let data):
                guard let data = data else { return }
                DispatchQueue.main.async {
                    self.pickedData = data
                    self.pickedImage = UIImage(data: data)
                    self.parseEXIF(from: data)
                }
            case .failure(let error):
                print("Failed to load image data: \(error)")
            }
        }
    }

    private func parseEXIF(from data: Data) {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            exifDate = nil
            gpsCoordinate = nil
            gpsAltitude = nil
            cameraModel = nil
            isGpsFound = false
            isMetadataLoaded = true
            return
        }
        
        let tiff = properties[kCGImagePropertyTIFFDictionary as String] as? [String: Any]
        let make = tiff?[kCGImagePropertyTIFFMake as String] as? String ?? ""
        let model = tiff?[kCGImagePropertyTIFFModel as String] as? String ?? ""
        cameraModel = make.isEmpty && model.isEmpty ? nil : "\(make) \(model)".trimmingCharacters(in: .whitespacesAndNewlines)
        
        exifDate = tiff?[kCGImagePropertyTIFFDateTime as String] as? String
        
        if let gps = properties[kCGImagePropertyGPSDictionary as String] as? [String: Any] {
            let latVal = gps[kCGImagePropertyGPSLatitude as String] as? Double
            let latRef = gps[kCGImagePropertyGPSLatitudeRef as String] as? String
            let lonVal = gps[kCGImagePropertyGPSLongitude as String] as? Double
            let lonRef = gps[kCGImagePropertyGPSLongitudeRef as String] as? String
            
            if let lat = latVal, let lon = lonVal {
                let latitude = latRef == "S" ? -lat : lat
                let longitude = lonRef == "W" ? -lon : lon
                gpsCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                isGpsFound = true
            } else {
                gpsCoordinate = nil
                isGpsFound = false
            }
            
            gpsAltitude = gps[kCGImagePropertyGPSAltitude as String] as? Double
            let altRef = gps[kCGImagePropertyGPSAltitudeRef as String] as? Int
            if let alt = gpsAltitude, altRef == 1 {
                gpsAltitude = -alt
            }
        } else {
            gpsCoordinate = nil
            gpsAltitude = nil
            isGpsFound = false
        }
        
        isMetadataLoaded = true
    }
}

struct MetadataRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.yellow)
                .frame(width: 24, height: 24)
            
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
            
            Spacer()
            
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .lineLimit(1)
        }
    }
}

struct MapLocation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}
