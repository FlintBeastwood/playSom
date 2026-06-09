import Testing
@testable import playSom

@MainActor
@Suite("RadioViewModel.filteredChannels")
struct RadioViewModelFilterTests {

    private func makeViewModelWithChannels() -> RadioViewModel {
        let vm = RadioViewModel()
        vm.channels = [
            Channel(id: "groovesalad", title: "Groove Salad", description: "Ambient downtempo", dj: "Rusty Hodge",
                    genre: "ambient|electronic", image: "", largeimage: "", xlimage: "",
                    listeners: "1000", lastPlaying: "", playlists: []),
            Channel(id: "dronezone", title: "Drone Zone", description: "Atmospheric textures", dj: "Rusty Hodge",
                    genre: "ambient", image: "", largeimage: "", xlimage: "",
                    listeners: "500", lastPlaying: "", playlists: []),
            Channel(id: "indiepop", title: "Indie Pop Rocks!", description: "Indie pop tracks", dj: "Elise",
                    genre: "alternative|rock", image: "", largeimage: "", xlimage: "",
                    listeners: "200", lastPlaying: "", playlists: [])
        ]
        return vm
    }

    @Test func emptySearchReturnsAllChannels() {
        let vm = makeViewModelWithChannels()
        vm.searchText = ""
        #expect(vm.filteredChannels.count == 3)
    }

    @Test func searchByTitleIsCaseInsensitive() {
        let vm = makeViewModelWithChannels()
        vm.searchText = "drone"
        #expect(vm.filteredChannels.map(\.id) == ["dronezone"])
    }

    @Test func searchByGenre() {
        let vm = makeViewModelWithChannels()
        vm.searchText = "electronic"
        #expect(vm.filteredChannels.map(\.id) == ["groovesalad"])
    }

    @Test func searchByDescription() {
        let vm = makeViewModelWithChannels()
        vm.searchText = "textures"
        #expect(vm.filteredChannels.map(\.id) == ["dronezone"])
    }

    @Test func searchByDJ() {
        let vm = makeViewModelWithChannels()
        vm.searchText = "elise"
        #expect(vm.filteredChannels.map(\.id) == ["indiepop"])
    }

    @Test func searchWithNoMatchesReturnsEmpty() {
        let vm = makeViewModelWithChannels()
        vm.searchText = "nonexistent-query"
        #expect(vm.filteredChannels.isEmpty)
    }
}
