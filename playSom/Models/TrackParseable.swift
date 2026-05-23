import Foundation

/// Shared protocol for types that represent a SomaFM track string (e.g. "Artist - Title").
/// Provides default implementations for parsing artist/track and building a Bandcamp search URL.
///
/// SomaFM always uses " - " as the separator between artist and title.
/// If the title itself contains " - ", everything after the first separator is rejoined.
protocol TrackParseable {
    /// The raw "Artist - Title" string to parse.
    var rawTrackString: String { get }
}

extension TrackParseable {

    /// The artist portion, e.g. "Groovecatcher" from "Groovecatcher - What The Croupier Saw".
    var artist: String {
        let parts = rawTrackString.components(separatedBy: " - ")
        guard parts.count >= 2 else { return rawTrackString }
        return parts[0].trimmingCharacters(in: .whitespaces)
    }

    /// The track name portion, e.g. "What The Croupier Saw".
    /// Rejoins with " - " if the title itself contains the separator.
    var trackName: String {
        let parts = rawTrackString.components(separatedBy: " - ")
        guard parts.count >= 2 else { return rawTrackString }
        return parts.dropFirst().joined(separator: " - ").trimmingCharacters(in: .whitespaces)
    }

    /// Bandcamp search URL for "Artist+Trackname".
    var bandcampSearchURL: URL? {
        guard !rawTrackString.isEmpty else { return nil }
        let query = "\(artist)+\(trackName)"
        var components = URLComponents(string: "https://bandcamp.com/search")
        components?.queryItems = [URLQueryItem(name: "q", value: query)]
        return components?.url
    }
}
