import Foundation

/// Represents a SomaFM radio channel.
struct Channel: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let description: String
    let dj: String
    let genre: String
    let image: String
    let largeimage: String
    let xlimage: String
    let listeners: String
    let lastPlaying: String
    let playlists: [Playlist]

    /// A single stream endpoint for a channel.
    struct Playlist: Codable, Hashable {
        let url: String
        let format: String   // "mp3", "aac", "aacp"
        let quality: String  // "highest", "high", "low"
    }

    // MARK: - Helpers

    /// Returns the best-quality playlist URL for the preferred format.
    func streamURL(preferredFormat: StreamFormat = .aac, preferredQuality: StreamQuality = .highest) -> URL? {
        // Try preferred format + quality first
        if let match = playlists.first(where: { $0.format == preferredFormat.rawValue && $0.quality == preferredQuality.rawValue }) {
            return URL(string: match.url)
        }
        // Fallback: any playlist with preferred quality
        if let match = playlists.first(where: { $0.quality == preferredQuality.rawValue }) {
            return URL(string: match.url)
        }
        // Fallback: first available
        return playlists.first.flatMap { URL(string: $0.url) }
    }

    /// Listener count as integer for sorting.
    var listenerCount: Int {
        Int(listeners) ?? 0
    }

    /// URL for the channel artwork (large version).
    var artworkURL: URL? {
        URL(string: xlimage.isEmpty ? largeimage : xlimage)
    }

    // MARK: - Track Parsing

    /// The artist part of lastPlaying, e.g. "Groovecatcher" from "Groovecatcher - What The Croupier Saw".
    /// SomaFM always uses " - " as separator between artist and title.
    var artist: String {
        let parts = lastPlaying.components(separatedBy: " - ")
        guard parts.count >= 2 else { return lastPlaying }
        return parts[0].trimmingCharacters(in: .whitespaces)
    }

    /// The track title part of lastPlaying, e.g. "What The Croupier Saw".
    /// If the title itself contains " - ", we rejoin everything after the first separator.
    var trackName: String {
        let parts = lastPlaying.components(separatedBy: " - ")
        guard parts.count >= 2 else { return lastPlaying }
        return parts.dropFirst().joined(separator: " - ").trimmingCharacters(in: .whitespaces)
    }

    /// Bandcamp search URL for the current track.
    /// Searches for "Artist+Trackname" so Bandcamp finds the most relevant results.
    var bandcampSearchURL: URL? {
        guard !lastPlaying.isEmpty else { return nil }
        // Use artist + track for a more targeted search than the full string
        let query = "\(artist)+\(trackName)"
        var components = URLComponents(string: "https://bandcamp.com/search")
        components?.queryItems = [URLQueryItem(name: "q", value: query)]
        return components?.url
    }
}

/// Wrapper for decoding the SomaFM channels.json response.
struct ChannelResponse: Codable {
    let channels: [Channel]
}

// MARK: - Enums

enum StreamFormat: String, CaseIterable {
    case aac = "aac"
    case mp3 = "mp3"
    case aacp = "aacp"

    var displayName: String {
        switch self {
        case .aac: return "AAC 128k"
        case .mp3: return "MP3 128k"
        case .aacp: return "AAC+ 64k"
        }
    }
}

enum StreamQuality: String, CaseIterable {
    case highest = "highest"
    case high = "high"
    case low = "low"

    var displayName: String {
        switch self {
        case .highest: return "Highest"
        case .high: return "High"
        case .low: return "Low"
        }
    }
}
