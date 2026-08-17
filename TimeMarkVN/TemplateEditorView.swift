import SwiftUI
import PhotosUI

struct TemplateEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var stamp: StampStore
    @EnvironmentObject var store: ProStore
    @State private var logoItem: PhotosPickerItem?
    @State private var templateName = ""
    @State private var showName = false
    @State private var paywall = false
    
    @State private var activeTab = 0 // 0: Nội dung, 1: Kiểu dáng, 2: Mẫu & Logo
    
    // Sample mock location for preview
    private let sampleAddress = "12 P. Tôn Thất Tùng, Trung Tự, Đống Đa, Hà Nội"
    private let sampleCoordinate = "21.004832° N  105.828456° E"

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
                        
                        // Watermark preview overlay
                        VStack(alignment: .leading, spacing: 4) {
                            if stamp.style.isEnabled(.address) {
                                Label(sampleAddress, systemImage: "location.fill")
                                    .font(.system(size: CGFloat(stamp.style.fontSize * 0.7)))
                            }
                            if stamp.style.isEnabled(.date) {
                                Text(Date(), format: .dateTime.day().month().year().hour().minute().second())
                                    .font(.system(size: CGFloat(stamp.style.fontSize * 0.65)).bold())
                                    .foregroundStyle(.yellow)
                            }
                            if stamp.style.isEnabled(.gps) {
                                Text(sampleCoordinate)
                                    .font(.system(size: CGFloat(stamp.style.fontSize * 0.55), design: .monospaced))
                            }
                            if stamp.style.isEnabled(.weather) {
                                Text("☁️ 28°C • Trời có mây")
                                    .font(.system(size: CGFloat(stamp.style.fontSize * 0.55)))
                            }
                            if stamp.style.isEnabled(.altitude) {
                                Text("Độ cao: 12 m")
                                    .font(.system(size: CGFloat(stamp.style.fontSize * 0.55)))
                            }
                        }
                        .foregroundStyle(.white)
                        .padding(14)
                        .background(.black.opacity(stamp.style.opacity),
                                    in: RoundedRectangle(cornerRadius: stamp.style.cornerRadius))
                        .scaleEffect(0.9)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
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
                            }
                        } else if activeTab == 1 {
                            // Styling Tab
                            VStack(alignment: .leading, spacing: 20) {
                                // Text Customizer Card
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(NSLocalizedString("CHỮ TÙY CHỈNH", comment: ""))
                                        .font(.system(.caption, design: .monospaced).bold())
                                        .foregroundStyle(.white.opacity(0.4))
                                        .tracking(1.5)
                                    
                                    TextField(NSLocalizedString("Nhập chữ tùy chỉnh...", comment: ""), text: $stamp.style.customText)
                                        .font(.body)
                                        .foregroundStyle(.white)
                                        .padding(.all, 14)
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
