import Foundation
import Combine

final class LibraryStore: ObservableObject {
    @Published private(set) var favorites: Set<UUID> = []

    func toggleFavorite(_ track: Track) {
        if favorites.contains(track.id) {
            favorites.remove(track.id)
        } else {
            favorites.insert(track.id)
        }
    }

    func isFavorite(_ track: Track) -> Bool {
        favorites.contains(track.id)
    }
}
