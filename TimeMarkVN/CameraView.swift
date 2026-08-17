import SwiftUI

struct CameraView: View {
    @EnvironmentObject var location: LocationManager
    @EnvironmentObject var stamp: StampStore
    @EnvironmentObject var store: ProStore
    @StateObject private var camera = CameraModel()

    @State private var lastImage: UIImage?
    @State private var editor = false
    @State private var captured = false
    @State private var share = false
    @State private var showPaywall = false
    @State private var showGrid = false
    
    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    var body: some View {
        ZStack {
            CameraPreview(session: camera.session).ignoresSafeArea()
            
            if showGrid {
                GridOverlayView()
            }

            // Premium background vignette
            LinearGradient(colors: [.black.opacity(0.65), .clear, .black.opacity(0.85)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack {
                // Top Telemetry HUD
                HStack(spacing: 12) {
                    Button {
                        triggerHaptic()
                        camera.flashOn.toggle()
                    } label: {
                        Image(systemName: camera.flashOn ? "bolt.fill" : "bolt.slash.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(camera.flashOn ? .yellow : .white)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 1))
                    }
                    
                    Button {
                        triggerHaptic()
                        showGrid.toggle()
                    } label: {
                        Image(systemName: showGrid ? "grid" : "grid.circle")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(showGrid ? .yellow : .white)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 1))
                    }
                    
                    Spacer()
                    
                    // Brand HUD
                    HStack(spacing: 6) {
                        Circle()
                            .fill(.yellow)
                            .frame(width: 6, height: 6)
                            .opacity(location.coordinate != nil ? 1 : 0.4)
                            .shadow(color: .yellow, radius: location.coordinate != nil ? 4 : 0)
                        
                        Text("TIMEMARK VN")
                            .font(.system(.subheadline, design: .monospaced).bold())
                            .tracking(2.5)
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.65), in: Capsule())
                    .overlay(Capsule().stroke(.white.opacity(0.15), lineWidth: 1))
                    
                    Spacer()
                    
                    Button {
                        triggerHaptic()
                        editor = true
                    } label: {
                        Image(systemName: "paintbrush.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 1))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                Spacer()

                // Watermark live preview area
                stampPreview
                    .offset(x: CGFloat((stamp.style.x - 0.5) * 80),
                            y: CGFloat((stamp.style.y - 0.8) * 80))
                    .gesture(
                        DragGesture().onChanged { value in
                            stamp.style.x = min(max(stamp.style.x + value.translation.width / 1000, 0.08), 0.92)
                            stamp.style.y = min(max(stamp.style.y + value.translation.height / 1600, 0.10), 0.92)
                        }
                    )

                Spacer()

                // Zoom control capsule
                HStack(spacing: 8) {
                    ForEach([1, 2, 3, 5], id: \.self) { value in
                        Button {
                            triggerHaptic()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                camera.setZoom(CGFloat(value))
                            }
                        } label: {
                            Text("\(value)x")
                                .font(.system(.caption, design: .monospaced).bold())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(abs(camera.zoom - CGFloat(value)) < 0.1 ? .yellow : .clear, in: Capsule())
                                .foregroundStyle(abs(camera.zoom - CGFloat(value)) < 0.1 ? .black : .white)
                        }
                    }
                }
                .padding(4)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().stroke(.white.opacity(0.15), lineWidth: 1))
                .shadow(color: .black.opacity(0.3), radius: 12)
                .padding(.bottom, 16)

                // Shutter and Actions bar
                HStack(alignment: .center) {
                    // Gallery Thumbnail or Placeholder
                    Group {
                        if let lastImage {
                            Button {
                                triggerHaptic()
                                share = true
                            } label: {
                                Image(uiImage: lastImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 56, height: 56)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(.yellow, lineWidth: 2))
                                    .shadow(color: .yellow.opacity(0.3), radius: 6)
                            }
                        } else {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.white.opacity(0.05))
                                .frame(width: 56, height: 56)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.15), lineWidth: 1))
                        }
                    }

                    Spacer()

                    // Shutter Button
                    Button {
                        triggerHaptic()
                        captured = true
                        camera.capture()
                    } label: {
                        ZStack {
                            Circle()
                                .stroke(.white, lineWidth: 4.5)
                                .frame(width: 78, height: 78)
                            
                            Circle()
                                .fill(.white)
                                .frame(width: 62, height: 62)
                                .overlay(
                                    Circle()
                                        .stroke(.yellow.opacity(0.4), lineWidth: 2.5)
                                        .blur(radius: 1.5)
                                )
                        }
                    }
                    .buttonStyle(ShutterButtonStyle())

