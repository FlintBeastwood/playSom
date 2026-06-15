import Testing
import Foundation
@testable import playSom

@Suite("PinnedChannel")
struct PinnedChannelTests {

    @Test func codableRoundTrip() throws {
        let original = PinnedChannel(id: "groovesalad", pinnedAt: Date(timeIntervalSince1970: 1_700_000_000))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PinnedChannel.self, from: data)
        #expect(decoded == original)
    }

    @Test func identifiableIdMatchesId() {
        let pinned = PinnedChannel(id: "dronezone", pinnedAt: Date())
        #expect(pinned.id == "dronezone")
    }

    @Test func hashableEqualityUsesAllFields() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let a = PinnedChannel(id: "x", pinnedAt: date)
        let b = PinnedChannel(id: "x", pinnedAt: date)
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
    }
}
