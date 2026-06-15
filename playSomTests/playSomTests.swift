import Testing
@testable import playSom

@Suite("playSom baseline coverage")
struct BaselineSuite {
    @Test func sanity() {
        #expect(true)
    }
}
