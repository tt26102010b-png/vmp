import Foundation

struct Track: Identifiable, Hashable {
    let id: UUID
    let title: String
    let artist: String
    let album: String
    let symbol: String

    init(id: UUID = UUID(), title: String, artist: String, album: String, symbol: String) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.symbol = symbol
    }
}

enum AppTab: String, CaseIterable, Identifiable {
    case home = "Главная"
    case library = "Моя музыка"
    case browse = "Обзор"

    var id: String { rawValue }
}
