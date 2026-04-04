import SwiftUI

@main
struct SpaceViewApp: App {
    @State private var favorites = FavoritesStore()

    init() {
        URLCache.shared.memoryCapacity = 50  * 1024 * 1024   // 50 MB RAM
        URLCache.shared.diskCapacity   = 300 * 1024 * 1024   // 300 MB disk
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(favorites)
        }
    }
}
