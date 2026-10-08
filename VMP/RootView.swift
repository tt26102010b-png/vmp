import SwiftUI

struct RootView: View {
    @EnvironmentObject private var player: PlayerStore
    @EnvironmentObject private var library: LibraryStore

    @State private var tab: AppTab = .home
    @State private var search = ""
    @State private var showPlayer = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                navigation

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        SearchBar(text: $search)

                        switch tab {
                        case .home:
                            HomeView(search: search)
                        case .library:
                            LibraryView()
                        case .browse:
                            BrowseView()
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, player.currentTrack == nil ? 24 : 100)
                }
            }

            if let track = player.currentTrack {
                MiniPlayer(track: track, player: player) {
                    showPlayer = true
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 4)
            }
        }
        .sheet(isPresented: $showPlayer) {
            FullPlayerView()
                .environmentObject(player)
                .environmentObject(library)
        }
        .onReceive(NotificationCenter.default.publisher(for: .vmpNext)) { _ in
            playNext()
        }
    }

    private var navigation: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(AppTab.allCases) { item in
                    Button(item.rawValue) {
                        tab = item
                    }
                    .font(.system(size: 13, weight: tab == item ? .semibold : .regular))
                    .foregroundStyle(tab == item ? .white : .secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 7)
                    .background(tab == item ? .white.opacity(0.12) : .clear)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 7)
            .padding(.bottom, 5)
        }
    }

    private func playNext() {
        guard let current = player.currentTrack,
              let index = TrackCatalog.all.firstIndex(of: current) else {
            if let first = TrackCatalog.all.first {
                player.play(first)
            }
            return
        }

        let nextIndex = (index + 1) % TrackCatalog.all.count
        player.play(TrackCatalog.all[nextIndex])
    }
}

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Поиск музыки", text: $text)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .background(.white.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.11), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct HomeView: View {
    @EnvironmentObject private var player: PlayerStore
    @EnvironmentObject private var library: LibraryStore

    let search: String

    private var tracks: [Track] {
        guard !search.isEmpty else { return TrackCatalog.all }
        return TrackCatalog.all.filter {
            $0.title.localizedCaseInsensitiveContains(search) ||
            $0.artist.localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Музыка")
                .font(.title2.bold())

            LazyVStack(spacing: 2) {
                ForEach(tracks) { track in
                    TrackRow(track: track)
                }
            }
        }
    }
}

struct TrackRow: View {
    @EnvironmentObject private var player: PlayerStore
    @EnvironmentObject private var library: LibraryStore

    let track: Track

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [.purple.opacity(0.75), .blue.opacity(0.65)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Image(systemName: track.symbol)
                        .foregroundStyle(.white.opacity(0.85))
                )
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 3) {
                Text(track.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                Text(track.artist)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                library.toggleFavorite(track)
            } label: {
                Image(systemName: library.isFavorite(track) ? "heart.fill" : "heart")
                    .foregroundStyle(library.isFavorite(track) ? .pink : .secondary)
            }
            .buttonStyle(.plain)

            Button {
                player.play(track)
            } label: {
                Image(systemName: player.currentTrack?.id == track.id && player.isPlaying ? "pause.fill" : "play.fill")
                    .frame(width: 32, height: 32)
                    .background(.white.opacity(0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 7)
    }
}

struct MiniPlayer: View {
    let track: Track
    @ObservedObject var player: PlayerStore
    let open: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 7)
                .fill(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 2) {
                Text(track.title).font(.caption.weight(.semibold)).lineLimit(1)
                Text(track.artist).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            }

            Spacer()

            Button { player.toggle() } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
            }
            .buttonStyle(.plain)

            Button {
                NotificationCenter.default.post(name: .vmpNext, object: nil)
            } label: {
                Image(systemName: "forward.fill")
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture(perform: open)
    }
}

struct FullPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var player: PlayerStore
    @EnvironmentObject private var library: LibraryStore

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [.black, .purple.opacity(0.22), .black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                if let track = player.currentTrack {
                    VStack(spacing: 24) {
                        Spacer()

                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [.purple.opacity(0.8), .blue.opacity(0.65)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                Image(systemName: track.symbol)
                                    .font(.system(size: 70))
                            )
                            .frame(width: 290, height: 290)

                        VStack(spacing: 5) {
                            Text(track.title)
                                .font(.title2.bold())
                            Text(track.artist)
                                .foregroundStyle(.secondary)
                        }

                        Slider(value: $player.progress, in: 0...1) { editing in
                            if !editing {
                                player.seek(to: player.progress)
                            }
                        }

                        HStack(spacing: 45) {
                            Button {
                                player.seek(to: 0)
                            } label: {
                                Image(systemName: "backward.fill")
                                    .font(.title2)
                            }

                            Button {
                                player.toggle()
                            } label: {
                                Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 58))
                            }

                            Button {
                                NotificationCenter.default.post(name: .vmpNext, object: nil)
                            } label: {
                                Image(systemName: "forward.fill")
                                    .font(.title2)
                            }
                        }

                        Spacer()
                    }
                    .padding(28)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Закрыть") { dismiss() }
                }

                if let track = player.currentTrack {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            library.toggleFavorite(track)
                        } label: {
                            Image(systemName: library.isFavorite(track) ? "heart.fill" : "heart")
                        }
                    }
                }
            }
        }
    }
}

struct LibraryView: View {
    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var player: PlayerStore

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Моя музыка")
                .font(.title2.bold())

            let favorites = TrackCatalog.all.filter { library.isFavorite($0) }

            if favorites.isEmpty {
                Text("Здесь будут твои любимые треки.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(favorites) { track in
                    TrackRow(track: track)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct BrowseView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Обзор")
                .font(.title2.bold())
            Text("Здесь позже можно добавить подборки, жанры и новые релизы.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
