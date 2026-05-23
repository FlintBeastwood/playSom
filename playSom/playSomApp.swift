import SwiftUI
import AppKit

/// The main app entry point. Configures a MenuBarExtra (no dock icon, no window).
@main
struct playSomApp: App {

    @StateObject private var viewModel = RadioViewModel()
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some Scene {
        // Menu bar popover — this is the entire UI
        MenuBarExtra {
            MenuBarView(viewModel: viewModel)
        } label: {
            Label {
                Text("playSom")
            } icon: {
                Image(systemName: viewModel.isPlaying ? "radio.fill" : "radio")
            }
        }
        .menuBarExtraStyle(.window)
        .onChange(of: isDarkMode) { _, dark in
            NSApp.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
        }
    }
}
