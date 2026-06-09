import Testing
@testable import playSom

@MainActor
@Suite("RadioViewModel lifecycle")
struct RadioViewModelLifecycleTests {

    @Test func setupBindingsInstalledOnce() {
        let vm = RadioViewModel()
        // setupBindings runs in init. Cancellable count should be a small,
        // bounded number — exactly the number of sinks we set up there.
        // Current shape: favoritesService.objectWillChange sink. (Phase 2 adds
        // more; this test pins the current baseline as a regression marker.)
        let initial = vm.debug_cancellableCount
        #expect(initial >= 1)
        #expect(initial <= 4)
    }

    @Test func startStopPeriodicRefreshIsIdempotent() {
        let vm = RadioViewModel()
        #expect(vm.debug_isRefreshTimerScheduled == false)
        vm.startPeriodicRefresh()
        #expect(vm.debug_isRefreshTimerScheduled == true)
        vm.startPeriodicRefresh()  // calling twice replaces, doesn't stack
        #expect(vm.debug_isRefreshTimerScheduled == true)
        vm.stopPeriodicRefresh()
        #expect(vm.debug_isRefreshTimerScheduled == false)
        vm.stopPeriodicRefresh()  // safe to call when already stopped
        #expect(vm.debug_isRefreshTimerScheduled == false)
    }

    @Test func channelAssignmentReplacesArrayNotAppends() {
        let vm = RadioViewModel()
        let first: [Channel] = [
            Channel(id: "a", title: "A", description: "", dj: "", genre: "",
                    image: "", largeimage: "", xlimage: "", listeners: "1",
                    lastPlaying: "", playlists: [])
        ]
        let second: [Channel] = [
            Channel(id: "b", title: "B", description: "", dj: "", genre: "",
                    image: "", largeimage: "", xlimage: "", listeners: "1",
                    lastPlaying: "", playlists: []),
            Channel(id: "c", title: "C", description: "", dj: "", genre: "",
                    image: "", largeimage: "", xlimage: "", listeners: "1",
                    lastPlaying: "", playlists: [])
        ]
        vm.channels = first
        #expect(vm.channels.count == 1)
        vm.channels = second
        #expect(vm.channels.count == 2)
        #expect(vm.channels.map(\.id) == ["b", "c"])
    }
}
