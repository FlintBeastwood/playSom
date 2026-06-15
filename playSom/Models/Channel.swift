import Foundation

/// Represents a SomaFM radio channel.
struct Channel: Identifiable, Codable, Hashable, TrackParseable {
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

    // MARK: - TrackParseable

    /// Maps to the protocol's raw string for artist/track parsing.
    var rawTrackString: String { lastPlaying }

    /// Returns a copy of this channel with `lastPlaying` replaced. Used to
    /// merge live ICY metadata so downstream derived properties (artist,
    /// trackName, bandcampSearchURL) reflect the live track.
    func with(lastPlaying newLastPlaying: String) -> Channel {
        Channel(
            id: id, title: title, description: description, dj: dj, genre: genre,
            image: image, largeimage: largeimage, xlimage: xlimage,
            listeners: listeners, lastPlaying: newLastPlaying, playlists: playlists
        )
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
