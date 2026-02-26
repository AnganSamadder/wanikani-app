import Foundation
import AVFoundation
import SwiftUI

@MainActor
final class AudioPlaybackService: ObservableObject {
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var currentURL: URL?
    private var player: AVPlayer?
    private var finishObserver: Any?

    func play(url: URL) {
        stop()
        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)
        currentURL = url
        isPlaying = true

        finishObserver = NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isPlaying = false
                self?.currentURL = nil
            }
        }

        player?.play()
    }

    func stop() {
        if let observer = finishObserver {
            NotificationCenter.default.removeObserver(observer)
            finishObserver = nil
        }
        player?.pause()
        player = nil
        isPlaying = false
        currentURL = nil
    }

    func toggle(url: URL) {
        if isPlaying && currentURL == url {
            stop()
        } else {
            play(url: url)
        }
    }
}
