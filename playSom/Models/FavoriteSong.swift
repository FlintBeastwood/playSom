import Foundation

/// A song that the user has favorited.
struct FavoriteSong: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String         // e.g. "Groovecatcher - What The Croupier Saw"
    let channelId: String     // e.g. "groovesalad"
    let channelTitle: String  // e.g. "Groove Salad"
    let savedAt: Date

    init(title: String, channelId: String, channelTitle: String) {
        self.id = UUID()
        self.title = title
        self.channelId = channelId
        self.channelTitle = channelTitle
        self.savedAt = Date()
    }

    // MARK: - Helpers

    /// The artist part of title, e.g. "Groovecatcher" from "Groovecatcher - What The Croupier Saw".
    /// SomaFM always uses " - " as separator between artist and title.
    var artist: String {
        let parts = title.components(separatedBy: " - ")
        guard parts.count >= 2 else { return title }
        return parts[0].trimmingCharacters(in: .whitespaces)
    }

    /// The track title part of title, e.g. "What The Croupier Saw".
    /// If the title itself contains " - ", we rejoin everything after the first separator.
    var trackName: String {
        let parts = title.components(separatedBy: " - ")
        guard parts.count >= 2 else { return title }
        return parts.dropFirst().joined(separator: " - ").trimmingCharacters(in: .whitespaces)
    }

    /// Bandcamp search URL for the track.
    /// Searches for "Artist+Trackname" so Bandcamp finds the most relevant results.
    var bandcampSearchURL: URL? {
        guard !title.isEmpty else { return nil }
        let query = "\(artist)+\(trackName)"
        var components = URLComponents(string: "https://bandcamp.com/search")
        components?.queryItems = [URLQueryItem(name: "q", value: query)]
        return components?.url
    }
}
