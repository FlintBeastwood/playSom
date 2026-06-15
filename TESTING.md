# Testing

playSom uses the [Swift Testing](https://developer.apple.com/xcode/swift-testing/) framework (the modern successor to XCTest, available from Xcode 16). Tests live in `playSomTests/` and currently cover 81 tests across 16 suites — model parsing, services, view-model behavior, image cache eviction, ICY metadata merging, popover sizing, and view-tree lookup helpers.

## Running tests

### In Xcode

Open `playSom.xcodeproj` and press `⌘U`.

### From the command line

```bash
xcodebuild test \
  -project playSom.xcodeproj \
  -scheme playSom \
  -destination 'platform=macOS'
```

Add `-quiet` for less verbose output, or pipe through `xcbeautify` / `xcpretty` for prettier formatting.

## Writing tests

Tests are written with Swift Testing macros (`@Suite`, `@Test`, `#expect`, `#require`), not XCTest. Example:

```swift
import Testing
@testable import playSom

@Suite("PinnedChannelsService")
struct PinnedChannelsServiceTests {
    @Test func pinAddsToSet() {
        let service = PinnedChannelsService(defaults: .ephemeral())
        service.pin(id: "groovesalad")
        #expect(service.isPinned(id: "groovesalad"))
    }
}
```

Services that persist state (`FavoritesService`, `PinnedChannelsService`) accept an injectable `UserDefaults` so tests can use an ephemeral, isolated store and run in parallel without polluting each other.
