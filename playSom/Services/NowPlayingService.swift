import Foundation
import MediaPlayer

/// Updates the macOS Now Playing info center with current track/channel information.
/// This enables:
/// - Track info in the system Now Playing widget
/// - Media key (play/pause) support
@MainActor
final class NowPlayingService {

    private var commandCenterConfigured = false

    /// Callback for play/pause toggle from media keys.
    var onPlayPauseToggle: (() -> Void)?

    // MARK: - Now Playing Info

    /// Updates the Now Playing info with the current channel and track.
    func update(channel: Channel) {
        var info = [String: Any]()
        info[MPMediaItemPropertyTitle] = channel.lastPlaying
        info[MPMediaItemPropertyArtist] = channel.title
        info[MPMediaItemPropertyAlbumTitle] = channel.description
        info[MPNowPlayingInfoPropertyIsLiveStream] = true
        info[MPNowPlayingInfoPropertyPlaybackRate] = 1.0

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        MPNowPlayingInfoCenter.default().playbackState = .playing
    }

    /// Clears the Now Playing info when playback stops.
    func clear() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        MPNowPlayingInfoCenter.default().playbackState = .stopped
    }

    /// Sets playback state (playing or paused).
    func setPlaybackState(isPlaying: Bool) {
        MPNowPlayingInfoCenter.default().playbackState = isPlaying ? .playing : .paused
    }

    // MARK: - Remote Command Center

    /// Configures the remote command center for media key support.
    /// Call this once during app setup.
    func configureCommandCenter() {
        guard !commandCenterConfigured else { return }
        commandCenterConfigured = true

        let center = MPRemoteCommandCenter.shared()

        // Enable play/pause toggle
        center.togglePlayPauseCommand.isEnabled = true
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.onPlayPauseToggle?()
            return .success
        }

        center.playCommand.isEnabled = true
        center.playCommand.addTarget { [weak self] _ in
            self?.onPlayPauseToggle?()
            return .success
        }

        center.pauseCommand.isEnabled = true
        center.pauseCommand.addTarget { [weak self] _ in
            self?.onPlayPauseToggle?()
            return .success
        }

        // Disable unsupported commands
        center.nextTrackCommand.isEnabled = false
        center.previousTrackCommand.isEnabled = false
        center.seekForwardCommand.isEnabled = false
        center.seekBackwardCommand.isEnabled = false
    }
}
