import Testing
import Foundation
@testable import playSom

@MainActor
@Suite("RadioViewModel.displayedChannels")
struct DisplayedChannelsTests {

    private func makeChannel(id: String, title: String, listeners: String) -> Channel {
        Channel(id: id, title: title, description: "", dj: "", genre: "",
                image: "", largeimage: "", xlimage: "",
                listeners: listeners, lastPlaying: "", playlists: [])
    }

    /// Each test gets a fresh `PinnedChannelsService` backed by a UUID-isolated
    /// UserDefaults suite so concurrent tests don't pollute `.standard`.
    private func makeViewModel(channels: [Channel]) -> RadioViewModel {
        let suite = UserDefaults(suiteName: "test-displayed-\(UUID().uuidString)")!
        let vm = RadioViewModel(pinnedService: PinnedChannelsService(defaults: suite))
        vm.channels = channels
        return vm
    }

    @Test func noPinsPreservesListenerOrder() {
        let vm = makeViewModel(channels: [
            makeChannel(id: "a", title: "A", listeners: "100"),
            makeChannel(id: "b", title: "B", listeners: "50"),
            makeChannel(id: "c", title: "C", listeners: "25")
        ])
        #expect(vm.displayedChannels.map(\.id) == ["a", "b", "c"])
    }

    @Test func pinnedChannelsAppearFirst() {
        let vm = makeViewModel(channels: [
            makeChannel(id: "a", title: "A", listeners: "100"),
            makeChannel(id: "b", title: "B", listeners: "50"),
            makeChannel(id: "c", title: "C", listeners: "25")
        ])
        vm.pinnedService.pin(id: "c")
        #expect(vm.displayedChannels.map(\.id) == ["c", "a", "b"])
    }

    @Test func multiplePinsPreserveListenerOrderWithinPinnedGroup() {
        let vm = makeViewModel(channels: [
            makeChannel(id: "a", title: "A", listeners: "100"),
            makeChannel(id: "b", title: "B", listeners: "50"),
            makeChannel(id: "c", title: "C", listeners: "25")
        ])
        vm.pinnedService.pin(id: "b")
        vm.pinnedService.pin(id: "c")
        #expect(vm.displayedChannels.map(\.id) == ["b", "c", "a"])
    }

    @Test func searchAppliesAcrossPinnedAndUnpinned() {
        let vm = makeViewModel(channels: [
            makeChannel(id: "groovesalad", title: "Groove Salad", listeners: "100"),
            makeChannel(id: "dronezone",   title: "Drone Zone",   listeners: "50")
        ])
        vm.pinnedService.pin(id: "dronezone")
        vm.searchText = "drone"
        #expect(vm.displayedChannels.map(\.id) == ["dronezone"])
    }

    @Test func searchHidingPinnedStillSurfacesMatchingUnpinned() {
        let vm = makeViewModel(channels: [
            makeChannel(id: "groovesalad", title: "Groove Salad", listeners: "100"),
            makeChannel(id: "dronezone",   title: "Drone Zone",   listeners: "50")
        ])
        vm.pinnedService.pin(id: "dronezone")
        vm.searchText = "groove"
        #expect(vm.displayedChannels.map(\.id) == ["groovesalad"])
    }

    @Test func orphanPinNotInChannelsIsSilentlyDropped() {
        let vm = makeViewModel(channels: [
            makeChannel(id: "a", title: "A", listeners: "100")
        ])
        vm.pinnedService.pin(id: "ghost")
        #expect(vm.displayedChannels.map(\.id) == ["a"])
        #expect(vm.pinnedService.isPinned(id: "ghost"))
    }

    @Test func allPinnedYieldsAllInPinnedGroup() {
        let vm = makeViewModel(channels: [
            makeChannel(id: "a", title: "A", listeners: "100"),
            makeChannel(id: "b", title: "B", listeners: "50")
        ])
        vm.pinnedService.pin(id: "a")
        vm.pinnedService.pin(id: "b")
        #expect(vm.displayedChannels.map(\.id) == ["a", "b"])
    }
}
