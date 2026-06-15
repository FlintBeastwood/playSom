import Testing
import Foundation
@testable import playSom

@Suite("Channel model")
struct ChannelTests {

    private static func makeChannel(
        playlists: [Channel.Playlist],
        xlimage: String = "https://example.com/xl.png",
        largeimage: String = "https://example.com/large.png",
        listeners: String = "100",
        lastPlaying: String = "Artist - Track"
    ) -> Channel {
        Channel(
            id: "test",
            title: "Test",
            description: "desc",
            dj: "DJ",
            genre: "ambient",
            image: "https://example.com/small.png",
            largeimage: largeimage,
            xlimage: xlimage,
            listeners: listeners,
            lastPlaying: lastPlaying,
            playlists: playlists
        )
    }

    @Test func streamURLPrefersFormatAndQualityMatch() throws {
        let channel = Self.makeChannel(playlists: [
            .init(url: "https://example.com/aac-high.m3u",   format: "aac",  quality: "highest"),
            .init(url: "https://example.com/mp3-high.m3u",   format: "mp3",  quality: "highest"),
            .init(url: "https://example.com/aacp-low.m3u",   format: "aacp", quality: "low")
        ])
        let url = try #require(channel.streamURL(preferredFormat: .aac, preferredQuality: .highest))
        #expect(url.absoluteString == "https://example.com/aac-high.m3u")
    }

    @Test func streamURLFallsBackToQualityWhenFormatMissing() throws {
        let channel = Self.makeChannel(playlists: [
            .init(url: "https://example.com/mp3-high.m3u",   format: "mp3",  quality: "highest"),
            .init(url: "https://example.com/aacp-low.m3u",   format: "aacp", quality: "low")
        ])
        let url = try #require(channel.streamURL(preferredFormat: .aac, preferredQuality: .highest))
        #expect(url.absoluteString == "https://example.com/mp3-high.m3u")
    }

    @Test func streamURLFallsBackToFirstWhenQualityAlsoMissing() throws {
        let channel = Self.makeChannel(playlists: [
            .init(url: "https://example.com/aacp-low.m3u",   format: "aacp", quality: "low"),
            .init(url: "https://example.com/anything.m3u",   format: "mp3",  quality: "high")
        ])
        let url = try #require(channel.streamURL(preferredFormat: .aac, preferredQuality: .highest))
        #expect(url.absoluteString == "https://example.com/aacp-low.m3u")
    }

    @Test func streamURLIsNilForEmptyPlaylists() {
        let channel = Self.makeChannel(playlists: [])
        #expect(channel.streamURL() == nil)
    }

    @Test func listenerCountParsesInt() {
        let channel = Self.makeChannel(playlists: [], listeners: "1264")
        #expect(channel.listenerCount == 1264)
    }

    @Test func listenerCountIsZeroForNonNumericString() {
        let channel = Self.makeChannel(playlists: [], listeners: "not-a-number")
        #expect(channel.listenerCount == 0)
    }

    @Test func artworkURLPrefersXLImageWhenPresent() throws {
        let channel = Self.makeChannel(playlists: [], xlimage: "https://example.com/xl.png", largeimage: "https://example.com/large.png")
        let url = try #require(channel.artworkURL)
        #expect(url.absoluteString == "https://example.com/xl.png")
    }

    @Test func artworkURLFallsBackToLargeImageWhenXLEmpty() throws {
        let channel = Self.makeChannel(playlists: [], xlimage: "", largeimage: "https://example.com/large.png")
        let url = try #require(channel.artworkURL)
        #expect(url.absoluteString == "https://example.com/large.png")
    }

    @Test func rawTrackStringEqualsLastPlaying() {
        let channel = Self.makeChannel(playlists: [], lastPlaying: "Foo - Bar")
        #expect(channel.rawTrackString == "Foo - Bar")
    }

    @Test func codableRoundTrip() throws {
        let original = Self.makeChannel(playlists: [
            .init(url: "https://example.com/a", format: "aac", quality: "highest")
        ])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Channel.self, from: data)
        #expect(decoded == original)
    }
}
