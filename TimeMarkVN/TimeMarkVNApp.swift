import SwiftUI

@main
struct TimeMarkVNApp: App {
    @StateObject private var location = LocationManager()
    @StateObject private var stamp = StampStore()
    @StateObject private var store = ProStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(location)
                .environmentObject(stamp)
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
    }
}