                    Spacer()

                    // Rotate Camera Button
                    Button {
                        triggerHaptic()
                        camera.toggleCamera()
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 1))
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            }
        }
        .task {
            camera.start()
            location.start()
        }
        .onChange(of: location.coordinate?.latitude) { oldValue, newValue in
            location.refreshWeather()
        }
        .onChange(of: camera.lastImage) { oldValue, newValue in
            guard captured, let raw = newValue else { return }
            captured = false
            process(raw)
        }
        .sheet(isPresented: $editor) { TemplateEditorView() }
        .sheet(isPresented: $share) {
            if let lastImage {
                ShareSheet(items: [lastImage])
            }
        }
        .sheet(isPresented: $showPaywall) { ProPaywallView() }
    }

    private var stampPreview: some View {
        VStack(alignment: .leading, spacing: 5) {
            if stamp.style.isEnabled(.address) {
                let tag = stamp.style.useCustomAddress ? "[\(NSLocalizedString("Thủ công", comment: ""))] " : "[\(NSLocalizedString("Tự động", comment: ""))] "
                let addr = stamp.style.useCustomAddress ? (stamp.style.customAddress.isEmpty ? location.address : stamp.style.customAddress) : location.address
                Label(tag + addr, systemImage: "location.fill")
                    .font(.headline)
            }
            if stamp.style.isEnabled(.date) {
                Text(Date(), format: .dateTime.day().month().year().hour().minute().second())
                    .font(.subheadline.bold())
                    .foregroundStyle(Color(hex: stamp.style.accentHex))
            }
            if stamp.style.isEnabled(.gps), let c = location.coordinate {
                Text(String(format: "%.6f° N  %.6f° E", c.latitude, c.longitude))
                    .font(.system(.caption, design: .monospaced))
            }
            if stamp.style.isEnabled(.weather) {
                Text("☁️ \(location.temperature) • \(location.weatherText)")
                    .font(.caption)
            }
            if stamp.style.isEnabled(.altitude) {
                Text(String(format: NSLocalizedString("Độ cao: %.0f m", comment: ""), location.altitude))
                    .font(.caption)
            }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.black.opacity(stamp.style.opacity),
                    in: RoundedRectangle(cornerRadius: stamp.style.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: stamp.style.cornerRadius)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }

    private func process(_ raw: UIImage) {
        let finish: (UIImage?) -> Void = { map in
            let final = StampRenderer.render(image: raw, location: location,
                                              style: stamp.style, logo: stamp.logo, map: map)
            lastImage = final
            UIImageWriteToSavedPhotosAlbum(final, nil, nil, nil)
        }

        if stamp.style.isEnabled(.map), let c = location.coordinate {
            MapSnapshotService.snapshot(coordinate: c, completion: finish)
        } else {
            finish(nil)
        }
    }
}

