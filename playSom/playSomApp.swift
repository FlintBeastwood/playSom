import SwiftUI
import AppKit

/// The main app entry point. Configures a MenuBarExtra (no dock icon, no window).
@main
struct playSomApp: App {

    @StateObject private var viewModel = RadioViewModel()
    @State private var tooltipUpdater = MenuBarTooltipUpdater()
    @AppStorage("isDarkMode") private var isDarkMode = false

    /// Builds the menu bar glyph as a hand-drawn template image.
    ///
    /// The `radio` SF Symbol packs fine internal detail (a dot speaker-grille and
    /// dial) that cannot resolve at ~18px on a 1x (non-Retina) display, so it
    /// renders as blurry gray mush there while staying crisp on 2x Retina. This
    /// draws a bold filled radio silhouette with cut-out details instead — bold
    /// shapes resolve cleanly at 1x. The image is built with a drawing handler so
    /// AppKit re-renders it per display scale (crisp at both 1x and 2x), and is
    /// marked `isTemplate` so macOS tints it for light/dark/highlighted bars.
    static func menuBarIcon(isPlaying: Bool) -> NSImage {
        let size = NSSize(width: 18, height: 16)
        let image = NSImage(size: size, flipped: false) { _ in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            drawRadioGlyph(ctx, playing: isPlaying)
            return true
        }
        image.isTemplate = true
        return image
    }

    /// Draws the radio silhouette into `ctx` in an 18x16 point coordinate space
    /// (origin bottom-left). Layout: antenna up-right, three grille lines on the
    /// left, speaker circle on the right. Body is filled; the grille and speaker
    /// are cleared cut-outs. When playing, the speaker shows a filled center;
    /// when idle it is a hollow ring.
    private static func drawRadioGlyph(_ ctx: CGContext, playing: Bool) {
        ctx.setFillColor(NSColor.black.cgColor)

        // Antenna: long bold diagonal from the body top-left up to the upper-right.
        ctx.saveGState()
        ctx.setStrokeColor(NSColor.black.cgColor)
        ctx.setLineWidth(1.6)
        ctx.setLineCap(.round)
        ctx.move(to: CGPoint(x: 2.6, y: 11.0))
        ctx.addLine(to: CGPoint(x: 16.2, y: 15.6))
        ctx.strokePath()
        ctx.restoreGState()

        // Body: filled rounded rectangle.
        let body = CGRect(x: 1.5, y: 1.0, width: 15.0, height: 10.5)
        ctx.addPath(CGPath(roundedRect: body, cornerWidth: 2.0, cornerHeight: 2.0, transform: nil))
        ctx.fillPath()

        // Grille lines on the left (cleared cut-outs), pixel-row aligned at 1x.
        ctx.setBlendMode(.clear)
        for y in [CGFloat(7), 5, 3] {
            ctx.addRect(CGRect(x: 3.0, y: y, width: 5.0, height: 1.0))
        }
        ctx.fillPath()

        // Speaker (right): clear the disc, redraw a black ring, then clear/keep centre.
        let spk = CGPoint(x: 12.0, y: 5.4)
        let outerR: CGFloat = 3.0
        ctx.setBlendMode(.clear)
        ctx.addArc(center: spk, radius: outerR, startAngle: 0, endAngle: .pi * 2, clockwise: false)
        ctx.fillPath()
        ctx.setBlendMode(.normal)
        ctx.setFillColor(NSColor.black.cgColor)
        ctx.addArc(center: spk, radius: outerR - 1.3, startAngle: 0, endAngle: .pi * 2, clockwise: false)
        ctx.fillPath()
        ctx.setBlendMode(.clear)
        let innerHoleR: CGFloat = playing ? (outerR - 2.5) : (outerR - 1.3)
        if innerHoleR > 0 {
            ctx.addArc(center: spk, radius: innerHoleR, startAngle: 0, endAngle: .pi * 2, clockwise: false)
            ctx.fillPath()
        }
        ctx.setBlendMode(.normal)
    }

    var body: some Scene {
        // Menu bar popover — this is the entire UI
        MenuBarExtra {
            MenuBarView(viewModel: viewModel)
                .task {
                    await Task.yield()
                    tooltipUpdater.start(viewModel: viewModel)
                }
        } label: {
            Image(nsImage: Self.menuBarIcon(isPlaying: viewModel.isPlaying))
                .accessibilityLabel("playSom")
        }
        .menuBarExtraStyle(.window)
        .onChange(of: isDarkMode) { _, dark in
            NSApp.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
        }
    }
}
