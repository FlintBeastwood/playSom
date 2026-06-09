import AppKit
import Combine
import Foundation

/// Locates the SwiftUI `MenuBarExtra`'s status-bar button and keeps its
/// `toolTip` in sync with current playback state.
///
/// `MenuBarExtra` doesn't expose its underlying `NSStatusItem`, so we discover
/// the button by walking `NSApp.windows` for a `NSStatusBarWindow` instance and
/// descending its view tree. The reference is cached for the app's lifetime.
@MainActor
final class MenuBarTooltipUpdater: NSObject {

    private weak var statusButton: NSStatusBarButton?
    private var cancellables = Set<AnyCancellable>()
    private var lookupAttempts = 0

    func start(viewModel: RadioViewModel) {
        attemptLookupAndSubscribe(viewModel: viewModel)
    }

    private func attemptLookupAndSubscribe(viewModel: RadioViewModel) {
        locateStatusButton()
        if statusButton == nil && lookupAttempts < 2 {
            lookupAttempts += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self, weak viewModel] in
                guard let self, let viewModel else { return }
                self.attemptLookupAndSubscribe(viewModel: viewModel)
            }
            return
        }
        guard statusButton != nil else {
            print("[MenuBarTooltipUpdater] could not locate NSStatusBarButton; tooltip disabled")
            return
        }
        subscribe(to: viewModel)
    }

    private func locateStatusButton() {
        for window in NSApp.windows {
            let className = String(describing: type(of: window))
            guard className == "NSStatusBarWindow" else { continue }
            if let button = window.contentView?.firstSubview(ofType: NSStatusBarButton.self) {
                statusButton = button
                return
            }
        }
    }

    private func subscribe(to viewModel: RadioViewModel) {
        // currentChannel.lastPlaying already carries the live ICY track once it
        // arrives (see RadioViewModel's liveTrack sink), so we only watch
        // currentChannel and isPlaying here.
        Publishers.CombineLatest(viewModel.$currentChannel, viewModel.$isPlaying)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] channel, isPlaying in
                self?.updateTooltip(channel: channel, isPlaying: isPlaying)
            }
            .store(in: &cancellables)
    }

    private func updateTooltip(channel: Channel?, isPlaying: Bool) {
        guard let button = statusButton else { return }
        let lines: [String]
        if let channel, isPlaying {
            let track = channel.lastPlaying.isEmpty ? "No data" : channel.lastPlaying
            lines = [channel.title, track]
        } else {
            lines = ["playSom", "not playing"]
        }
        button.toolTip = lines.joined(separator: "\n")
    }
}

// MARK: - NSView helper

extension NSView {
    /// Recursive depth-first search for the first subview of the given type.
    func firstSubview<T: NSView>(ofType type: T.Type) -> T? {
        for subview in subviews {
            if let match = subview as? T { return match }
            if let nested = subview.firstSubview(ofType: type) { return nested }
        }
        return nil
    }
}
