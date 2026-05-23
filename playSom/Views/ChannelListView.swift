import SwiftUI

/// Scrollable list of SomaFM channels with glassmorphism hover and active states.
struct ChannelListView: View {

    let channels: [Channel]
    let currentChannel: Channel?
    let isPlaying: Bool
    let isVisible: Bool
    let onSelect: (Channel) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(channels) { channel in
                    ChannelRow(
                        channel: channel,
                        isActive: currentChannel?.id == channel.id,
                        isPlaying: currentChannel?.id == channel.id && isPlaying,
                        isVisible: isVisible,
                        onSelect: { onSelect(channel) }
                    )
                }
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 6)
        }
        .scrollIndicators(.automatic)
    }
}

// MARK: - Channel Row

struct ChannelRow: View {

    let channel: Channel
    let isActive: Bool
    let isPlaying: Bool
    let isVisible: Bool
    let onSelect: () -> Void

    @State private var isHovered = false
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                channelArtwork
                channelInfo
                Spacer(minLength: 0)
                listenerCount
            }
            .padding(.leading, isActive ? 14 : 10)
            .padding(.trailing, 10)
            .padding(.vertical, 7)
            .background { rowBackground }
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isHovered)
            .animation(.spring(response: 0.30, dampingFraction: 0.75), value: isActive)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in isHovered = hovering }
    }

    // MARK: - Row Components

    private var channelArtwork: some View {
        CachedAsyncImage(url: URL(string: channel.largeimage)) { image in
            image.resizable().aspectRatio(contentMode: .fill)
        } placeholder: {
            Image(systemName: "music.note")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 38, height: 38)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(
            color: isActive ? Color.somaAccent.opacity(0.40) : .black.opacity(0.12),
            radius: isActive ? 6 : 3,
            y: 1
        )
    }

    private var channelInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 5) {
                Text(channel.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .foregroundStyle(isActive ? Color.somaAccent : .primary)

                if isPlaying {
                    PlayingIndicator(isVisible: isVisible)
                }
            }

            Text(channel.description)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private var listenerCount: some View {
        VStack(alignment: .trailing, spacing: 1) {
            Text(channel.listeners)
                .font(.caption2)
                .fontWeight(.medium)
                .monospacedDigit()
                .foregroundStyle(isActive ? Color.somaAccent : .secondary)
            Image(systemName: "headphones")
                .font(.system(size: 8))
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Row Background

    @ViewBuilder
    private var rowBackground: some View {
        ZStack(alignment: .leading) {
            if isActive {
                activeBackground
                activeIndicatorPill
            } else if isHovered {
                hoveredBackground
            }
        }
    }

    private var activeBackground: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(isDarkMode ? Color.white.opacity(0.06) : Color.white.opacity(0.45))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.somaAccent.opacity(isDarkMode ? 0.08 : 0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.somaAccent.opacity(0.35), Color.somaPurple.opacity(0.15)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.75
                    )
            )
    }

    private var activeIndicatorPill: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [Color.somaAccent, Color.somaPurple],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .frame(width: 3, height: 18)
            .padding(.leading, 5)
            .shadow(color: Color.somaAccent.opacity(0.55), radius: 3)
            .transition(.scale.combined(with: .opacity))
    }

    private var hoveredBackground: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(isDarkMode ? Color.white.opacity(0.04) : Color.black.opacity(0.03))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        isDarkMode ? Color.white.opacity(0.10) : Color.black.opacity(0.04),
                        lineWidth: 0.75
                    )
            )
    }
}

// MARK: - Playing Indicator (Animated Bars)

struct PlayingIndicator: View {

    let isVisible: Bool

    var body: some View {
        // TimelineView with `paused: true` stops rendering completely — zero CPU
        TimelineView(.animation(minimumInterval: 1.0 / 20, paused: !isVisible)) { context in
            HStack(spacing: 1.5) {
                ForEach(0..<3, id: \.self) { index in
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.somaAccent, Color.somaPurple],
                                startPoint: .bottom, endPoint: .top
                            )
                        )
                        .frame(width: 2, height: barHeight(index, date: context.date))
                }
            }
        }
        .frame(width: 12, height: 10)
    }

    /// Organic sine-wave bar heights — smooth and varied without .repeatForever
    private func barHeight(_ index: Int, date: Date) -> CGFloat {
        let time = date.timeIntervalSinceReferenceDate
        let frequencies: [Double] = [2.6, 1.8, 2.2]
        let maxHeights: [CGFloat] = [9.0, 5.0, 7.5]
        let phase = Double(index) * 0.8
        let normalized = (sin(time * frequencies[index] + phase) + 1) / 2  // 0…1
        return 3 + normalized * (maxHeights[index] - 3)
    }
}

// MARK: - Preview

#Preview {
    ChannelListView(
        channels: SomaFMService.fallbackChannels,
        currentChannel: SomaFMService.fallbackChannels.first,
        isPlaying: true,
        isVisible: true
    ) { _ in }
    .frame(width: 320, height: 400)
}
