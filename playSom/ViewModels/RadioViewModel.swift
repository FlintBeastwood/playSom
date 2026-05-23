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
    private let somaService = SomaFMService()
    private let nowPlayingService = NowPlayingService()
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?

    // MARK: - Computed

    /// Channels filtered by search text.
    var filteredChannels: [Channel] {
        if searchText.isEmpty {
            return channels
        }
        let query = searchText.lowercased()
        return channels.filter {
            $0.title.lowercased().contains(query) ||
            $0.genre.lowercased().contains(query) ||
            $0.description.lowercased().contains(query) ||
            $0.dj.lowercased().contains(query)
        }
    }

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

    init() {
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
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
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

        // Update current channel's metadata (now playing, listeners)
        if let current = currentChannel,
           let updated = sorted.first(where: { $0.id == current.id }) {
            currentChannel = updated
            if isPlaying {
                nowPlayingService.update(channel: updated)
            }
        }
    }

    // MARK: - Playback

    /// Plays a specific channel.
    func play(channel: Channel) async {
        currentChannel = channel
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
    }

    private func setupNowPlaying() {
        nowPlayingService.configureCommandCenter()
        nowPlayingService.onPlayPauseToggle = { [weak self] in
            self?.togglePlayPause()
        }
    }
}
