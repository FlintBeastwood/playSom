import Testing
import Foundation
@testable import playSom

@MainActor
@Suite("PinnedChannelsService")
struct PinnedChannelsServiceTests {

    private func makeService() -> (PinnedChannelsService, UserDefaults) {
        let defaults = UserDefaults(suiteName: "test-pinned-\(UUID().uuidString)")!
        return (PinnedChannelsService(defaults: defaults), defaults)
    }

    @Test func newServiceHasNoPins() {
        let (service, _) = makeService()
        #expect(service.pinnedIds.isEmpty)
    }

    @Test func pinAddsToSet() {
        let (service, _) = makeService()
        service.pin(id: "groovesalad")
        #expect(service.pinnedIds.contains("groovesalad"))
    }

    @Test func pinIsIdempotent() {
        let (service, _) = makeService()
        service.pin(id: "groovesalad")
        service.pin(id: "groovesalad")
        #expect(service.pinnedIds.count == 1)
    }

    @Test func unpinRemovesFromSet() {
        let (service, _) = makeService()
        service.pin(id: "groovesalad")
        service.unpin(id: "groovesalad")
        #expect(service.pinnedIds.isEmpty)
    }

    @Test func unpinOfUnpinnedIsSafe() {
        let (service, _) = makeService()
        service.unpin(id: "nonexistent")
        #expect(service.pinnedIds.isEmpty)
    }

    @Test func togglePinReturnsTrueWhenAddedFalseWhenRemoved() {
        let (service, _) = makeService()
        let firstResult = service.togglePin(id: "x")
        #expect(firstResult == true)
        let secondResult = service.togglePin(id: "x")
        #expect(secondResult == false)
        #expect(service.pinnedIds.isEmpty)
    }

    @Test func clearAllRemovesEverything() {
        let (service, _) = makeService()
        service.pin(id: "a")
        service.pin(id: "b")
        service.clearAll()
        #expect(service.pinnedIds.isEmpty)
    }

    @Test func persistsAcrossInstances() {
        let (first, defaults) = makeService()
        first.pin(id: "persisted")
        let second = PinnedChannelsService(defaults: defaults)
        #expect(second.pinnedIds.contains("persisted"))
    }

    @Test func isPinnedReflectsState() {
        let (service, _) = makeService()
        #expect(!service.isPinned(id: "x"))
        service.pin(id: "x")
        #expect(service.isPinned(id: "x"))
        service.unpin(id: "x")
        #expect(!service.isPinned(id: "x"))
    }
}
