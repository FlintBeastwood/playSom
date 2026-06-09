import Foundation

/// A channel the user has pinned to the top of the channel list.
struct PinnedChannel: Codable, Hashable, Identifiable {
    let id: String
    let pinnedAt: Date
}
