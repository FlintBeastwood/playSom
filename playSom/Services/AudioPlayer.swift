import AVFoundation
import Combine
import Foundation

/// Manages audio playback of SomaFM streams using AVPlayer.
@MainActor
final class AudioPlayer: ObservableObject {

    // MARK: - Published State

    @Published private(set) var isPlaying = false
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    @Published var volume: Float = 0.75 {
        didSet { player?.volume = volume }
    }

    // MARK: - Private State

    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var statusObserver: AnyCancellable?
    private let somaService = SomaFMService()

    /// Standard browser User-Agent to prevent server-side blocks on SomaFM streams.
    private static let browserUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"

    // MARK: - Playback Controls

    /// Starts playing a channel by resolving its .pls playlist URL.
    func play(channel: Channel, format: StreamFormat = .aac, quality: StreamQuality = .highest) async {
        stop()
        isLoading = true
        error = nil

        guard let playlistURL = channel.streamURL(preferredFormat: format, preferredQuality: quality) else {
            error = "No stream URL available for this channel."
            isLoading = false
            return
        }

        do {
            // Parse the .pls file to get the actual stream URL
            let streamURL = try await somaService.parsePlaylistURL(playlistURL)
            
            // Pre-resolve 302 redirects using a browser User-Agent to acquire a valid _ic2 session token
            let resolvedURL = await resolveRedirects(for: streamURL)
            
            startPlayback(url: resolvedURL)
        } catch {
            self.error = "Failed to load stream: \(error.localizedDescription)"
            isLoading = false
        }
    }

    /// Stops the current playback.
    func stop() {
        player?.pause()
        player = nil
        playerItem = nil
        statusObserver = nil
        isPlaying = false
        isLoading = false
        error = nil
    }

    /// Toggles play/pause for the current stream.
    func togglePlayPause() {
        guard let player else { return }
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }

    // MARK: - Stream Resolution

    /// Resolves any 302 redirects for the given URL using a lightweight HEAD request with a browser User-Agent.
    private func resolveRedirects(for url: URL) async -> URL {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.setValue(Self.browserUserAgent, forHTTPHeaderField: "User-Agent")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse,
               let resolvedURL = httpResponse.url {
                return resolvedURL
            }
        } catch {
            print("[AudioPlayer] Redirect resolution failed: \(error). Using original URL.")
        }
        return url
    }

    private func startPlayback(url: URL) {
        // Construct the AVURLAsset with a standard Safari browser User-Agent to prevent server-side blocks
        let asset = AVURLAsset(url: url, options: [AVURLAssetHTTPUserAgentKey: Self.browserUserAgent])
        let item = AVPlayerItem(asset: asset)
        let newPlayer = AVPlayer(playerItem: item)
        newPlayer.volume = volume

        // Observe the player item status to know when playback is ready
        statusObserver = item.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self else { return }
                switch status {
                case .readyToPlay:
                    self.isLoading = false
                    self.isPlaying = true
                    newPlayer.play()
                case .failed:
                    self.isLoading = false
                    self.error = item.error?.localizedDescription ?? "Playback failed."
                    self.isPlaying = false
                default:
                    break
                }
            }

        self.playerItem = item
        self.player = newPlayer
    }
}
