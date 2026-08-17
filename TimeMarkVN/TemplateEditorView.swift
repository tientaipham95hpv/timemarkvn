import SwiftUI
import PhotosUI

struct TemplateEditorView: View {
    @EnvironmentObject var stamp: StampStore
    @EnvironmentObject var store: ProStore
    @State private var logoItem: PhotosPickerItem?
    @State private var templateName = ""
    @State private var showName = false
    @State private var paywall = false

    var body: some View {
        NavigationStack {
            List {
                Section("Trường dữ liệu") {
                    ForEach(StampField.allCases) { field in
                        Toggle(isOn: Binding(
                            get: { stamp.style.isEnabled(field) },
                            set: { stamp.style.enabled[field] = $0 }
                        )) {
                            Label(field.title, systemImage: field.icon)
                        }
                    }
                }

                Section("Vị trí") {
                    HStack { Text("Ngang"); Slider(value: $stamp.style.x, in: 0.08...0.92) }
                    HStack { Text("Dọc"); Slider(value: $stamp.style.y, in: 0.10...0.92) }
                    Text("Bạn cũng có thể kéo watermark trực tiếp trên Camera.")
                        .font(.caption).foregroundStyle(.secondary)
                }

                Section("Kiểu") {
                    HStack { Text("Cỡ chữ"); Slider(value: $stamp.style.fontSize, in: 14...42) }
                    HStack { Text("Trong suốt"); Slider(value: $stamp.style.opacity, in: 0.25...0.95) }
                    HStack { Text("Bo góc"); Slider(value: $stamp.style.cornerRadius, in: 0...40) }
                    TextField("Chữ tùy chỉnh", text: $stamp.style.customText)
                }

                Section("Logo") {
                    PhotosPicker("Chọn logo", selection: $logoItem, matching: .images)
                }

                Section("Template") {
                    Button {
                        if store.isPro || stamp.templates.count < 3 {
                            showName = true
                        } else {
                            paywall = true
                        }
                    } label: {
                        Label("Lưu template", systemImage: "square.and.arrow.down")
                    }

                    ForEach(stamp.templates) { template in
                        HStack {
                            Button(template.name) { stamp.load(template) }
                            Spacer()
                            Button(role: .destructive) {
                                stamp.deleteTemplate(template)
                            } label: { Image(systemName: "trash") }
                        }
                    }
                }

                Section("Preset") {
                    Button("Cơ bản") { stamp.style = StampStyle() }
                    Button("Công trình") {
                        var s = StampStyle()
                        s.enabled[.altitude] = true
                        s.enabled[.compass] = true
                        s.enabled[.map] = true
                        stamp.style = s
                    }
                    Button("Du lịch") {
                        var s = StampStyle()
                        s.enabled[.altitude] = true
                        s.enabled[.weather] = true
                        s.enabled[.map] = true
                        stamp.style = s
                    }
                    Button("Ngày lớn") {
                        var s = StampStyle()
                        s.enabled[.gps] = false
                        s.enabled[.map] = false
                        s.fontSize = 30
                        stamp.style = s
                    }
                }
            }
            .navigationTitle("Thiết kế")
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
}
