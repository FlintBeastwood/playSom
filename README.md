# 📻 playSom

A lightweight macOS menu bar app for streaming [SomaFM](https://somafm.com) internet radio.

![macOS](https://img.shields.io/badge/macOS-15.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-AGPLv3-red)

## Features

- 🎵 **30+ SomaFM Channels** — Groove Salad, Drone Zone, DEF CON Radio and more
- 📡 **Lives in your menu bar** — No dock icon, no clutter
- 🔍 **Search** — Find channels by name, genre, or DJ
- 🎛️ **Volume control** — Built-in slider
- 🎹 **Media key support** — Play/Pause with your keyboard
- 🖥️ **Now Playing** — Shows current track in the macOS media widget
- 📊 **Live data** — Channel list updates automatically from the SomaFM API
- ⚡ **Lightweight** — Native Swift, ~5 MB app size

## Screenshots

<!-- TODO: Add screenshots -->

## Installation

### Download (Recommended)

1. Go to [Releases](../../releases)
2. Download the latest `playSom.dmg`
3. Drag `playSom.app` to your Applications folder
4. Launch — a radio icon appears in your menu bar!

### Build from Source

Requires **Xcode 16+** and **macOS 15.0+**.

```bash
git clone https://github.com/YOUR_USERNAME/playSom.git
cd playSom
xcodebuild -scheme playSom -configuration Release build
```

Or open `playSom.xcodeproj` in Xcode and press `⌘R`.

## Tech Stack

- **Swift + SwiftUI** — Native macOS UI
- **AVPlayer** — Audio streaming
- **MenuBarExtra** — Menu bar integration
- **MPNowPlayingInfoCenter** — Media key & Now Playing support

## How it works

1. Loads channel data from the [SomaFM API](https://somafm.com/channels.json)
2. Parses `.pls` playlist files to get direct stream URLs
3. Streams audio via `AVPlayer` (AAC/MP3)
4. Updates Now Playing info for macOS media controls

## License

GNU AGPLv3 License — see [LICENSE](LICENSE) for details.

## Credits

- [SomaFM](https://somafm.com) — Listener-supported, commercial-free internet radio since 2000
- Please consider [donating to SomaFM](https://somafm.com/support/) to keep the music playing! 🎶
