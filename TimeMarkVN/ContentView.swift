import SwiftUI

struct ContentView: View {
    @State private var tab = 0

    var body: some View {
        TabView(selection: $tab) {
            CameraView().tabItem { Label(NSLocalizedString("Camera", comment: ""), systemImage: "camera.fill") }.tag(0)
            TemplateEditorView().tabItem { Label(NSLocalizedString("Thiết kế", comment: ""), systemImage: "paintbrush.fill") }.tag(1)
            GalleryView().tabItem { Label(NSLocalizedString("Thư viện", comment: ""), systemImage: "photo.on.rectangle.angled") }.tag(2)
            SettingsView().tabItem { Label(NSLocalizedString("Cài đặt", comment: ""), systemImage: "gearshape.fill") }.tag(3)
        }
        .tint(.yellow)
    }
}
