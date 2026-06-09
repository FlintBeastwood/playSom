import Testing
import AppKit
@testable import playSom

@MainActor
@Suite("ImageCache — byte cap")
struct ImageCacheByteCapTests {

    /// Builds an opaque NSImage of the given pixel dimensions. The bitmap is
    /// retained by the NSImage so memory cost is proportional to W * H.
    private func image(width: Int, height: Int) -> NSImage {
        let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: width,
            pixelsHigh: height,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: width * 4,
            bitsPerPixel: 32
        )!
        let image = NSImage(size: NSSize(width: width, height: height))
        image.addRepresentation(bitmap)
        return image
    }

    @Test func totalCostLimitIsConfigured() {
        let cache = ImageCache.shared
        let exposed = cache.totalCostLimit
        #expect(exposed > 0, "ImageCache.totalCostLimit must be set to bound memory usage")
        #expect(exposed <= 64 * 1024 * 1024, "totalCostLimit should be modest (≤ 64 MB) for a menubar app")
    }

    @Test func storeAcceptsCostAndDoesNotCrash() {
        let cache = ImageCache.shared
        let url = URL(string: "https://test.example/large.png")!
        cache.store(image(width: 512, height: 512), for: url)
        _ = cache.image(for: url)
    }
}
