import SwiftUI
import PhotosUI
import Speech
import AVFoundation

struct TemplateEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var stamp: StampStore
    @EnvironmentObject var store: ProStore
    @State private var logoItem: PhotosPickerItem?
    @State private var templateName = ""
    @State private var showName = false
    @State private var paywall = false
    
    @StateObject private var speechHelper = SpeechRecognizerHelper()
    
    @State private var activeTab = 0 // 0: Nội dung, 1: Kiểu dáng, 2: Mẫu & Logo
    
    private var colorBinding: Binding<Color> {
        Binding(
            get: { Color(hex: stamp.style.accentHex) },
            set: { stamp.style.accentHex = $0.toHex() }
        )
    }
    
    // Sample mock location for preview
    private let sampleAddress = "12 P. Tôn Thất Tùng, Trung Tự, Đống Đa, Hà Nội"
    private let sampleCoordinate = "21.004832° N  105.828456° E"

    private func getJoinedTelemetry() -> String {
        var items: [String] = []
        let tag = stamp.style.useCustomAddress ? "[\(NSLocalizedString("Thủ công", comment: ""))] " : "[\(NSLocalizedString("Tự động", comment: ""))] "
        let addr = stamp.style.useCustomAddress ? (stamp.style.customAddress.isEmpty ? sampleAddress : stamp.style.customAddress) : sampleAddress
        
        if stamp.style.isEnabled(.address) { items.append("📍 " + tag + addr) }
        if stamp.style.isEnabled(.date) {
            let dateStr = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium)
            items.append(dateStr)
        }
        if stamp.style.isEnabled(.gps) {
            items.append(sampleCoordinate + " (±3.5m)")
        }
        if stamp.style.isEnabled(.custom) {
            items.append(stamp.style.customText)
            for f in stamp.style.customFields {
                if !f.isEmpty { items.append(f) }
            }
        }
        return items.joined(separator: "  •  ")
    }

    private var stampPreviewContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            if stamp.style.isEnabled(.address) {
                let tag = stamp.style.useCustomAddress ? "[\(NSLocalizedString("Thủ công", comment: ""))] " : "[\(NSLocalizedString("Tự động", comment: ""))] "
                let addr = stamp.style.useCustomAddress ? (stamp.style.customAddress.isEmpty ? sampleAddress : stamp.style.customAddress) : sampleAddress
                Label(tag + addr, systemImage: "location.fill")
                    .font(Font.customFont(size: CGFloat(stamp.style.fontSize * 0.7), weight: .semibold, designName: stamp.style.fontDesign))
            }
            if stamp.style.isEnabled(.date) {
                Text(Date(), format: .dateTime.day().month().year().hour().minute().second())
                    .font(Font.customFont(size: CGFloat(stamp.style.fontSize * 0.65), weight: .bold, designName: stamp.style.fontDesign))
                    .foregroundStyle(Color(hex: stamp.style.accentHex))
            }
            if stamp.style.isEnabled(.gps) {
                Text(sampleCoordinate + " (±3.5m)")
                    .font(Font.customFont(size: CGFloat(stamp.style.fontSize * 0.55), weight: .semibold, designName: stamp.style.fontDesign))
            }
            if stamp.style.isEnabled(.compass) {
                Text(String(format: NSLocalizedString("La bàn: %.0f° %@", comment: ""), 120.0, 120.0.cardinalDirection))
                    .font(Font.customFont(size: CGFloat(stamp.style.fontSize * 0.55), weight: .semibold, designName: stamp.style.fontDesign))
            }
            if stamp.style.isEnabled(.weather) {
                Text("☁️ 28°C • Trời có mây")
                    .font(Font.customFont(size: CGFloat(stamp.style.fontSize * 0.55), weight: .semibold, designName: stamp.style.fontDesign))
            }
            if stamp.style.isEnabled(.altitude) {
                Text("Độ cao: 12 m")
                    .font(Font.customFont(size: CGFloat(stamp.style.fontSize * 0.55), weight: .semibold, designName: stamp.style.fontDesign))
            }
            if stamp.style.isEnabled(.custom) {
                Text(stamp.style.customText)
                    .font(Font.customFont(size: CGFloat(stamp.style.fontSize * 0.65), weight: .semibold, designName: stamp.style.fontDesign))
                
                ForEach(stamp.style.customFields, id: \.self) { field in
                    if !field.isEmpty {
                        Text(field)
                            .font(Font.customFont(size: CGFloat(stamp.style.fontSize * 0.65), weight: .semibold, designName: stamp.style.fontDesign))
                    }
                }
            }
        }
    }

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.06, blue: 0.06).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Bar
                HStack {
                    Text(NSLocalizedString("Thiết kế Watermark", comment: ""))
                        .font(.system(.title3, design: .rounded).bold())
                        .foregroundStyle(.white)
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Text(NSLocalizedString("Xong", comment: ""))
                            .font(.system(.subheadline).bold())
                            .foregroundStyle(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.yellow, in: Capsule())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                // Live Watermark Preview Container
                VStack {
                    Text(NSLocalizedString("XEM TRƯỚC WATERMARK", comment: ""))
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                        .tracking(1.5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    
                    ZStack {
                        // Blurred camera preview simulation background
                        LinearGradient(colors: [Color(red: 0.15, green: 0.25, blue: 0.25), Color(red: 0.1, green: 0.1, blue: 0.15)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.white.opacity(0.1), lineWidth: 1)
                            )
                        
                        if stamp.style.isTiled {
                            GeometryReader { geo in
                                let cols = Int(geo.size.width / 100) + 1
                                let rows = Int(geo.size.height / 60) + 1
                                VStack(spacing: 30) {
                                    ForEach(0..<rows, id: \.self) { _ in
                                        HStack(spacing: 36) {
                                            ForEach(0..<cols, id: \.self) { _ in
                                                Text(stamp.style.customText)
                                                    .font(.system(size: 8, weight: .bold))
                                                    .foregroundStyle(.white)
                                                    .opacity(0.12)
                                                    .rotationEffect(.degrees(-30))
                                            }
                                        }
                                    }
                                }
                                .padding(.top, 16)
                                .padding(.leading, 12)
                            }
                            .frame(height: 180)
                            .clipped()
                        }
                        
                        // Watermark preview overlay (Restructured with Dynamic Layouts)
                        Group {
                            if stamp.style.layoutType == "minimalist" {
                                Text(getJoinedTelemetry())
                                    .font(Font.customFont(size: CGFloat(stamp.style.fontSize * 0.45), weight: .bold, designName: stamp.style.fontDesign))
                                    .foregroundStyle(.white)
                                    .shadow(color: .black.opacity(0.8), radius: 1, x: 0.5, y: 0.5)
                                    .padding(.horizontal, 16)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            } else if stamp.style.layoutType == "badge" {
                                VStack(spacing: 2) {
                                    Circle()
                                        .fill(.black.opacity(stamp.style.opacity))
                                        .frame(width: 80, height: 80)
                                        .overlay(
                                            Circle()
                                                .stroke(Color(hex: stamp.style.accentHex), lineWidth: 2)
                                        )
                                        .overlay(
                                            VStack(spacing: 1) {
                                                if stamp.style.isEnabled(.address) {
                                                    Text("📍 GeoStamp")
                                                        .font(.system(size: 5, weight: .bold))
                                                }
                                                if stamp.style.isEnabled(.date) {
                                                    Text(Date(), format: .dateTime.hour().minute().second())
                                                        .font(.system(size: 6, weight: .bold))
                                                        .foregroundStyle(Color(hex: stamp.style.accentHex))
                                                }
                                                if stamp.style.isEnabled(.gps) {
                                                    Text("21.004, 105.828")
                                                        .font(.system(size: 5, weight: .bold))
                                                }
                                                if stamp.style.isEnabled(.custom) {
                                                    Text(stamp.style.customText)
                                                        .font(.system(size: 6, weight: .bold))
                                                        .lineLimit(1)
                                                }
                                            }
                                            .foregroundStyle(.white)
                                            .padding(4)
                                        )
                                }
                                .scaleEffect(0.9)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .padding(.trailing, 16)
                            } else {
                                stampPreviewContent
                                    .foregroundStyle(.white)
                                    .padding(10)
                                    .background(.black.opacity(stamp.style.opacity),
                                                in: RoundedRectangle(cornerRadius: stamp.style.cornerRadius * 0.8))
                                    .scaleEffect(0.8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 12)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 16)
                
                // Custom Segmented Picker (Tab Switcher)
                HStack(spacing: 0) {
                    TabButton(title: NSLocalizedString("Trường dữ liệu", comment: ""), icon: "list.bullet.rectangle", isActive: activeTab == 0) {
                        activeTab = 0
                    }
                    TabButton(title: NSLocalizedString("Kiểu dáng", comment: ""), icon: "slider.horizontal.3", isActive: activeTab == 1) {
                        activeTab = 1
                    }
                    TabButton(title: NSLocalizedString("Mẫu & Logo", comment: ""), icon: "folder.fill", isActive: activeTab == 2) {
                        activeTab = 2
                    }
                }
                .padding(.all, 4)
                .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                
                // Scrollable Controls based on active tab
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        if activeTab == 0 {
                            // Fields Tab
                            VStack(alignment: .leading, spacing: 14) {
                                Text(NSLocalizedString("BẬT / TẮT THÔNG TIN", comment: ""))
                                    .font(.system(.caption, design: .monospaced).bold())
                                    .foregroundStyle(.white.opacity(0.4))
                                    .tracking(1.5)
                                    .padding(.horizontal, 8)
                                
                                ForEach(StampField.allCases) { field in
                                    Toggle(isOn: Binding(
                                        get: { stamp.style.isEnabled(field) },
                                        set: { stamp.style.enabled[field] = $0 }
                                    )) {
                                        HStack(spacing: 14) {
                                            Image(systemName: field.icon)
                                                .font(.headline)
                                                .foregroundStyle(.yellow)
                                                .frame(width: 32, height: 32)
                                                .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
                                            Text(field.title)
                                                .font(.body.bold())
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .toggleStyle(SwitchToggleStyle(tint: .yellow))
                                    .padding(.all, 14)
                                    .background(.white.opacity(0.02), in: RoundedRectangle(cornerRadius: 14))
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.06), lineWidth: 1))
                                }
                                
                                // Custom Address Card
                                VStack(alignment: .leading, spacing: 12) {
                                    Toggle(isOn: $stamp.style.useCustomAddress) {
                                        HStack(spacing: 14) {
                                            Image(systemName: "pencil.and.outline")
                                                .font(.headline)
                                                .foregroundStyle(Color(hex: stamp.style.accentHex))
                                                .frame(width: 32, height: 32)
                                                .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
                                            Text(NSLocalizedString("Sử dụng địa chỉ thủ công", comment: ""))
                                                .font(.body.bold())
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .toggleStyle(SwitchToggleStyle(tint: .yellow))
                                    
                                    if stamp.style.useCustomAddress {
                                        TextField(NSLocalizedString("Nhập địa chỉ thủ công...", comment: ""), text: $stamp.style.customAddress)
                                            .font(.body)
                                            .foregroundStyle(.white)
                                            .padding(.all, 14)
                                            .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
                                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.12), lineWidth: 1))
                                    }
                                }
                                .padding(.all, 14)
                                .background(.white.opacity(0.02), in: RoundedRectangle(cornerRadius: 14))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.06), lineWidth: 1))
                            }
                        } else if activeTab == 1 {
                            // Styling Tab
                            VStack(alignment: .leading, spacing: 20) {
                                // Text Customizer Card (Multiple Custom Fields)
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(NSLocalizedString("CHỮ TÙY CHỈNH", comment: ""))
                                        .font(.system(.caption, design: .monospaced).bold())
                                        .foregroundStyle(.white.opacity(0.4))
                                        .tracking(1.5)
                                    
                                    HStack {
                                        TextField(NSLocalizedString("Dòng 1...", comment: ""), text: $stamp.style.customText)
                                            .font(.body)
                                            .foregroundStyle(.white)
                                        
                                        Button {
                                            if speechHelper.isRecording {
                                                speechHelper.stop()
                                            } else {
                                                speechHelper.start()
                                            }
                                        } label: {
                                            Image(systemName: speechHelper.isRecording ? "mic.fill" : "mic")
                                                .foregroundStyle(speechHelper.isRecording ? .red : .yellow)
                                                .font(.title3)
                                                .scaleEffect(speechHelper.isRecording ? 1.2 : 1.0)
                                                .animation(.easeInOut(duration: 0.3), value: speechHelper.isRecording)
                                        }
                                    }
                                    .padding(.all, 12)
                                    .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.12), lineWidth: 1))
                                    .onChange(of: speechHelper.transcript) { oldValue, newValue in
                                        if !newValue.isEmpty {
                                            stamp.style.customText = newValue
                                        }
                                    }
                                    
                                    // Pro custom lines
                                    ForEach(0..<2, id: \.self) { index in
                                        HStack {
                                            TextField(String(format: NSLocalizedString("Dòng %d (Pro)...", comment: ""), index + 2), text: Binding(
                                                get: {
                                                    if index < stamp.style.customFields.count {
                                                        return stamp.style.customFields[index]
                                                    }
                                                    return ""
                                                },
                                                set: { val in
                                                    if store.isPro {
                                                        while stamp.style.customFields.count <= index {
                                                            stamp.style.customFields.append("")
                                                        }
                                                        stamp.style.customFields[index] = val
                                                    } else {
                                                        paywall = true
                                                    }
                                                }
                                            ))
                                            .font(.body)
                                            .foregroundStyle(store.isPro ? .white : .white.opacity(0.4))
                                            .disabled(!store.isPro)
                                            
                                            if !store.isPro {
                                                Image(systemName: "lock.fill")
                                                    .font(.caption)
                                                    .foregroundStyle(.yellow)
                                            }
                                        }
                                        .padding(.all, 12)
                                        .background(.white.opacity(store.isPro ? 0.04 : 0.02), in: RoundedRectangle(cornerRadius: 10))
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(store.isPro ? .white.opacity(0.12) : .white.opacity(0.06), lineWidth: 1))
                                    }
                                }
                                .padding(.all, 16)
                                .background(.white.opacity(0.02), in: RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.06), lineWidth: 1))
                                
                                // Layout Selector Card
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(NSLocalizedString("BỐ CỤC CHỮ KÝ", comment: ""))
                                        .font(.system(.caption, design: .monospaced).bold())
                                        .foregroundStyle(.white.opacity(0.4))
                                        .tracking(1.5)
                                    
                                    Picker(NSLocalizedString("Bố cục chữ ký", comment: ""), selection: $stamp.style.layoutType) {
                                        Text(NSLocalizedString("Cổ điển", comment: "")).tag("classic")
                                        Text(NSLocalizedString("Tối giản", comment: "")).tag("minimalist")
                                        Text(NSLocalizedString("Huy hiệu", comment: "")).tag("badge")
                                    }
                                    .pickerStyle(.segmented)
                                }
                                .padding(.all, 16)
                                .background(.white.opacity(0.02), in: RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.06), lineWidth: 1))
                                
                                // Color Selector Card
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(NSLocalizedString("MÀU ĐIỂM NHẤN", comment: ""))
                                        .font(.system(.caption, design: .monospaced).bold())
                                        .foregroundStyle(.white.opacity(0.4))
                                        .tracking(1.5)
                                    
                                    ColorPicker(NSLocalizedString("Màu sắc chữ ký", comment: ""), selection: colorBinding)
                                        .font(.body.bold())
                                        .foregroundStyle(.white)
                                        .padding(.all, 14)
                                        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.12), lineWidth: 1))
                                }
                                .padding(.all, 16)
                                .background(.white.opacity(0.02), in: RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.06), lineWidth: 1))

                                // Grid Watermark Toggle Card (Pro)
                                VStack(alignment: .leading, spacing: 12) {
                                    Toggle(isOn: Binding(
                                        get: { stamp.style.isTiled },
                                        set: {
                                            if store.isPro {
                                                stamp.style.isTiled = $0
                                            } else {
                                                paywall = true
                                            }
                                        }
                                    )) {
                                        HStack(spacing: 14) {
                                            Image(systemName: "grid.multiply")
                                                .font(.headline)
                                                .foregroundStyle(.yellow)
                                                .frame(width: 32, height: 32)
                                                .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(NSLocalizedString("Lưới bảo vệ ảnh (Pro)", comment: ""))
                                                    .font(.body.bold())
                                                    .foregroundStyle(.white)
                                                Text(NSLocalizedString("Phủ bản quyền mờ chéo khắp hình", comment: ""))
                                                    .font(.system(size: 10))
                                                    .foregroundStyle(.white.opacity(0.5))
                                            }
                                        }
                                    }
                                    .toggleStyle(SwitchToggleStyle(tint: .yellow))
                                }
                                .padding(.all, 14)
                                .background(.white.opacity(0.02), in: RoundedRectangle(cornerRadius: 14))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.06), lineWidth: 1))
                                
                                // Font Selector Card
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(NSLocalizedString("KIỂU CHỮ", comment: ""))
                                        .font(.system(.caption, design: .monospaced).bold())
                                        .foregroundStyle(.white.opacity(0.4))
                                        .tracking(1.5)
                                    
                                    Picker(NSLocalizedString("Kiểu chữ chữ ký", comment: ""), selection: $stamp.style.fontDesign) {
                                        Text(NSLocalizedString("Mặc định", comment: "")).tag("default")
                                        Text(NSLocalizedString("Đơn cách", comment: "")).tag("monospaced")
                                        Text(NSLocalizedString("Bo tròn", comment: "")).tag("rounded")
                                        Text(NSLocalizedString("Có chân", comment: "")).tag("serif")
                                    }
                                    .pickerStyle(.menu)
                                    .font(.body.bold())
                                    .foregroundStyle(.white)
                                    .padding(.all, 8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.12), lineWidth: 1))
                                }
                                .padding(.all, 16)
                                .background(.white.opacity(0.02), in: RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.06), lineWidth: 1))
                                
                                // Sliders Card
                                VStack(alignment: .leading, spacing: 24) {
                                    Text(NSLocalizedString("CÂN CHỈNH KÍCH THƯỚC", comment: ""))
                                        .font(.system(.caption, design: .monospaced).bold())
                                        .foregroundStyle(.white.opacity(0.4))
                                        .tracking(1.5)
                                    
                                    CustomSliderRow(title: NSLocalizedString("Cỡ chữ", comment: ""), val: $stamp.style.fontSize, range: 14...36, symbol: "textformat.size")
                                    CustomSliderRow(title: NSLocalizedString("Trong suốt", comment: ""), val: $stamp.style.opacity, range: 0.25...0.95, symbol: "eye.fill")
                                    CustomSliderRow(title: NSLocalizedString("Bo góc", comment: ""), val: $stamp.style.cornerRadius, range: 0...32, symbol: "skew")
                                }
                                .padding(.all, 16)
                                .background(.white.opacity(0.02), in: RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.06), lineWidth: 1))
                            }
                        } else {
                            // Templates & Presets & Logo
                            VStack(spacing: 20) {
                                // Logo section card
                                VStack(alignment: .leading, spacing: 14) {
                                    Text(NSLocalizedString("LOGO THƯƠNG HIỆU", comment: ""))
                                        .font(.system(.caption, design: .monospaced).bold())
                                        .foregroundStyle(.white.opacity(0.4))
                                        .tracking(1.5)
                                    
                                    if store.isPro {
                                        PhotosPicker(selection: $logoItem, matching: .images) {
                                            HStack {
                                                Image(systemName: "photo.badge.plus")
                                                    .font(.headline)
                                                Text(stamp.logo != nil ? NSLocalizedString("Thay đổi logo cá nhân", comment: "") : NSLocalizedString("Chọn logo thương hiệu của bạn", comment: ""))
                                                    .font(.body.bold())
                                                Spacer()
                                                if let logo = stamp.logo {
                                                    Image(uiImage: logo)
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(width: 36, height: 36)
                                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                                }
                                            }
                                            .foregroundStyle(.white)
                                            .padding(.all, 16)
                                            .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
                                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.12), lineWidth: 1))
                                        }
                                    } else {
                                        Button {
                                            paywall = true
                                        } label: {
                                            HStack {
                                                Image(systemName: "lock.fill")
                                                    .font(.headline)
                                                    .foregroundStyle(.yellow)
                                                Text(NSLocalizedString("Chọn logo thương hiệu của bạn (Pro)", comment: ""))
                                                    .font(.body.bold())
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .font(.caption.bold())
                                                    .foregroundStyle(.white.opacity(0.3))
                                            }
                                            .foregroundStyle(.white.opacity(0.6))
                                            .padding(.all, 16)
                                            .background(.white.opacity(0.02), in: RoundedRectangle(cornerRadius: 12))
                                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.08), lineWidth: 1))
                                        }
                                    }
                                }
                                .padding(.all, 16)
                                .background(.white.opacity(0.02), in: RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.06), lineWidth: 1))
                                
                                // Save Template section card
                                VStack(alignment: .leading, spacing: 14) {
                                    Text(NSLocalizedString("LƯU MẪU ĐÃ THIẾT KẾ", comment: ""))
                                        .font(.system(.caption, design: .monospaced).bold())
                                        .foregroundStyle(.white.opacity(0.4))
                                        .tracking(1.5)
                                    
                                    Button {
                                        if store.isPro || stamp.templates.count < 3 {
                                            showName = true
                                        } else {
                                            paywall = true
                                        }
                                    } label: {
                                        Label(NSLocalizedString("Lưu thiết kế hiện tại", comment: ""), systemImage: "square.and.arrow.down.fill")
                                            .font(.body.bold())
                                            .foregroundStyle(.black)
                                            .frame(maxWidth: .infinity)
                                            .padding(.all, 16)
                                            .background(.yellow, in: RoundedRectangle(cornerRadius: 12))
                                    }
                                    
                                    if !stamp.templates.isEmpty {
                                        Divider().background(.white.opacity(0.1)).padding(.vertical, 8)
                                        
                                        ForEach(stamp.templates) { template in
                                            HStack {
                                                Button {
                                                    stamp.load(template)
                                                } label: {
                                                    HStack {
                                                        Image(systemName: "doc.text.fill")
                                                            .foregroundStyle(.yellow)
                                                        Text(template.name)
                                                            .font(.body)
                                                            .foregroundStyle(.white)
                                                    }
                                                }
                                                Spacer()
                                                Button(role: .destructive) {
                                                    stamp.deleteTemplate(template)
                                                } label: {
                                                    Image(systemName: "trash.fill")
                                                        .foregroundStyle(.red.opacity(0.8))
                                                }
                                            }
                                            .padding(.vertical, 8)
                                        }
                                    }
                                }
                                .padding(.all, 16)
                                .background(.white.opacity(0.02), in: RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.06), lineWidth: 1))
                                
                                // Presets section card
                                VStack(alignment: .leading, spacing: 14) {
                                    Text(NSLocalizedString("PRESETS CÀI ĐẶT NHANH", comment: ""))
                                        .font(.system(.caption, design: .monospaced).bold())
                                        .foregroundStyle(.white.opacity(0.4))
                                        .tracking(1.5)
                                    
                                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                        PresetButton(title: NSLocalizedString("Cơ bản", comment: ""), icon: "doc.plaintext") {
                                            stamp.style = StampStyle()
                                        }
                                        PresetButton(title: NSLocalizedString("Công trình", comment: ""), icon: "building.2") {
                                            var s = StampStyle()
                                            s.enabled[.altitude] = true
                                            s.enabled[.compass] = true
                                            s.enabled[.map] = true
                                            stamp.style = s
                                        }
                                        PresetButton(title: NSLocalizedString("Du lịch", comment: ""), icon: "airplane") {
                                            var s = StampStyle()
                                            s.enabled[.altitude] = true
                                            s.enabled[.weather] = true
                                            s.enabled[.map] = true
                                            stamp.style = s
                                        }
                                        PresetButton(title: NSLocalizedString("Ngày lớn", comment: ""), icon: "calendar.badge.clock") {
                                            var s = StampStyle()
                                            s.enabled[.gps] = false
                                            s.enabled[.map] = false
                                            s.fontSize = 30
                                            stamp.style = s
                                        }
                                    }
                                }
                                .padding(.all, 16)
                                .background(.white.opacity(0.02), in: RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.06), lineWidth: 1))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
        }
        .alert(NSLocalizedString("Lưu template", comment: ""), isPresented: $showName) {
            TextField(NSLocalizedString("Tên template", comment: ""), text: $templateName)
            Button(NSLocalizedString("Lưu", comment: "")) {
                stamp.saveTemplate(name: templateName.isEmpty ? NSLocalizedString("Template mới", comment: "") : templateName)
                templateName = ""
            }
            Button(NSLocalizedString("Hủy", comment: ""), role: .cancel) {}
        }
        .sheet(isPresented: $paywall) { ProPaywallView() }
        .task(id: logoItem) {
            if let data = try? await logoItem?.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                stamp.loadLogo(image)
            }
        }
    }
}

