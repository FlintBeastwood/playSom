import SwiftUI

/// Scrollable list of SomaFM channels, partitioned into Pinned and All-channels sections.
struct ChannelListView: View {

    let channels: [Channel]
    let currentChannel: Channel?
    let isPlaying: Bool
    let isVisible: Bool
    let isPinned: (Channel) -> Bool
    let isSearching: Bool
    let onSelect: (Channel) -> Void
    let onTogglePin: (Channel) -> Void

    private var pinnedChannels: [Channel] { channels.filter(isPinned) }
    private var unpinnedChannels: [Channel] { channels.filter { !isPinned($0) } }

    private var showSectionLabels: Bool {
        !isSearching && !pinnedChannels.isEmpty && !unpinnedChannels.isEmpty
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                if showSectionLabels {
                    sectionLabel("Pinned")
                }
                // Namespace IDs per section so a channel moving between
                // pinned/unpinned forces SwiftUI to construct a fresh row
                // rather than reuse the cached one with stale `isPinned`.
                ForEach(pinnedChannels) { channel in
                    row(for: channel).id("pinned-\(channel.id)")
                }
                if showSectionLabels {
                    sectionLabel("All channels").padding(.top, 6)
                }
                ForEach(unpinnedChannels) { channel in
                    row(for: channel).id("unpinned-\(channel.id)")
                }
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 6)
        }
        .scrollIndicators(.automatic)
    }

    private func row(for channel: Channel) -> some View {
        ChannelRow(
            channel: channel,
            isPinned: isPinned(channel),
            isActive: currentChannel?.id == channel.id,
            isPlaying: currentChannel?.id == channel.id && isPlaying,
            isVisible: isVisible,
            onSelect: { onSelect(channel) },
            onTogglePin: { onTogglePin(channel) }
        )
    }

    private func sectionLabel(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 2)
    }
}

// MARK: - Channel Row

struct ChannelRow: View {

    let channel: Channel
    let isPinned: Bool
    let isActive: Bool
    let isPlaying: Bool
    let isVisible: Bool
    let onSelect: () -> Void
    let onTogglePin: () -> Void

    @State private var isHovered = false
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                channelArtwork
                channelInfo
                Spacer(minLength: 0)
                pinButton
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
        .contextMenu {
            Button(isPinned ? "Unpin" : "Pin to top", action: onTogglePin)
        }
    }

    private var rowTooltip: String {
        var lines = [channel.title, channel.description]
        if !channel.genre.isEmpty { lines.append("Genre: \(channel.genre)") }
        if !channel.dj.isEmpty    { lines.append("DJ: \(channel.dj)") }
        return lines.joined(separator: "\n")
    }

    // MARK: - Row Components

    private var channelArtwork: some View {
        CachedAsyncImage(url: URL(string: channel.image)) { image in
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
                    .help(rowTooltip)

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

    private var pinButton: some View {
        Button(action: onTogglePin) {
            Image(systemName: isPinned ? "pin.fill" : "pin")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isPinned ? Color.somaAccent : Color.secondary)
                .frame(width: 20, height: 20)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(isPinned || isHovered ? 1.0 : 0.0)
        .allowsHitTesting(isPinned || isHovered)
        .help(isPinned ? "Unpin" : "Pin to top")
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .animation(.easeInOut(duration: 0.15), value: isPinned)
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
        isVisible: true,
        isPinned: { _ in false },
        isSearching: false,
        onSelect: { _ in },
        onTogglePin: { _ in }
    )
    .frame(width: 320, height: 400)
}
