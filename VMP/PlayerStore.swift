import Foundation
import AVFoundation
import MediaPlayer
import Combine

final class PlayerStore: NSObject, ObservableObject {
    @Published private(set) var currentTrack: Track?
    @Published private(set) var isPlaying = false
    @Published var progress: Double = 0

    private var player: AVAudioPlayer?
    private var timer: Timer?

    override init() {
        super.init()
        configureAudioSession()
        configureRemoteCommands()
    }

    func play(_ track: Track) {
        currentTrack = track

        // Демо-режим: если у трека нет локального аудиофайла,
        // интерфейс всё равно переключается в состояние воспроизведения.
        // Реальный URL/файл подключается в AudioSource.
        isPlaying = true
        progress = 0
        startTimer()
        updateNowPlaying()
    }

    func toggle() {
        guard currentTrack != nil else { return }
        isPlaying.toggle()
        if isPlaying {
            startTimer()
        } else {
            timer?.invalidate()
        }
        updateNowPlaying()
    }

    func seek(to value: Double) {
        progress = min(max(value, 0), 1)
        if let player {
            player.currentTime = player.duration * progress
        }
    }

    func stop() {
        player?.stop()
        timer?.invalidate()
        isPlaying = false
        progress = 0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self, self.isPlaying else { return }
            guard let player = self.player, player.duration > 0 else { return }
            self.progress = player.currentTime / player.duration
        }
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: []
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session error:", error)
        }
    }

    private func configureRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.addTarget { [weak self] _ in
            self?.isPlaying = true
            self?.startTimer()
            return .success
        }

        center.pauseCommand.addTarget { [weak self] _ in
            self?.isPlaying = false
            self?.timer?.invalidate()
            return .success
        }

        center.nextTrackCommand.addTarget { [weak self] _ in
            NotificationCenter.default.post(name: .vmpNext, object: nil)
            return .success
        }

        center.previousTrackCommand.addTarget { [weak self] _ in
            self?.seek(to: 0)
            return .success
        }
    }

    private func updateNowPlaying() {
        guard let track = currentTrack else { return }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyArtist: track.artist,
            MPMediaItemPropertyAlbumTitle: track.album,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: 0,
            MPMediaItemPropertyPlaybackDuration: 0,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1 : 0
        ]
    }

    deinit {
        timer?.invalidate()
    }
}

extension Notification.Name {
    static let vmpNext = Notification.Name("VMPNextTrack")
}
