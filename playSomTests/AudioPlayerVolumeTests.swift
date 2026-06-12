import Testing
import Foundation
@testable import playSom

@MainActor
@Suite("AudioPlayer volume persistence")
struct AudioPlayerVolumeTests {

    private func makePlayer() -> (AudioPlayer, UserDefaults) {
        let defaults = UserDefaults(suiteName: "test-volume-\(UUID().uuidString)")!
        return (AudioPlayer(defaults: defaults), defaults)
    }

    @Test func newPlayerDefaultsTo075() {
        let (player, _) = makePlayer()
        #expect(player.volume == 0.75)
    }

    @Test func volumePersistsAcrossInstances() {
        let (player, defaults) = makePlayer()
        player.volume = 0.3
        let restored = AudioPlayer(defaults: defaults)
        #expect(restored.volume == 0.3)
    }

    @Test func mutedVolumePersistsAndIsNotResetToDefault() {
        let (player, defaults) = makePlayer()
        player.volume = 0.0
        let restored = AudioPlayer(defaults: defaults)
        #expect(restored.volume == 0.0)
    }

    @Test func maxVolumePersists() {
        let (player, defaults) = makePlayer()
        player.volume = 1.0
        let restored = AudioPlayer(defaults: defaults)
        #expect(restored.volume == 1.0)
    }
}
