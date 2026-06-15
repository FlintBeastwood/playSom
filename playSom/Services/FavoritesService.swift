import Foundation

/// Persists favorite songs to UserDefaults.
@MainActor
final class FavoritesService: ObservableObject {

    private static let storageKey = "com.playSom.favoriteSongs"

    @Published private(set) var favorites: [FavoriteSong] = []

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        loadFavorites()
    }

    // MARK: - Public API

    /// Adds the currently playing track as a favorite.
    func addFavorite(title: String, channelId: String, channelTitle: String) {
        // Don't add duplicates (same title on same channel)
        guard !isFavorite(title: title, channelId: channelId) else { return }

        let song = FavoriteSong(title: title, channelId: channelId, channelTitle: channelTitle)
        favorites.insert(song, at: 0) // newest first
        saveFavorites()
    }

    /// Removes a favorite by its ID.
    func removeFavorite(id: UUID) {
        favorites.removeAll { $0.id == id }
        saveFavorites()
    }

    /// Removes a favorite by title and channel.
    func removeFavorite(title: String, channelId: String) {
        favorites.removeAll { $0.title == title && $0.channelId == channelId }
        saveFavorites()
    }

    /// Checks if a track is already favorited.
    func isFavorite(title: String, channelId: String) -> Bool {
        favorites.contains { $0.title == title && $0.channelId == channelId }
    }

    /// Toggles favorite status for a track. Returns true if added, false if removed.
    @discardableResult
    func toggleFavorite(title: String, channelId: String, channelTitle: String) -> Bool {
        if isFavorite(title: title, channelId: channelId) {
            removeFavorite(title: title, channelId: channelId)
            return false
        } else {
            addFavorite(title: title, channelId: channelId, channelTitle: channelTitle)
            return true
        }
    }

    /// Removes all favorites.
    func clearAll() {
        favorites.removeAll()
        saveFavorites()
    }

    // MARK: - Persistence

    private func saveFavorites() {
        do {
            let data = try JSONEncoder().encode(favorites)
            defaults.set(data, forKey: Self.storageKey)
        } catch {
            print("[FavoritesService] Failed to save favorites: \(error)")
        }
    }

    private func loadFavorites() {
        guard let data = defaults.data(forKey: Self.storageKey) else { return }
        do {
            favorites = try JSONDecoder().decode([FavoriteSong].self, from: data)
        } catch {
            print("[FavoritesService] Failed to load favorites: \(error)")
        }
    }
}
