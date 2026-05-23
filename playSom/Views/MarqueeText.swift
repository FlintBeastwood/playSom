import SwiftUI

/// Scrolls text horizontally in a seamless loop when it's wider than its container.
/// Does NOT use .frame(maxWidth: .infinity) — the parent controls the width via .frame or layout.
/// Inherits foregroundStyle from the environment.
struct MarqueeText: View {

    let text: String
    let font: Font
    var speed: Double = 38   // points per second
    var delay: Double = 1.2  // pause before starting
    let isVisible: Bool

    @State private var offset: CGFloat = 0
    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var isScrolling = false

    private let gap: CGFloat = 48

    private var needsMarquee: Bool {
        textWidth > 0 && containerWidth > 0 && textWidth > containerWidth
    }

    var body: some View {
        // GeometryReader gives us the width that the PARENT assigns to this view.
        // The parent (HStack) decides how wide we are — we just measure and scroll within it.
        GeometryReader { proxy in
            let available = proxy.size.width

            ZStack(alignment: .leading) {
                if needsMarquee {
                    // Two copies side-by-side for a seamless loop
                    HStack(spacing: gap) {
                        Text(text).font(font).lineLimit(1).fixedSize()
                        Text(text).font(font).lineLimit(1).fixedSize()
                    }
                    .offset(x: offset)
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
            // Measure text width via a hidden overlay
            .background(
                Text(text).font(font).lineLimit(1).fixedSize()
                    .hidden()
                    .overlay(GeometryReader { textGeo in
                        Color.clear.onAppear {
                            textWidth = textGeo.size.width
                            containerWidth = available
                            maybeStart()
                        }
                    })
            )
            .onChange(of: available) { _, w in
                containerWidth = w
                maybeStart()
            }
            .onChange(of: text) { _, _ in
                reset()
            }
            .onChange(of: isVisible) { _, visible in
                if visible {
                    maybeStart()
                } else {
                    reset()
                }
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

    private func maybeStart() {
        guard isVisible, needsMarquee, !isScrolling else { return }
        isScrolling = true
        let duration = Double(textWidth + gap) / speed
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard isVisible, isScrolling else { return }
            withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                offset = -(textWidth + gap)
            }
        }
    }

    private func reset() {
        isScrolling = false
        offset = 0
        textWidth = 0
    }
}
