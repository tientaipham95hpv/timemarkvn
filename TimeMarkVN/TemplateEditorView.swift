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
                    Text("Thiết kế Watermark")
                        .font(.system(.title3, design: .rounded).bold())
                        .foregroundStyle(.white)
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Text("Xong")
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
                    Text("XEM TRƯỚC WATERMARK")
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
                    TabButton(title: "Trường dữ liệu", icon: "list.bullet.rectangle", isActive: activeTab == 0) {
                        activeTab = 0
                    }
                    TabButton(title: "Kiểu dáng", icon: "slider.horizontal.3", isActive: activeTab == 1) {
                        activeTab = 1
                    }
                    TabButton(title: "Mẫu & Logo", icon: "folder.fill", isActive: activeTab == 2) {
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
                                Text("BẬT / TẮT THÔNG TIN")
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
                                    Text("CHỮ TÙY CHỈNH")
                                        .font(.system(.caption, design: .monospaced).bold())
                                        .foregroundStyle(.white.opacity(0.4))
                                        .tracking(1.5)
                                    
                                    TextField("Nhập chữ tùy chỉnh...", text: $stamp.style.customText)
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
                                    Text("CÂN CHỈNH KÍCH THƯỚC")
                                        .font(.system(.caption, design: .monospaced).bold())
                                        .foregroundStyle(.white.opacity(0.4))
                                        .tracking(1.5)
                                    
                                    CustomSliderRow(title: "Cỡ chữ", val: $stamp.style.fontSize, range: 14...36, symbol: "textformat.size")
                                    CustomSliderRow(title: "Độ trong suốt", val: $stamp.style.opacity, range: 0.25...0.95, symbol: "eye.fill")
                                    CustomSliderRow(title: "Độ bo góc nền", val: $stamp.style.cornerRadius, range: 0...32, symbol: "skew")
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
                                    Text("LOGO THƯƠNG HIỆU")
                                        .font(.system(.caption, design: .monospaced).bold())
                                        .foregroundStyle(.white.opacity(0.4))
                                        .tracking(1.5)
                                    
                                    PhotosPicker(selection: $logoItem, matching: .images) {
                                        HStack {
                                            Image(systemName: "photo.badge.plus")
                                                .font(.headline)
                                            Text(stamp.logo != nil ? "Thay đổi logo cá nhân" : "Chọn logo thương hiệu của bạn")
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
                                    Text("LƯU MẪU ĐÃ THIẾT KẾ")
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
                                        Label("Lưu thiết kế hiện tại", systemImage: "square.and.arrow.down.fill")
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
                                    Text("PRESETS CÀI ĐẶT NHANH")
                                        .font(.system(.caption, design: .monospaced).bold())
                                        .foregroundStyle(.white.opacity(0.4))
                                        .tracking(1.5)
                                    
                                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                        PresetButton(title: "Cơ bản", icon: "doc.plaintext") {
                                            stamp.style = StampStyle()
                                        }
                                        PresetButton(title: "Công trình", icon: "building.2") {
                                            var s = StampStyle()
                                            s.enabled[.altitude] = true
                                            s.enabled[.compass] = true
                                            s.enabled[.map] = true
                                            stamp.style = s
                                        }
                                        PresetButton(title: "Du lịch", icon: "airplane") {
                                            var s = StampStyle()
                                            s.enabled[.altitude] = true
                                            s.enabled[.weather] = true
                                            s.enabled[.map] = true
                                            stamp.style = s
                                        }
                                        PresetButton(title: "Ngày lớn", icon: "calendar.badge.clock") {
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
        .alert("Lưu template", isPresented: $showName) {
            TextField("Tên template", text: $templateName)
            Button("Lưu") {
                stamp.saveTemplate(name: templateName.isEmpty ? "Template mới" : templateName)
                templateName = ""
            }
            Button("Hủy", role: .cancel) {}
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
