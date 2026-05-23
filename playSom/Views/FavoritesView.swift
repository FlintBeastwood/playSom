import SwiftUI

/// Displays the user's list of favorite songs.
struct FavoritesView: View {

    @ObservedObject var favoritesService: FavoritesService
    @Binding var isShowingFavorites: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button {
                    isShowingFavorites = false
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.tint)

                Spacer()

                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                    .font(.caption)
                Text("Favorites")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                // Song count badge
                Text("\(favoritesService.favorites.count)")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .monospacedDigit()
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            // Favorites list
            if favoritesService.favorites.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(favoritesService.favorites) { song in
                            FavoriteSongRow(song: song) {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    favoritesService.removeFavorite(id: song.id)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .scrollIndicators(.automatic)
            }

            // Clear all button (only when there are favorites)
            if !favoritesService.favorites.isEmpty {
                Divider()
                HStack {
                    Button {
                        favoritesService.clearAll()
                    } label: {
                        Text("Clear all")
                            .font(.caption2)
                            .foregroundStyle(.red.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "star.slash")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)
            Text("No favorites yet")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Tap ★ next to the\ncurrent track to save it.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Favorite Song Row

struct FavoriteSongRow: View {

    let song: FavoriteSong
    let onRemove: () -> Void

    @State private var isHovered = false
    @State private var isCartHovered = false
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some View {
        HStack(spacing: 10) {
            // Star icon
            Image(systemName: "star.fill")
                .font(.caption2)
                .foregroundStyle(.yellow)

            // Song info
            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Text(song.channelTitle)
                        .font(.caption2)
                        .foregroundStyle(Color.somaAccent)

                    Text("·")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    Text(song.savedAt, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer(minLength: 0)

            // Action buttons (visible on hover)
            if isHovered {
                HStack(spacing: 8) {
                    // 🛒 Bandcamp with micro-spring hover
                    if let url = song.bandcampSearchURL {
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
                        .help("Buy on Bandcamp: \(song.artist) – \(song.trackName)")
                    }

                    Button(action: onRemove) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background {
            if isHovered {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                isDarkMode ? Color.white.opacity(0.10) : Color.black.opacity(0.04),
                                lineWidth: 0.75
                            )
                    )
            }
        }
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                isHovered = hovering
            }
        }
        .padding(.horizontal, 8)
    }
}
