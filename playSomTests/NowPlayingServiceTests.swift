import Testing
import MediaPlayer
@testable import playSom

@MainActor
@Suite("NowPlayingService.updateTrackTitle")
struct NowPlayingServiceTests {

    @Test func updateTrackTitleSetsTitleField() {
        let service = NowPlayingService()
        let channel = Channel(
            id: "c", title: "Chan", description: "D", dj: "", genre: "",
            image: "", largeimage: "", xlimage: "",
            listeners: "0", lastPlaying: "Old", playlists: []
        )
        service.update(channel: channel)

        service.updateTrackTitle("New Artist - New Track")
        let title = MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyTitle] as? String
        #expect(title == "New Artist - New Track")
    }

    @Test func updateTrackTitlePreservesOtherFields() {
        let service = NowPlayingService()
        let channel = Channel(
            id: "c", title: "Chan", description: "Description", dj: "", genre: "",
            image: "", largeimage: "", xlimage: "",
            listeners: "0", lastPlaying: "Old", playlists: []
        )
        service.update(channel: channel)
        service.updateTrackTitle("New Track")
        let info = MPNowPlayingInfoCenter.default().nowPlayingInfo
        #expect(info?[MPMediaItemPropertyArtist] as? String == "Chan")
        #expect(info?[MPMediaItemPropertyAlbumTitle] as? String == "Description")
    }

    @Test func updateTrackTitleWhenInfoNilCreatesDict() {
        let service = NowPlayingService()
        service.clear()
        service.updateTrackTitle("First Track")
        let title = MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyTitle] as? String
        #expect(title == "First Track")
    }
}
