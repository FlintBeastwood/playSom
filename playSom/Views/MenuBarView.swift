import SwiftUI
import AppKit

/// The main menu bar popover view — glassmorphism edition.
struct MenuBarView: View {

    @ObservedObject var viewModel: RadioViewModel
    @State private var showingLegal = false
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    @FocusState private var isSearchFocused: Bool
    @State private var themeRotation = 0.0
    @State private var isVisible = false

    var body: some View {
        ZStack(alignment: .top) {

            // ── Aurora gradient overlay (optimized for premium ambient blend) ──
            LinearGradient(
                colors: [Color.somaAccent.opacity(isDarkMode ? 0.08 : 0.04), Color.somaPurple.opacity(isDarkMode ? 0.05 : 0.02), .clear],
                startPoint: .topLeading,
                endPoint: .center
            )
            .frame(height: 160)
            .allowsHitTesting(false)
            .zIndex(1)

            // ── Main content stack ────────────────────────────────────────────
            VStack(spacing: 0) {
                if showingLegal {
                    LegalView(isShowing: $showingLegal)
                    gradientDivider
                    bottomControls

                } else if viewModel.showingFavorites {
                    FavoritesView(
                        favoritesService: viewModel.favoritesService,
                        isShowingFavorites: $viewModel.showingFavorites
                    )
                    gradientDivider
                    bottomControls

                } else {
                    headerView
                    gradientDivider

                    if let channel = viewModel.currentChannel {
                        NowPlayingView(
                            channel: channel,
                            isPlaying: viewModel.isPlaying,
                            isLoading: viewModel.isLoading,
                            isFavorite: viewModel.isCurrentTrackFavorite,
                            isVisible: isVisible,
                            onPlayPause: { viewModel.togglePlayPause() },
                            onStop: { viewModel.stop() },
                            onToggleFavorite: { viewModel.toggleCurrentTrackFavorite() }
                        )
                        Divider()
                    }

                    searchBar

                    ChannelListView(
                        channels: viewModel.filteredChannels,
                        currentChannel: viewModel.currentChannel,
                        isPlaying: viewModel.isPlaying,
                        isVisible: isVisible
                    ) { channel in
                        Task { await viewModel.play(channel: channel) }
                    }

                    gradientDivider
                    bottomControls
                }
            }
            .zIndex(0)
        }
        .frame(width: 320, height: 520)
        .background(
            ZStack {
                Color.clear
                if isDarkMode {
                    Color.darkObsidian.opacity(0.85)
                } else {
                    Color.lightCloud.opacity(0.88)
                }
                
                // Ambient Aurora orbs
                RadialGradient(
                    colors: [Color.glowTeal.opacity(isDarkMode ? 0.16 : 0.10), .clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 240
                )
                RadialGradient(
                    colors: [Color.glowPurple.opacity(isDarkMode ? 0.12 : 0.07), .clear],
                    center: .bottomTrailing,
                    startRadius: 0,
                    endRadius: 240
                )
            }
        )
        .onAppear {
            NSApp.appearance = NSAppearance(named: isDarkMode ? .darkAqua : .aqua)
            isVisible = true
        }
        .task {
            await viewModel.loadChannels()
            viewModel.startPeriodicRefresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            isVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification)) { _ in
            isVisible = false
        }
    }
    // MARK: - Gradient Divider

    private var gradientDivider: some View {
        Color.primary.opacity(isDarkMode ? 0.08 : 0.05)
            .frame(height: 0.75)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 10) {

            // Gradient logo icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.somaAccent, Color.somaPurple],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)
                    .shadow(color: Color.somaAccent.opacity(0.55), radius: 7)

                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
            }

            Text("playSom")
                .font(.headline)
                .fontWeight(.bold)

            Spacer()

            // Favorites glass pill
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.showingFavorites = true
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                    if viewModel.favoritesService.favorites.count > 0 {
                        Text("\(viewModel.favoritesService.favorites.count)")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .monospacedDigit()
                    }
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.22), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .help("Show favorites")

            Text("SomaFM")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(isSearchFocused ? Color.somaAccent : Color.primary.opacity(0.48))
                .font(.caption)
                .scaleEffect(isSearchFocused ? 1.05 : 1.0)
            
            TextField("Search channels…", text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .font(.caption)
                .focused($isSearchFocused)
            
            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.caption2)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isDarkMode ? Color.white.opacity(0.04) : Color.black.opacity(0.02))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(
                    isSearchFocused ? Color.somaAccent.opacity(0.60) : Color.primary.opacity(0.10),
                    lineWidth: 0.75
                )
        )
        .shadow(
            color: isSearchFocused ? Color.somaAccent.opacity(0.12) : .clear,
            radius: 8,
            x: 0,
            y: 2
        )
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .animation(.easeInOut(duration: 0.2), value: isSearchFocused)
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 8) {
            volumeSlider
            errorMessage
            toolbarButtons
        }
        .padding(.vertical, 10)
    }

    private var volumeSlider: some View {
        HStack(spacing: 10) {
            Image(systemName: "speaker.fill")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            
            CustomVolumeSlider(value: Binding(get: { viewModel.volume }, set: { viewModel.volume = $0 }))
            
            Image(systemName: "speaker.wave.3.fill")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var errorMessage: some View {
        if let error = viewModel.errorMessage {
            Text(error)
                .font(.caption2)
                .foregroundStyle(.red)
                .lineLimit(2)
                .padding(.horizontal, 16)
        }
    }

    private var toolbarButtons: some View {
        HStack {
            Button { showingLegal = true } label: {
                Image(systemName: "info.circle")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Information & Privacy")

            Spacer()
            themeToggleButton
            Spacer()

            Button { NSApplication.shared.terminate(nil) } label: {
                Text("Quit").font(.caption).foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
    }

    private var themeToggleButton: some View {
        Button {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) {
                themeRotation += 360
                isDarkMode.toggle()
            }
        } label: {
            Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                .font(.body)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.somaAccent, Color.somaPurple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .rotationEffect(.degrees(themeRotation))
                .scaleEffect(isDarkMode ? 1.0 : 0.9)
        }
        .buttonStyle(.plain)
        .help(isDarkMode ? "Switch to Light Mode" : "Switch to Dark Mode")
    }
}

// MARK: - Custom Premium Volume Slider

struct CustomVolumeSlider: View {
    @Binding var value: Float
    @State private var isHovering = false
    @State private var isDragging = false
    
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background Track
                Capsule()
                    .fill(isDarkMode ? Color.white.opacity(0.15) : Color.black.opacity(0.10))
                    .frame(height: 5)
                
                // Active Track (Gradient)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.somaAccent, Color.somaPurple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * CGFloat(value), height: 5)
                
                // Thumb
                Circle()
                    .fill(.white)
                    .frame(width: 12, height: 12)
                    .shadow(color: .black.opacity(0.25), radius: 3, y: 1.5)
                    .offset(x: max(0, min(geometry.size.width * CGFloat(value) - 6, geometry.size.width - 12)))
                    .opacity(isHovering || isDragging ? 1.0 : 0.0)
                    .scaleEffect(isHovering || isDragging ? 1.0 : 0.6)
            }
            .frame(height: 12)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        isDragging = true
                        let width = geometry.size.width
                        let newValue = Float(gesture.location.x / width)
                        value = min(max(newValue, 0.0), 1.0)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
        }
        .frame(height: 12)
        .onHover { hovering in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                isHovering = hovering
            }
        }
    }
}
