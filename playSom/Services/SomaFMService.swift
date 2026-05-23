import Foundation

/// Service for fetching SomaFM channel data and parsing .pls playlist files.
actor SomaFMService {

    private let channelsURL = URL(string: "https://somafm.com/channels.json")!

    // MARK: - Channel List

    /// Fetches the current channel list from the SomaFM API.
    /// Falls back to a bundled list if the network request fails.
    func fetchChannels() async -> [Channel] {
        do {
            let (data, response) = try await URLSession.shared.data(from: channelsURL)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return Self.fallbackChannels
            }
            let decoded = try JSONDecoder().decode(ChannelResponse.self, from: data)
            return decoded.channels
        } catch {
            print("[SomaFMService] Failed to fetch channels: \(error). Using fallback.")
            return Self.fallbackChannels
        }
    }

    // MARK: - PLS Parsing

    /// Parses a .pls playlist file and returns the first stream URL.
    /// PLS files contain entries like:
    /// ```
    /// File1=http://ice1.somafm.com/groovesalad-128-mp3
    /// ```
    /// Allowed domains for stream URLs (prevents redirect attacks via compromised PLS files).
    private static let allowedStreamDomains = ["somafm.com"]

    func parsePlaylistURL(_ playlistURL: URL) async throws -> URL {
        let (data, _) = try await URLSession.shared.data(from: playlistURL)
        guard let content = String(data: data, encoding: .utf8) else {
            throw SomaFMError.invalidPlaylistData
        }

        guard let streamURL = extractFirstStreamURL(from: content) else {
            throw SomaFMError.noStreamURLFound
        }

        let secureURL = upgradeToHTTPS(streamURL)

        guard isAllowedDomain(secureURL) else {
            throw SomaFMError.untrustedStreamDomain
        }

        return secureURL
    }

    /// Extracts the first "File1=" or "File=" URL from a PLS playlist string.
    private func extractFirstStreamURL(from content: String) -> URL? {
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let lowered = trimmed.lowercased()

            guard lowered.hasPrefix("file1=") || lowered.hasPrefix("file="),
                  let equalsIndex = trimmed.firstIndex(of: "=") else {
                continue
            }

            let urlString = String(trimmed[trimmed.index(after: equalsIndex)...])
                .trimmingCharacters(in: .whitespaces)
            return URL(string: urlString)
        }
        return nil
    }

    /// Upgrades an HTTP URL to HTTPS to satisfy ATS and prevent network drops.
    private func upgradeToHTTPS(_ url: URL) -> URL {
        guard url.scheme == "http" else { return url }
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.scheme = "https"
        return components?.url ?? url
    }

    /// Validates that a URL belongs to a known SomaFM domain.
    private func isAllowedDomain(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return Self.allowedStreamDomains.contains(where: { host == $0 || host.hasSuffix(".\($0)") })
    }

    // MARK: - Errors

    enum SomaFMError: LocalizedError {
        case invalidPlaylistData
        case noStreamURLFound
        case untrustedStreamDomain

        var errorDescription: String? {
            switch self {
            case .invalidPlaylistData:
                return "Could not read playlist data."
            case .noStreamURLFound:
                return "No stream URL found in playlist."
            case .untrustedStreamDomain:
                return "Stream URL is not from a trusted SomaFM domain."
            }
        }
    }

    // MARK: - Fallback Channels

    /// A static subset of popular channels as fallback when the API is unreachable.
    static let fallbackChannels: [Channel] = [
        Channel(
            id: "groovesalad", title: "Groove Salad",
            description: "A nicely chilled plate of ambient/downtempo beats and grooves.",
            dj: "Rusty Hodge", genre: "ambient|electronic",
            image: "https://api.somafm.com/img/groovesalad120.png",
            largeimage: "https://api.somafm.com/logos/256/groovesalad256.png",
            xlimage: "https://api.somafm.com/logos/512/groovesalad512.png",
            listeners: "0", lastPlaying: "",
            playlists: [
                .init(url: "https://api.somafm.com/groovesalad130.pls", format: "aac", quality: "highest"),
                .init(url: "https://api.somafm.com/groovesalad64.pls", format: "aacp", quality: "high"),
            ]
        ),
        Channel(
            id: "dronezone", title: "Drone Zone",
            description: "Served best chilled, safe with most medications. Atmospheric textures with minimal beats.",
            dj: "Rusty Hodge", genre: "ambient",
            image: "https://api.somafm.com/img/dronezone120.jpg",
            largeimage: "https://api.somafm.com/logos/256/dronezone256.png",
            xlimage: "https://api.somafm.com/logos/512/dronezone512.png",
            listeners: "0", lastPlaying: "",
            playlists: [
                .init(url: "https://api.somafm.com/dronezone130.pls", format: "aac", quality: "highest"),
                .init(url: "https://api.somafm.com/dronezone64.pls", format: "aacp", quality: "high"),
            ]
        ),
        Channel(
            id: "spacestation", title: "Space Station Soma",
            description: "Tune in, turn on, space out. Spaced-out ambient and mid-tempo electronica.",
            dj: "Rusty Hodge", genre: "electronic",
            image: "https://api.somafm.com/img/sss.jpg",
            largeimage: "https://api.somafm.com/logos/256/spacestation256.png",
            xlimage: "https://api.somafm.com/logos/512/spacestation512.png",
            listeners: "0", lastPlaying: "",
            playlists: [
                .init(url: "https://api.somafm.com/spacestation130.pls", format: "aac", quality: "highest"),
                .init(url: "https://api.somafm.com/spacestation64.pls", format: "aacp", quality: "high"),
            ]
        ),
        Channel(
            id: "deepspaceone", title: "Deep Space One",
            description: "Deep ambient electronic, experimental and space music.",
            dj: "Rusty Hodge", genre: "ambient",
            image: "https://api.somafm.com/img/deepspaceone120.gif",
            largeimage: "https://api.somafm.com/logos/256/deepspaceone256.png",
            xlimage: "https://api.somafm.com/logos/512/deepspaceone512.png",
            listeners: "0", lastPlaying: "",
            playlists: [
                .init(url: "https://api.somafm.com/deepspaceone130.pls", format: "aac", quality: "highest"),
                .init(url: "https://api.somafm.com/deepspaceone64.pls", format: "aacp", quality: "high"),
            ]
        ),
        Channel(
            id: "secretagent", title: "Secret Agent",
            description: "The soundtrack for your stylish, mysterious, dangerous life.",
            dj: "Rusty Hodge", genre: "lounge",
            image: "https://api.somafm.com/img/secretagent120.jpg",
            largeimage: "https://api.somafm.com/logos/256/secretagent256.png",
            xlimage: "https://api.somafm.com/logos/512/secretagent512.png",
            listeners: "0", lastPlaying: "",
            playlists: [
                .init(url: "https://api.somafm.com/secretagent130.pls", format: "aac", quality: "highest"),
                .init(url: "https://api.somafm.com/secretagent64.pls", format: "aacp", quality: "high"),
            ]
        ),
        Channel(
            id: "defcon", title: "DEF CON Radio",
            description: "Music for Hacking. The DEF CON Year-Round Channel.",
            dj: "Rusty Hodge", genre: "electronic",
            image: "https://api.somafm.com/img/defcon120.png",
            largeimage: "https://api.somafm.com/logos/256/defcon256.png",
            xlimage: "https://api.somafm.com/logos/512/defcon512.png",
            listeners: "0", lastPlaying: "",
            playlists: [
                .init(url: "https://api.somafm.com/defcon130.pls", format: "aac", quality: "highest"),
                .init(url: "https://api.somafm.com/defcon64.pls", format: "aacp", quality: "high"),
            ]
        ),
        Channel(
            id: "indiepop", title: "Indie Pop Rocks!",
            description: "New and classic favorite indie pop tracks.",
            dj: "Elise", genre: "alternative|rock",
            image: "https://api.somafm.com/img/indychick.jpg",
            largeimage: "https://api.somafm.com/logos/256/indiepop256.png",
            xlimage: "https://api.somafm.com/logos/512/indiepop512.png",
            listeners: "0", lastPlaying: "",
            playlists: [
                .init(url: "https://api.somafm.com/indiepop130.pls", format: "aac", quality: "highest"),
                .init(url: "https://api.somafm.com/indiepop64.pls", format: "aacp", quality: "high"),
            ]
        ),
    ]
}
