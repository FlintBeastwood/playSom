import Testing
@testable import playSom

@Suite("Channel.with(lastPlaying:)")
struct ChannelMergeTests {

    private static func sample(lastPlaying: String = "Original Artist - Original Track") -> Channel {
        Channel(
            id: "c", title: "Title", description: "Desc", dj: "DJ", genre: "g",
            image: "img", largeimage: "lg", xlimage: "xl",
            listeners: "5", lastPlaying: lastPlaying,
            playlists: [.init(url: "https://example.com", format: "aac", quality: "highest")]
        )
    }

    @Test func replacesLastPlayingPreservingOtherFields() {
        let original = Self.sample()
        let updated = original.with(lastPlaying: "New Artist - New Track")
        #expect(updated.lastPlaying == "New Artist - New Track")
        #expect(updated.id == original.id)
        #expect(updated.title == original.title)
        #expect(updated.description == original.description)
        #expect(updated.dj == original.dj)
        #expect(updated.genre == original.genre)
        #expect(updated.image == original.image)
        #expect(updated.largeimage == original.largeimage)
        #expect(updated.xlimage == original.xlimage)
        #expect(updated.listeners == original.listeners)
        #expect(updated.playlists == original.playlists)
    }

    @Test func derivedTrackParseablePropertiesReflectMergedValue() {
        let original = Self.sample(lastPlaying: "Old - Track")
        let updated = original.with(lastPlaying: "Artist - Title")
        #expect(updated.artist == "Artist")
        #expect(updated.trackName == "Title")
        #expect(updated.rawTrackString == "Artist - Title")
    }
}
