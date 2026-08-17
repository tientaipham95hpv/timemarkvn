import SwiftUI

struct ContentView: View {
    @State private var tab = 0

    var body: some View {
        TabView(selection: $tab) {
            CameraView().tabItem { Label("Camera", systemImage: "camera.fill") }.tag(0)
            TemplateEditorView().tabItem { Label("Thiết kế", systemImage: "paintbrush.fill") }.tag(1)
            GalleryView().tabItem { Label("Thư viện", systemImage: "photo.on.rectangle.angled") }.tag(2)
            SettingsView().tabItem { Label("Cài đặt", systemImage: "gearshape.fill") }.tag(3)
        }
        .tint(.yellow)
    }
}