// Custom shutter press animation
struct ShutterButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.90 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// Redesigned premium paywall screen
struct ProPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: ProStore
    @State private var selectedProduct: String?

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.06, blue: 0.06).ignoresSafeArea()
            
            // Glowing background effect
            VStack {
                LinearGradient(colors: [.yellow.opacity(0.14), .clear],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: 280)
                Spacer()
            }
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    // Title & Crown Icon
                    VStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(
                                LinearGradient(colors: [.yellow, .orange],
                                               startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .shadow(color: .yellow.opacity(0.35), radius: 12)
                            .padding(.top, 24)
                        
                        Text(NSLocalizedString("TimeMark Pro", comment: ""))
                            .font(.system(.title, design: .rounded).bold())
                            .foregroundStyle(.white)
                        
                        Text(NSLocalizedString("Mở khóa các công cụ chuyên nghiệp tốt nhất", comment: ""))
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    
                    // Features
                    VStack(spacing: 14) {
                        FeatureRow(icon: "rectangle.stack.fill",
                                   title: NSLocalizedString("Template không giới hạn", comment: ""),
                                   desc: NSLocalizedString("Tạo và lưu không giới hạn các mẫu thiết kế của riêng bạn.", comment: ""))
                        FeatureRow(icon: "square.stack.3d.up.fill",
                                   title: NSLocalizedString("Batch export", comment: ""),
                                   desc: NSLocalizedString("Đóng dấu watermark hàng loạt hình ảnh cùng một lúc, tiết kiệm thời gian.", comment: ""))
                        FeatureRow(icon: "wand.and.stars",
                                   title: NSLocalizedString("Logo & watermark nâng cao", comment: ""),
                                   desc: NSLocalizedString("Tùy chỉnh chèn logo thương hiệu cá nhân với chất lượng sắc nét.", comment: ""))
                        FeatureRow(icon: "nosign",
                                   title: NSLocalizedString("Không quảng cáo", comment: ""),
                                   desc: NSLocalizedString("Loại bỏ hoàn toàn quảng cáo để tập trung tối đa cho công việc.", comment: ""))
                    }
                    .padding(.horizontal)
                    
                    // Gói sản phẩm
                    VStack(alignment: .leading, spacing: 14) {
                        Text(NSLocalizedString("DANH SÁCH GÓI", comment: ""))
                            .font(.system(.caption, design: .monospaced).bold())
                            .foregroundStyle(.white.opacity(0.4))
                            .tracking(1.5)
                            .padding(.horizontal, 8)
                        
                        if store.products.isEmpty {
                            VStack(spacing: 12) {
                                ProgressView()
                                    .tint(.yellow)
                                    .padding()
                                Text(NSLocalizedString("Đang kết nối App Store...", comment: ""))
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.4))
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.08), lineWidth: 1))
                        } else {
                            ForEach(store.products) { product in
                                Button {
                                    selectedProduct = product.id
                                    Task { await store.purchase(product) }
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(product.displayName)
                                                .font(.headline.bold())
                                                .foregroundStyle(.white)
                                            Text(product.description)
                                                .font(.caption)
                                                .foregroundStyle(.white.opacity(0.5))
                                                .multilineTextAlignment(.leading)
                                        }
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 4) {
                                            Text(product.displayPrice)
                                                .font(.title3.bold())
                                                .foregroundStyle(.yellow)
                                            
                                            if product.id.contains("yearly") {
                                                Text(NSLocalizedString("TIẾT KIỆM 30%", comment: ""))
                                                    .font(.system(size: 8, weight: .bold))
                                                    .foregroundStyle(.black)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 3)
                                                    .background(.yellow, in: Capsule())
                                            }
                                        }
                                    }
                                    .padding(.all, 18)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(.white.opacity(selectedProduct == product.id ? 0.08 : 0.03))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(selectedProduct == product.id ? Color.yellow : Color.white.opacity(0.12), lineWidth: 1.5)
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Footer
                    VStack(spacing: 16) {
                        Button {
                            Task { await store.restore() }
                        } label: {
                            Text(NSLocalizedString("Khôi phục giao dịch đã mua", comment: ""))
                                .font(.subheadline.bold())
                                .foregroundStyle(.yellow)
                        }
                        .padding(.top, 8)
                        
                        Text(NSLocalizedString("Thanh toán sẽ được tính vào tài khoản App Store của bạn. Hủy bất kỳ lúc nào ít nhất 24 giờ trước khi kết thúc chu kỳ.", comment: ""))
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.3))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.bottom, 36)
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.white.opacity(0.35))
                    .padding()
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let desc: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.yellow)
                .frame(width: 44, height: 44)
                .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.08), lineWidth: 1))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
        }
        .padding(.all, 12)
        .background(.white.opacity(0.02), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.05), lineWidth: 1))
    }
}

// 3x3 Grid Overlay View
struct GridOverlayView: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let w = geo.size.width
                let h = geo.size.height
                
                // Vertical lines
                path.move(to: CGPoint(x: w / 3, y: 0))
                path.addLine(to: CGPoint(x: w / 3, y: h))
                path.move(to: CGPoint(x: w * 2 / 3, y: 0))
                path.addLine(to: CGPoint(x: w * 2 / 3, y: h))
                
                // Horizontal lines
                path.move(to: CGPoint(x: 0, y: h / 3))
                path.addLine(to: CGPoint(x: w, y: h / 3))
                path.move(to: CGPoint(x: 0, y: h * 2 / 3))
                path.addLine(to: CGPoint(x: w, y: h * 2 / 3))
            }
            .stroke(Color.white.opacity(0.18), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
        }
        .ignoresSafeArea()
    }
}
