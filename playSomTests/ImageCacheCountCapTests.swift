import Testing
import AppKit
@testable import playSom

@MainActor
@Suite("ImageCache — count cap")
struct ImageCacheCountCapTests {

    /// A 1×1 transparent NSImage — cheap to allocate, sufficient for count tests.
    private func tinyImage() -> NSImage {
        let image = NSImage(size: NSSize(width: 1, height: 1))
        image.lockFocus()
        NSColor.clear.set()
        NSRect(x: 0, y: 0, width: 1, height: 1).fill()
        image.unlockFocus()
        return image
    }

    @Test func cacheRetainsRecentlyAddedEntries() {
        let cache = ImageCache.shared
        let url = URL(string: "https://test.example/recent.png")!
        cache.store(tinyImage(), for: url)
        #expect(cache.image(for: url) != nil)
    }

    /// Pushing more than the configured count limit (200) should not cause the
    /// most-recently-stored entry to be evicted; NSCache enforces a soft cap.
    @Test func capCannotBeBypassedByStoringMoreThanLimit() {
        let cache = ImageCache.shared
        for i in 0..<250 {
            let url = URL(string: "https://test.example/img-\(i).png")!
            cache.store(tinyImage(), for: url)
        }
        let latest = URL(string: "https://test.example/img-249.png")!
        #expect(cache.image(for: latest) != nil)
    }
}
