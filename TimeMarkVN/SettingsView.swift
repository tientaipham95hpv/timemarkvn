import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: ProStore
    @EnvironmentObject var stamp: StampStore
    @EnvironmentObject var location: LocationManager

    @State private var paywall = false
    @State private var batch = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Tài khoản") {
                    HStack {
                        Label(store.isPro ? "TimeMark Pro" : "TimeMark Free",
                              systemImage: store.isPro ? "crown.fill" : "person.fill")
                        Spacer()
                        if !store.isPro {
                            Button("Nâng cấp") { paywall = true }
                        }
                    }
                }

                Section("Công cụ") {
                    Button {
                        if store.isPro { batch = true } else { paywall = true }
                    } label: {
                        Label("Xuất watermark hàng loạt", systemImage: "square.stack.3d.up.fill")
                    }
                }

                Section("Pro") {
                    Label("Template không giới hạn", systemImage: "rectangle.stack.fill")
                    Label("Batch export", systemImage: "square.stack.3d.up.fill")
                    Label("Logo & watermark nâng cao", systemImage: "wand.and.stars")
                    Label("Không quảng cáo", systemImage: "nosign")
                }

                Section {
                    Button("Khôi phục giao dịch") {
                        Task { await store.restore() }
                    }
                }

                Section("Thông tin") {
                    Text("TimeMark VN V5")
                    Text("StoreKit 2 • iOS 17+")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Cài đặt")
            .sheet(isPresented: $paywall) { ProPaywallView() }
            .sheet(isPresented: $batch) { BatchExportView() }
        }
    }
}
