import Testing
import Foundation
@testable import playSom

private struct TestTrack: TrackParseable {
    let rawTrackString: String
}

@Suite("TrackParseable")
struct TrackParseableTests {

    @Test func splitsArtistAndTrack() {
        let t = TestTrack(rawTrackString: "Groovecatcher - What The Croupier Saw")
        #expect(t.artist == "Groovecatcher")
        #expect(t.trackName == "What The Croupier Saw")
    }

    @Test func rejoinsWhenTitleContainsSeparator() {
        let t = TestTrack(rawTrackString: "Artist - Some - Long - Title")
        #expect(t.artist == "Artist")
        #expect(t.trackName == "Some - Long - Title")
    }

    @Test func returnsRawWhenNoSeparator() {
        let t = TestTrack(rawTrackString: "Just A Title")
        #expect(t.artist == "Just A Title")
        #expect(t.trackName == "Just A Title")
    }

    @Test func handlesEmptyString() {
        let t = TestTrack(rawTrackString: "")
        #expect(t.artist == "")
        #expect(t.trackName == "")
    }

    @Test func trimsWhitespaceAroundParts() {
        let t = TestTrack(rawTrackString: "  Artist  -  Track  ")
        #expect(t.artist == "Artist")
        #expect(t.trackName == "Track")
    }

    @Test func bandcampURLEncodesQuery() throws {
        let t = TestTrack(rawTrackString: "Artist Name - Track Name")
        let url = try #require(t.bandcampSearchURL)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.host == "bandcamp.com")
        #expect(components.path == "/search")
        let q = components.queryItems?.first(where: { $0.name == "q" })?.value
        #expect(q == "Artist Name+Track Name")
    }

    @Test func bandcampURLIsNilForEmptyString() {
        let t = TestTrack(rawTrackString: "")
        #expect(t.bandcampSearchURL == nil)
    }
}
