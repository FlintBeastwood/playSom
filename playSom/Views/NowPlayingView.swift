import SwiftUI

/// Displays the currently playing channel and track with glassmorphism styling.
struct NowPlayingView: View {

    let channel: Channel
    let isPlaying: Bool
    let isLoading: Bool
    let isFavorite: Bool
    let isVisible: Bool
    let onPlayPause: () -> Void
    let onStop: () -> Void
    let onToggleFavorite: () -> Void

    @State private var starAnimating = false
    @State private var isPlayHovered = false
    @State private var isStopHovered = false
    @State private var isStarHovered = false
    @State private var isCartHovered = false

    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some View {
        HStack(spacing: 12) {
            artworkView
            trackInfoView
            playbackControls
        }
        .padding(12)
        .background(nowPlayingBackground)
        .overlay(nowPlayingBorderOverlay)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .shadow(
            color: Color.somaAccent.opacity(isDarkMode ? 0.08 : 0.03),
            radius: 14,
            y: 4
        )
    }

    // MARK: - Artwork

    private var artworkView: some View {
        CachedAsyncImage(url: channel.artworkURL) { image in
            image.resizable().aspectRatio(contentMode: .fill)
        } placeholder: {
            Image(systemName: "music.note.tv")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
        .frame(width: 52, height: 52)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.somaAccent.opacity(0.35))
                .blur(radius: 8)
        )
        .shadow(
            color: Color.somaAccent.opacity(isDarkMode ? 0.25 : 0.10),
            radius: 6,
            y: 2
        )
    }

    // MARK: - Track Info

    private var trackInfoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(channel.title)
                .font(.caption)
                .fontWeight(.bold)
                .lineLimit(1)

            if !channel.lastPlaying.isEmpty {
                HStack(spacing: 6) {
                    MarqueeText(text: channel.lastPlaying, font: .caption2, isVisible: isVisible)
                        .foregroundStyle(.secondary)
                        .id(channel.lastPlaying)

                    favoriteButton
                    bandcampButton
                }
            }

            genreBadge
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Action Buttons

    private var favoriteButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                starAnimating = true
            }
            onToggleFavorite()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                starAnimating = false
            }
        }) {
            Image(systemName: isFavorite ? "star.fill" : "star")
                .font(.caption2)
                .foregroundStyle(isFavorite ? .yellow : (isStarHovered ? .primary : .secondary))
                .scaleEffect(starAnimating ? 1.45 : (isStarHovered ? 1.15 : 1.0))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.70)) {
                isStarHovered = hovering
            }
        }
        .help(isFavorite ? "Remove from favorites" : "Add to favorites")
    }

    @ViewBuilder
    private var bandcampButton: some View {
        if let url = channel.bandcampSearchURL {
            Button(action: { NSWorkspace.shared.open(url) }) {
                Image(systemName: "cart.badge.plus")
                    .font(.caption2)
                    .foregroundStyle(isCartHovered ? Color.somaAccent : .secondary)
                    .scaleEffect(isCartHovered ? 1.15 : 1.0)
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                withAnimation(.spring(response: 0.25, dampingFraction: 0.70)) {
                    isCartHovered = hovering
                }
            }
            .help("Buy on Bandcamp: \(channel.artist) – \(channel.trackName)")
        }
    }

    private var genreBadge: some View {
        Text(channel.genre.replacingOccurrences(of: "|", with: " · "))
            .font(.system(size: 9, weight: .medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.somaAccent.opacity(isDarkMode ? 0.12 : 0.08))
            .foregroundStyle(Color.somaAccent)
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(Color.somaAccent.opacity(0.20), lineWidth: 0.5))
    }

    // MARK: - Playback Controls

    private var playbackControls: some View {
        VStack(spacing: 8) {
            playPauseButton
            stopButton
        }
    }

    private var playPauseButton: some View {
        Button(action: onPlayPause) {
            ZStack {
                Circle()
                    .fill(isDarkMode ? Color.white.opacity(0.10) : Color.black.opacity(0.04))
                    .overlay(
                        Circle().strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.somaAccent.opacity(isPlayHovered ? 0.90 : 0.60),
                                    Color.somaPurple.opacity(isPlayHovered ? 0.70 : 0.40)
                                ],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.25
                        )
                    )
                    .shadow(
                        color: Color.somaAccent.opacity(isPlayHovered ? 0.35 : 0.15),
                        radius: isPlayHovered ? 8 : 4,
                        x: 0,
                        y: isPlayHovered ? 3 : 1
                    )

                if isLoading {
                    ProgressView().controlSize(.small)
                } else {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.somaAccent, Color.somaPurple],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .offset(x: isPlaying ? 0 : 1.5) // optical centering for play triangle
                        .scaleEffect(isPlayHovered ? 1.08 : 1.0)
                }
            }
            .frame(width: 36, height: 36)
            .scaleEffect(isPlayHovered ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                isPlayHovered = hovering
            }
        }
    }

    private var stopButton: some View {
        Button(action: onStop) {
            ZStack {
                Circle()
                    .fill(isStopHovered ? Color.red.opacity(0.12) : Color.primary.opacity(0.04))
                    .frame(width: 20, height: 20)

                Image(systemName: "stop.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(isStopHovered ? Color.red.opacity(0.85) : Color.secondary)
            }
            .scaleEffect(isStopHovered ? 1.10 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.spring(response: 0.20, dampingFraction: 0.70)) {
                isStopHovered = hovering
            }
        }
        .help("Stop playback")
    }

    // MARK: - Background Layers

    private var nowPlayingBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(isDarkMode ? Color.white.opacity(0.06) : Color.white.opacity(0.50))

            LinearGradient(
                colors: [Color.somaAccent.opacity(isDarkMode ? 0.12 : 0.06), .clear],
                startPoint: .leading, endPoint: .trailing
            )

            LinearGradient(
                colors: [
                    isDarkMode ? Color.white.opacity(0.12) : Color.white.opacity(0.60),
                    .clear
                ],
                startPoint: .top, endPoint: .center
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var nowPlayingBorderOverlay: some View {
        RoundedRectangle(cornerRadius: 16)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        isDarkMode ? .white.opacity(0.14) : .black.opacity(0.06),
                        isDarkMode ? .white.opacity(0.03) : .black.opacity(0.01)
                    ],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                lineWidth: 0.75
            )
    }
}


// MARK: - Preview

#Preview {
    NowPlayingView(
        channel: SomaFMService.fallbackChannels.first!,
        isPlaying: true,
        isLoading: false,
        isFavorite: false,
        isVisible: true,
        onPlayPause: {},
        onStop: {},
        onToggleFavorite: {}
    )
    .frame(width: 320)
}
