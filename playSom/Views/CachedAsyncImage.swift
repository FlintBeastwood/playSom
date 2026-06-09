import SwiftUI
import AppKit

// MARK: - Image Cache

/// A simple in-memory image cache backed by NSCache.
/// Images are loaded once and reused on every subsequent scroll — no re-fetching.
final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSURL, NSImage>()

    /// Approximate per-entry memory cost in bytes, used to drive eviction.
    /// Computed as width × height × 4 (RGBA) — a representative byte count for
    /// decoded bitmap storage held by `NSImage`.
    private static func cost(of image: NSImage) -> Int {
        let size = image.size
        return Int(size.width) * Int(size.height) * 4
    }

    private init() {
        cache.countLimit = 200
        cache.totalCostLimit = 50 * 1024 * 1024   // 50 MB
    }

    var totalCostLimit: Int { cache.totalCostLimit }

    func image(for url: URL) -> NSImage? {
        cache.object(forKey: url as NSURL)
    }

    func store(_ image: NSImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL, cost: Self.cost(of: image))
    }
}

// MARK: - CachedAsyncImage

/// Drop-in replacement for AsyncImage that caches loaded images in memory.
/// Once loaded, the image is shown instantly without any network request on scroll.
struct CachedAsyncImage<Content: View, Placeholder: View>: View {

    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder

    @State private var nsImage: NSImage?
    @State private var isLoading = false

    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let nsImage {
                content(Image(nsImage: nsImage))
            } else {
                placeholder()
            }
        }
        // Key on url — restarts automatically whenever the channel changes
        .task(id: url) {
            nsImage = nil        // clear old image first so the placeholder shows during load
            await load()
        }
    }

    private func load() async {
        guard let url, !isLoading else { return }

        // Return immediately if already cached
        if let cached = ImageCache.shared.image(for: url) {
            nsImage = cached
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = NSImage(data: data) {
                ImageCache.shared.store(image, for: url)
                nsImage = image
            }
        } catch {
            // Silently fail — placeholder stays visible
        }
    }
}