// Subview Component for Custom Segmented Tab
struct TabButton: View {
    let title: String
    let icon: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.subheadline)
                Text(title)
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundStyle(isActive ? .black : .white.opacity(0.6))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isActive ? Color.yellow : Color.clear, in: RoundedRectangle(cornerRadius: 10))
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isActive)
        }
    }
}

// Subview Component for Sliders
struct CustomSliderRow: View {
    let title: String
    @Binding var val: Double
    let range: ClosedRange<Double>
    let symbol: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(title, systemImage: symbol)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                Spacer()
                Text(String(format: title.contains("suất") ? "%.0f%%" : "%.0f px", title.contains("suất") ? val * 100 : val))
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(.yellow)
            }
            
            Slider(value: $val, in: range)
                .tint(.yellow)
        }
    }
}

// Subview Component for Preset Buttons
struct PresetButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(.yellow)
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding(.all, 14)
            .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.1), lineWidth: 1))
        }
    }
}

// Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 255, 255, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func toHex() -> String {
        let uic = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uic.getRed(&r, green: &g, blue: &b, alpha: &a)
        let rgb: Int = (Int)(r * 255) << 16 | (Int)(g * 255) << 8 | (Int)(b * 255) << 0
        return String(format: "#%06x", rgb)
    }
}

class SpeechRecognizerHelper: ObservableObject {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "vi-VN"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    @Published var transcript = ""
    @Published var isRecording = false
    
    func start() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            if authStatus == .authorized {
                DispatchQueue.main.async {
                    self.startRecording()
                }
            }
        }
    }
    
    private func startRecording() {
        recognitionTask?.cancel()
        self.recognitionTask = nil
        
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            if let result = result {
                DispatchQueue.main.async {
                    self.transcript = result.bestTranscription.formattedString
                }
                isFinal = result.isFinal
            }
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                DispatchQueue.main.async {
                    self.isRecording = false
                }
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try? audioEngine.start()
        isRecording = true
    }
    
    func stop() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        isRecording = false
    }
}
