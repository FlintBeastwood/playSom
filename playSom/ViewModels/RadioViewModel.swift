import Foundation
import SwiftUI
import Combine

/// Central state management for the radio player.
/// Coordinates between AudioPlayer, SomaFMService, NowPlayingService, and FavoritesService.
@MainActor
final class RadioViewModel: ObservableObject {

    // MARK: - Published State

    @Published var channels: [Channel] = []
    @Published var currentChannel: Channel?
    @Published var isPlaying = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedFormat: StreamFormat = .aac
    @Published var selectedQuality: StreamQuality = .highest
    @Published var showingFavorites = false

    // MARK: - Services

    let audioPlayer = AudioPlayer()
    let favoritesService = FavoritesService()
    let pinnedService: PinnedChannelsService
    private let somaService = SomaFMService()
    private let nowPlayingService = NowPlayingService()
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?

    // MARK: - Computed

    /// Channels filtered by search text, partitioned with pinned channels first.
    /// Pinned and unpinned groups each preserve the existing listener-count sort.
    var displayedChannels: [Channel] {
        let base = searchText.isEmpty
            ? channels
            : channels.filter {
                let query = searchText.lowercased()
                return $0.title.lowercased().contains(query) ||
                       $0.genre.lowercased().contains(query) ||
                       $0.description.lowercased().contains(query) ||
                       $0.dj.lowercased().contains(query)
            }

        let pinned   = base.filter {  pinnedService.isPinned(id: $0.id) }
        let unpinned = base.filter { !pinnedService.isPinned(id: $0.id) }
        return pinned + unpinned
    }

    /// Kept for the Phase 1 baseline test only. Phase 2 uses `displayedChannels`.
    var filteredChannels: [Channel] { displayedChannels }

    /// Volume binding that forwards to the audio player.
    var volume: Float {
        get { audioPlayer.volume }
        set { audioPlayer.volume = newValue }
    }

    /// Checks if the currently playing track is a favorite.
    var isCurrentTrackFavorite: Bool {
        guard let channel = currentChannel, !channel.lastPlaying.isEmpty else { return false }
        return favoritesService.isFavorite(title: channel.lastPlaying, channelId: channel.id)
    }

    // MARK: - Init

    init(pinnedService: PinnedChannelsService? = nil) {
        // Construct the default service inside the @MainActor init body rather
        // than as a default-argument expression — the latter is evaluated in
        // the caller's isolation context, which is nonisolated for `@main App`
        // property initializers.
        self.pinnedService = pinnedService ?? PinnedChannelsService()
        setupBindings()
        setupNowPlaying()
    }

    // MARK: - Channel Loading

    /// Loads all channels from the SomaFM API.
    func loadChannels() async {
        let fetched = await somaService.fetchChannels()
        channels = fetched.sorted { $0.listenerCount > $1.listenerCount }
    }

    /// Periodically refreshes the channel list (every 60 seconds) to update
    /// listener counts and "now playing" info.
    func startPeriodicRefresh() {
        refreshTimer?.invalidate()
        // 5 minutes is plenty for listener counts and seasonal channel changes;
        // the live track is driven by ICY metadata from the stream itself.
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                await self.refreshChannels()
            }
        }
    }

    func stopPeriodicRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    /// Refreshes channels without disrupting current playback.
    private func refreshChannels() async {
        let fetched = await somaService.fetchChannels()
        let sorted = fetched.sorted { $0.listenerCount > $1.listenerCount }

        // Update channel list
        channels = sorted

        // Update current channel's listener count and other metadata.
        // `lastPlaying` is exclusively ICY-driven now — preserve whatever the
        // ICY sink (or the empty initial state) put on currentChannel.
        if let current = currentChannel,
           let updated = sorted.first(where: { $0.id == current.id }) {
            currentChannel = updated.with(lastPlaying: current.lastPlaying)
        }
    }

    // MARK: - Playback

    /// Plays a specific channel.
    func play(channel: Channel) async {
        // Wipe any polled `lastPlaying` value — live track is exclusively
        // sourced from the stream's ICY metadata once it arrives.
        currentChannel = channel.with(lastPlaying: "")
        isLoading = true
        errorMessage = nil

        await audioPlayer.play(channel: channel, format: selectedFormat, quality: selectedQuality)

        if audioPlayer.error != nil {
            errorMessage = audioPlayer.error
        } else {
            nowPlayingService.update(channel: channel)
        }
        isLoading = false
    }

    /// Stops playback completely.
    func stop() {
        audioPlayer.stop()
        currentChannel = nil
        nowPlayingService.clear()
    }

    /// Toggles play/pause.
    func togglePlayPause() {
        audioPlayer.togglePlayPause()
        if let channel = currentChannel {
            nowPlayingService.setPlaybackState(isPlaying: audioPlayer.isPlaying)
            if audioPlayer.isPlaying {
                nowPlayingService.update(channel: channel)
            }
        }
    }

    // MARK: - Favorites

    /// Toggles the favorite status of the currently playing track.
    func toggleCurrentTrackFavorite() {
        guard let channel = currentChannel, !channel.lastPlaying.isEmpty else { return }
        favoritesService.toggleFavorite(
            title: channel.lastPlaying,
            channelId: channel.id,
            channelTitle: channel.title
        )
        objectWillChange.send()
    }

    // MARK: - Private Setup

    private func setupBindings() {
        // Forward audio player state to our published properties
        audioPlayer.$isPlaying
            .receive(on: DispatchQueue.main)
            .assign(to: &$isPlaying)

        audioPlayer.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)

        audioPlayer.$error
            .receive(on: DispatchQueue.main)
            .assign(to: &$errorMessage)

        // Re-publish when favorites change
        favoritesService.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        // Re-publish when pin set changes
        pinnedService.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        audioPlayer.$liveTrack
            .receive(on: DispatchQueue.main)
            .sink { [weak self] live in
                guard let self, let live, !live.isEmpty, let channel = self.currentChannel else { return }
                if channel.lastPlaying != live {
                    self.currentChannel = channel.with(lastPlaying: live)
                    self.nowPlayingService.updateTrackTitle(live)
                }
            }
            .store(in: &cancellables)
    }

    private func setupNowPlaying() {
        nowPlayingService.configureCommandCenter()
        nowPlayingService.onPlayPauseToggle = { [weak self] in
            self?.togglePlayPause()
        }
    }

    // MARK: - DEBUG Accessors (test-only)

    #if DEBUG
    /// Test-only: how many Combine subscriptions are currently retained.
    var debug_cancellableCount: Int { cancellables.count }

    /// Test-only: whether the periodic refresh timer is currently scheduled.
    var debug_isRefreshTimerScheduled: Bool { refreshTimer != nil }
    #endif
}
