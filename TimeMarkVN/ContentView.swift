import SwiftUI
import LocalAuthentication

struct ContentView: View {
    @State private var tab = 0
    @AppStorage("isBiometricLockEnabled") private var isBiometricLockEnabled = false
    @State private var isUnlocked = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            TabView(selection: $tab) {
                CameraView().tabItem { Label(NSLocalizedString("Camera", comment: ""), systemImage: "camera.fill") }.tag(0)
                TemplateEditorView().tabItem { Label(NSLocalizedString("Thiết kế", comment: ""), systemImage: "paintbrush.fill") }.tag(1)
                GalleryView().tabItem { Label(NSLocalizedString("Thư viện", comment: ""), systemImage: "photo.on.rectangle.angled") }.tag(2)
                SettingsView().tabItem { Label(NSLocalizedString("Cài đặt", comment: ""), systemImage: "gearshape.fill") }.tag(3)
            }
            .tint(.yellow)
            
            if isBiometricLockEnabled && !isUnlocked {
                VStack(spacing: 24) {
                    Spacer()
                    
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(.yellow)
                        .shadow(color: .yellow.opacity(0.3), radius: 10)
                    
                    VStack(spacing: 8) {
                        Text(NSLocalizedString("Ứng dụng đang khóa", comment: ""))
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        
                        Text(NSLocalizedString("Vui lòng xác thực Face ID / Touch ID để tiếp tục", comment: ""))
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    Spacer()
                    
                    Button {
                        authenticate()
                    } label: {
                        HStack {
                            Image(systemName: "faceid")
                            Text(NSLocalizedString("Mở khóa", comment: ""))
                        }
                        .font(.body.bold())
                        .foregroundStyle(.black)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(.yellow, in: Capsule())
                    }
                    .padding(.bottom, 60)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
                .onAppear {
                    authenticate()
                }
            }
        }
        .onChange(of: scenePhase) { oldValue, newValue in
            if newValue == .background || newValue == .inactive {
                if isBiometricLockEnabled {
                    isUnlocked = false
                }
            } else if newValue == .active {
                if isBiometricLockEnabled && !isUnlocked {
                    authenticate()
                }
            }
        }
    }

    private func authenticate() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = NSLocalizedString("Xác thực Face ID để bảo mật dữ liệu hiện trường", comment: "")
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        withAnimation {
                            isUnlocked = true
                        }
                    }
                }
            }
        } else {
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: NSLocalizedString("Xác thực mã PIN thiết bị để mở khóa", comment: "")) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        withAnimation {
                            isUnlocked = true
                        }
                    }
                }
            }
        }
    }
}
