import SwiftUI

/// Scrolls text horizontally in a seamless loop when it's wider than its container.
/// Uses TimelineView for animation — completely stops rendering when not visible.
/// Inherits foregroundStyle from the environment.
struct MarqueeText: View {

    let text: String
    let font: Font
    var speed: Double = 38   // points per second
    var delay: Double = 1.2  // pause before starting
    let isVisible: Bool

    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var startDate: Date?

    private let gap: CGFloat = 48

    private var needsMarquee: Bool {
        textWidth > 0 && containerWidth > 0 && textWidth > containerWidth
    }

    private var shouldAnimate: Bool {
        isVisible && needsMarquee
    }

    var body: some View {
        GeometryReader { proxy in
            let available = proxy.size.width

            // TimelineView with `paused: true` stops the render loop completely — zero CPU
            TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !shouldAnimate)) { context in
                ZStack(alignment: .leading) {
                    if needsMarquee {
                        let totalScroll = textWidth + gap
                        let duration = totalScroll / speed
                        let elapsed = startDate.map { context.date.timeIntervalSince($0) - delay } ?? -1
                        let progress = elapsed > 0 ? elapsed.truncatingRemainder(dividingBy: duration) / duration : 0
                        let currentOffset = -CGFloat(progress) * totalScroll

                        HStack(spacing: gap) {
                            Text(text).font(font).lineLimit(1).fixedSize()
                            Text(text).font(font).lineLimit(1).fixedSize()
                        }
                        .offset(x: currentOffset)
                    } else {
                        Text(text).font(font).lineLimit(1)
                            .frame(width: available, alignment: .leading)
                    }
                }
                .frame(width: available, alignment: .leading)
                .clipped()
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: .black, location: needsMarquee ? 0.05 : 0.0),
                            .init(color: .black, location: needsMarquee ? 0.95 : 1.0),
                            .init(color: .clear, location: 1.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }
            // Measure text width via a hidden overlay
            .background(
                Text(text).font(font).lineLimit(1).fixedSize()
                    .hidden()
                    .overlay(GeometryReader { textGeo in
                        Color.clear.onAppear {
                            textWidth = textGeo.size.width
                            containerWidth = available
                            if shouldAnimate { startDate = Date() }
                        }
                    })
            )
            .onChange(of: available) { _, w in
                containerWidth = w
            }
            .onChange(of: text) { _, _ in
                textWidth = 0
                startDate = nil
            }
            .onChange(of: shouldAnimate) { _, animating in
                startDate = animating ? Date() : nil
            }
        }
        // Height matches a single line of the chosen font — no GeometryReader height collapse
        .frame(height: lineHeight)
    }

    // MARK: - Helpers

    private var lineHeight: CGFloat {
        switch font {
        case .caption2: return 14
        case .caption:  return 16
        default:        return 18
        }
    }
}
