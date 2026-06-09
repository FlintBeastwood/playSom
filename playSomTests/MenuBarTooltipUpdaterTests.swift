import Testing
import AppKit
@testable import playSom

@MainActor
@Suite("MenuBarTooltipUpdater — view tree search")
struct MenuBarTooltipUpdaterViewSearchTests {

    @Test func findsDirectChildOfRequestedType() {
        let parent = NSView()
        let button = NSStatusBarButton()
        parent.addSubview(button)
        let found = parent.firstSubview(ofType: NSStatusBarButton.self)
        #expect(found === button)
    }

    @Test func findsNestedDescendant() {
        let outer = NSView()
        let middle = NSView()
        let inner = NSStatusBarButton()
        outer.addSubview(middle)
        middle.addSubview(inner)
        let found = outer.firstSubview(ofType: NSStatusBarButton.self)
        #expect(found === inner)
    }

    @Test func returnsNilWhenNoMatch() {
        let parent = NSView()
        parent.addSubview(NSView())
        parent.addSubview(NSTextField())
        let found = parent.firstSubview(ofType: NSStatusBarButton.self)
        #expect(found == nil)
    }

    @Test func returnsFirstMatchInDepthFirstOrder() {
        let parent = NSView()
        let firstNested = NSView()
        let firstButton = NSStatusBarButton()
        firstNested.addSubview(firstButton)
        let secondButton = NSStatusBarButton()
        parent.addSubview(firstNested)
        parent.addSubview(secondButton)
        let found = parent.firstSubview(ofType: NSStatusBarButton.self)
        #expect(found === firstButton)
    }
}
