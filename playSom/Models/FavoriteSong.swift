import Foundation

/// A song that the user has favorited.
struct FavoriteSong: Identifiable, Codable, Hashable, TrackParseable {
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

    // MARK: - TrackParseable

    /// Maps to the protocol's raw string for artist/track parsing.
    var rawTrackString: String { title }
}

