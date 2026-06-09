import Testing
import CoreGraphics
@testable import playSom

@Suite("Popover height formula")
struct PopoverHeightTests {

    @Test(arguments: [
        (pinned: 0, channels: 30, expectedRows: 5),
        (pinned: 1, channels: 30, expectedRows: 5),
        (pinned: 3, channels: 30, expectedRows: 5),
        (pinned: 4, channels: 30, expectedRows: 6),
        (pinned: 5, channels: 30, expectedRows: 7),
        (pinned: 7, channels: 30, expectedRows: 9),
        (pinned: 8, channels: 30, expectedRows: 10),
        (pinned: 11, channels: 30, expectedRows: 10),
        (pinned: 30, channels: 30, expectedRows: 10)
    ])
    func visibleRowsFollowsFormula(pinned: Int, channels: Int, expectedRows: Int) {
        #expect(MenuBarView.visibleRows(pinned: pinned) == expectedRows)
    }

    @Test func baseHeightWithoutPinsMatchesOriginal() {
        let h = MenuBarView.popoverHeight(pinned: 0, totalChannels: 30)
        #expect(h == 520)
    }

    @Test func heightGrowsWhenMoreThan3Pinned() {
        let zero = MenuBarView.popoverHeight(pinned: 0, totalChannels: 30)
        let four = MenuBarView.popoverHeight(pinned: 4, totalChannels: 30)
        #expect(four > zero)
    }

    @Test func heightStopsGrowingAt8OrMorePinned() {
        let eight = MenuBarView.popoverHeight(pinned: 8, totalChannels: 30)
        let twelve = MenuBarView.popoverHeight(pinned: 12, totalChannels: 30)
        #expect(eight == twelve)
    }

    @Test func sectionLabelHeightAppliesOnlyWhenBothGroupsNonEmpty() {
        let allPinned = MenuBarView.popoverHeight(pinned: 5, totalChannels: 5)   // no unpinned
        let somePinned = MenuBarView.popoverHeight(pinned: 5, totalChannels: 30) // some unpinned
        #expect(somePinned > allPinned)
        #expect(somePinned - allPinned == 22)
    }
}
