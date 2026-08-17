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

    var body: some View {
        ZStack {
            CameraPreview(session: camera.session).ignoresSafeArea()

            LinearGradient(colors: [.black.opacity(0.5), .clear, .black.opacity(0.85)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack {
                HStack {
                    Button { camera.flashOn.toggle() } label: {
                        Image(systemName: camera.flashOn ? "bolt.fill" : "bolt.slash")
                    }
                    Spacer()
                    Text("TIMEMARK VN").font(.headline.bold())
                    Spacer()
                    Button { editor = true } label: {
                        Image(systemName: "paintbrush.fill")
                    }
                }
                .font(.title3)
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.top, 12)

                Spacer()

                stampPreview
                    .offset(x: CGFloat((stamp.style.x - 0.5) * 80),
                            y: CGFloat((stamp.style.y - 0.8) * 80))
                    .gesture(
                        DragGesture().onChanged { value in
                            stamp.style.x = min(max(stamp.style.x + value.translation.width / 1000, 0.08), 0.92)
                            stamp.style.y = min(max(stamp.style.y + value.translation.height / 1600, 0.10), 0.92)
                        }
                    )

                HStack(spacing: 10) {
                    ForEach([1, 2, 3, 5], id: \.self) { value in
                        Button("\(value)x") {
                            camera.setZoom(CGFloat(value))
                        }
                        .font(.caption.bold())
                        .foregroundStyle(abs(camera.zoom - CGFloat(value)) < 0.1 ? .yellow : .white)
                    }
                }
                .padding(8)
                .background(.black.opacity(0.45), in: Capsule())

                HStack {
                    if let lastImage {
                        Image(uiImage: lastImage)
                            .resizable().scaledToFill()
                            .frame(width: 58, height: 58)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .onTapGesture { share = true }
                    } else {
                        Color.clear.frame(width: 58, height: 58)
                    }

                    Spacer()

                    Button {
                        captured = true
                        camera.capture()
                    } label: {
                        Circle().fill(.white).frame(width: 80, height: 80)
                            .overlay(Circle().stroke(.gray, lineWidth: 4).padding(5))
                    }

                    Spacer()

                    Button { camera.toggleCamera() } label: {
                        Image(systemName: "camera.rotate.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 58, height: 58)
                            .background(.black.opacity(0.4), in: Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 22)
            }
        }
        .task {
            camera.start()
            location.start()
        }
        .onChange(of: location.coordinate?.latitude) { location.refreshWeather() }
        .onChange(of: camera.lastImage) {
            guard captured, let raw = camera.lastImage else { return }
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
        VStack(alignment: .leading, spacing: 4) {
            if stamp.style.isEnabled(.address) {
                Label(location.address, systemImage: "location.fill").font(.headline)
            }
            if stamp.style.isEnabled(.date) {
                Text(Date(), format: .dateTime.day().month().year().hour().minute().second())
                    .font(.subheadline.bold())
            }
            if stamp.style.isEnabled(.gps), let c = location.coordinate {
                Text(String(format: "%.6f° N  %.6f° E", c.latitude, c.longitude)).font(.caption)
            }
            if stamp.style.isEnabled(.weather) {
                Text("☁️ \(location.temperature) • \(location.weatherText)").font(.caption)
            }
            if stamp.style.isEnabled(.altitude) {
                Text(String(format: "Độ cao: %.0f m", location.altitude)).font(.caption)
            }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.black.opacity(stamp.style.opacity),
                    in: RoundedRectangle(cornerRadius: stamp.style.cornerRadius))
        .padding(.horizontal, 18)
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

struct ProPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: ProStore

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("TimeMark Pro")
                        .font(.largeTitle.bold())
                    Text("Mở khóa toàn bộ công cụ chuyên nghiệp.")
                        .foregroundStyle(.secondary)
                }

                Section("Quyền lợi") {
                    Label("Template không giới hạn", systemImage: "rectangle.stack.fill")
                    Label("Batch export", systemImage: "square.stack.3d.up.fill")
                    Label("Logo & watermark nâng cao", systemImage: "wand.and.stars")
                    Label("Không quảng cáo", systemImage: "nosign")
                }

                Section("Gói") {
                    ForEach(store.products) { product in
                        Button {
                            Task { await store.purchase(product) }
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(product.displayName).bold()
                                    Text(product.description).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(product.displayPrice).bold()
                            }
                        }
                    }
                }

                Button("Khôi phục giao dịch") {
                    Task { await store.restore() }
                }
            }
            .navigationTitle("Pro")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Đóng") { dismiss() }
                }
            }
        }
    }
}
