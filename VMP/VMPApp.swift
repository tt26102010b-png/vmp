import SwiftUI

@main
struct VMPApp: App {
    @StateObject private var player = PlayerStore()
    @StateObject private var library = LibraryStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(player)
                .environmentObject(library)
                .preferredColorScheme(.dark)
        }
    }
}
