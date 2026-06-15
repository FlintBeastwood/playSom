import Testing
import Foundation
@testable import playSom

@MainActor
@Suite("FavoritesService")
struct FavoritesServiceTests {

    private func makeService() -> (FavoritesService, UserDefaults) {
        let suiteName = "test-favorites-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        return (FavoritesService(defaults: defaults), defaults)
    }

    @Test func newServiceHasNoFavorites() {
        let (service, _) = makeService()
        #expect(service.favorites.isEmpty)
    }

    @Test func addFavoriteInsertsNewestFirst() {
        let (service, _) = makeService()
        service.addFavorite(title: "Song A", channelId: "c1", channelTitle: "Chan 1")
        service.addFavorite(title: "Song B", channelId: "c1", channelTitle: "Chan 1")
        #expect(service.favorites.count == 2)
        #expect(service.favorites.first?.title == "Song B")
    }

    @Test func duplicateAddsAreIgnored() {
        let (service, _) = makeService()
        service.addFavorite(title: "Song", channelId: "c1", channelTitle: "Chan 1")
        service.addFavorite(title: "Song", channelId: "c1", channelTitle: "Chan 1")
        #expect(service.favorites.count == 1)
    }

    @Test func sameTitleOnDifferentChannelsAllowed() {
        let (service, _) = makeService()
        service.addFavorite(title: "Song", channelId: "c1", channelTitle: "Chan 1")
        service.addFavorite(title: "Song", channelId: "c2", channelTitle: "Chan 2")
        #expect(service.favorites.count == 2)
    }

    @Test func isFavoriteReturnsTrueForAddedTrack() {
        let (service, _) = makeService()
        service.addFavorite(title: "Song", channelId: "c1", channelTitle: "Chan 1")
        #expect(service.isFavorite(title: "Song", channelId: "c1"))
        #expect(!service.isFavorite(title: "Song", channelId: "c2"))
    }

    @Test func removeByIdRemovesOnlyMatchingEntry() {
        let (service, _) = makeService()
        service.addFavorite(title: "A", channelId: "c1", channelTitle: "Chan 1")
        service.addFavorite(title: "B", channelId: "c1", channelTitle: "Chan 1")
        let target = service.favorites.first { $0.title == "A" }!
        service.removeFavorite(id: target.id)
        #expect(service.favorites.count == 1)
        #expect(service.favorites.first?.title == "B")
    }

    @Test func removeByTitleAndChannel() {
        let (service, _) = makeService()
        service.addFavorite(title: "Song", channelId: "c1", channelTitle: "Chan 1")
        service.removeFavorite(title: "Song", channelId: "c1")
        #expect(service.favorites.isEmpty)
    }

    @Test func toggleFavoriteRoundTrip() {
        let (service, _) = makeService()
        let addedFirst = service.toggleFavorite(title: "S", channelId: "c1", channelTitle: "Chan 1")
        #expect(addedFirst == true)
        let addedSecond = service.toggleFavorite(title: "S", channelId: "c1", channelTitle: "Chan 1")
        #expect(addedSecond == false)
        #expect(service.favorites.isEmpty)
    }

    @Test func clearAllRemovesEverything() {
        let (service, _) = makeService()
        service.addFavorite(title: "A", channelId: "c1", channelTitle: "Chan 1")
        service.addFavorite(title: "B", channelId: "c2", channelTitle: "Chan 2")
        service.clearAll()
        #expect(service.favorites.isEmpty)
    }

    @Test func persistsAndReloadsAcrossInstances() {
        let (first, defaults) = makeService()
        first.addFavorite(title: "Persisted", channelId: "c1", channelTitle: "Chan 1")
        let second = FavoritesService(defaults: defaults)
        #expect(second.favorites.count == 1)
        #expect(second.favorites.first?.title == "Persisted")
    }
}
