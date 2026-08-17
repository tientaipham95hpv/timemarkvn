import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: ProStore
    @EnvironmentObject var stamp: StampStore
    @EnvironmentObject var location: LocationManager

    @State private var paywall = false
    @State private var batch = false

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.06, blue: 0.06).ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    // Brand Header
                    VStack(spacing: 8) {
                        Image(systemName: "camera.rose.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(
                                LinearGradient(colors: [.yellow, .yellow.opacity(0.8)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .shadow(color: .yellow.opacity(0.2), radius: 8)
                            .padding(.top, 16)
                        
                        Text("TIMEMARK VN")
                            .font(.system(.title3, design: .monospaced).bold())
                            .tracking(4.0)
                            .foregroundStyle(.white)
                        
                        Text("Phiên bản 5.0 • Chuyên nghiệp")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    
                    // Account Premium Card
                    VStack(alignment: .leading, spacing: 14) {
                        Text("TÀI KHOẢN")
                            .font(.system(.caption, design: .monospaced).bold())
                            .foregroundStyle(.white.opacity(0.4))
                            .tracking(1.5)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(store.isPro ? "Tài khoản Pro" : "Tài khoản Free")
                                    .font(.headline.bold())
                                    .foregroundStyle(.white)
                                Text(store.isPro ? "Bạn đã kích hoạt toàn bộ tính năng cao cấp." : "Nâng cấp để mở khóa các công cụ bị giới hạn.")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                            
                            Spacer()
                            
                            if store.isPro {
                                Image(systemName: "crown.fill")
                                    .font(.title2)
                                    .foregroundStyle(.yellow)
                                    .shadow(color: .yellow.opacity(0.4), radius: 6)
                            } else {
                                Button {
                                    paywall = true
                                } label: {
                                    Text("Nâng cấp")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.black)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(.yellow, in: Capsule())
                                }
                            }
                        }
                        .padding(.all, 16)
                        .background(.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(store.isPro ? Color.yellow.opacity(0.4) : Color.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Core tools Card
                    VStack(alignment: .leading, spacing: 14) {
                        Text("CÔNG CỤ NÂNG CAO")
                            .font(.system(.caption, design: .monospaced).bold())
                            .foregroundStyle(.white.opacity(0.4))
                            .tracking(1.5)
                        
                        Button {
                            if store.isPro {
                                batch = true
                            } else {
                                paywall = true
                            }
                        } label: {
                            HStack(spacing: 16) {
                                Image(systemName: "square.stack.3d.up.fill")
                                    .font(.headline)
                                    .foregroundStyle(.yellow)
                                    .frame(width: 36, height: 36)
                                    .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Xuất watermark hàng loạt")
                                        .font(.body.bold())
                                        .foregroundStyle(.white)
                                    Text("Đóng dấu và lưu nhiều ảnh cùng một lúc")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.5))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white.opacity(0.3))
                            }
                            .padding(.all, 16)
                            .background(.white.opacity(0.02), in: RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.06), lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Pro Features List Card
                    VStack(alignment: .leading, spacing: 14) {
                        Text("QUYỀN LỢI PREMIUM")
                            .font(.system(.caption, design: .monospaced).bold())
                            .foregroundStyle(.white.opacity(0.4))
                            .tracking(1.5)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            SettingsFeatureRow(icon: "rectangle.stack.fill", title: "Mẫu template không giới hạn")
                            SettingsFeatureRow(icon: "square.stack.3d.up.fill", title: "Tính năng Batch Export")
                            SettingsFeatureRow(icon: "wand.and.stars", title: "Chèn logo doanh nghiệp sắc nét")
                            SettingsFeatureRow(icon: "nosign", title: "Không có quảng cáo làm phiền")
                        }
                        .padding(.all, 20)
                        .background(.white.opacity(0.02), in: RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.06), lineWidth: 1))
                    }
                    .padding(.horizontal, 20)
                    
                    // Restore Purchases & Info Card
                    VStack(alignment: .leading, spacing: 16) {
                        Button {
                            Task { await store.restore() }
                        } label: {
                            HStack {
                                Spacer()
                                Label("Khôi phục giao dịch đã mua", systemImage: "arrow.clockwise.circle.fill")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.yellow)
                                Spacer()
                            }
                            .padding(.all, 16)
                            .background(.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.08), lineWidth: 1))
                        }
                        
                        // App Version Info
                        VStack(spacing: 4) {
                            Text("TimeMark VN v5.0 (Build 2026)")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.3))
                            Text("Thiết kế tối ưu cho StoreKit 2 & iOS 17+")
                                .font(.system(size: 10))
                                .foregroundStyle(.white.opacity(0.25))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
        }
        .sheet(isPresented: $paywall) { ProPaywallView() }
        .sheet(isPresented: $batch) { BatchExportView() }
    }
}

struct SettingsFeatureRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(.yellow)
                .frame(width: 24, height: 24)
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(.white)
            Spacer()
            Image(systemName: "checkmark")
                .font(.caption.bold())
                .foregroundStyle(.yellow)
        }
    }
}
