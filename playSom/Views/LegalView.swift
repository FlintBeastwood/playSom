import SwiftUI

/// Legal information: Privacy Policy, Copyright, and Attribution.
struct LegalView: View {

    @Binding var isShowing: Bool

    var body: some View {
        VStack(spacing: 0) {

            // Header
            HStack {
                Button {
                    isShowing = false
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.tint)

                Spacer()

                Image(systemName: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Information")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // MARK: Privacy Policy
                    legalSection(title: "Privacy Policy", icon: "lock.shield") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("playSom does not collect, transmit, or share any personal data.")
                                .font(.caption)
                                .fontWeight(.medium)

                            dataItem(
                                title: "Favorites",
                                detail: "Song titles and channel names you star are stored locally on your Mac only (UserDefaults). This data never leaves your device."
                            )
                            dataItem(
                                title: "Network requests",
                                detail: "The app connects solely to somafm.com to fetch the channel list and audio streams. No personal data is transmitted in these requests."
                            )
                            dataItem(
                                title: "No tracking",
                                detail: "No analytics, advertising networks, or third-party SDKs are used."
                            )
                        }
                    }

                    // MARK: Third-party Content
                    legalSection(title: "Third-Party Content", icon: "antenna.radiowaves.left.and.right") {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("playSom is an unofficial, open-source client for SomaFM.")
                                .font(.caption)

                            Text("All streams, channel names, artwork, and metadata are property of SomaFM LLC. Please consider supporting them:")
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            Button {
                                NSWorkspace.shared.open(URL(string: "https://somafm.com/support/")!)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "heart.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.red)
                                    Text("somafm.com/support")
                                        .font(.caption)
                                        .foregroundStyle(.tint)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // MARK: License
                    legalSection(title: "License", icon: "doc.badge.gearshape") {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("GNU AGPLv3 License")
                                .font(.caption)
                                .fontWeight(.medium)

                            Text("Copyright © 2026 Tobias Lettenmeier")
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            Text("This software is free software, licensed under the GNU Affero General Public License v3.0. You can redistribute and modify it under these terms.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            Button {
                                NSWorkspace.shared.open(URL(string: "https://github.com/tobiaslettenmeier/playSom")!)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                                        .font(.caption2)
                                    Text("Source code on GitHub")
                                        .font(.caption)
                                }
                                .foregroundStyle(.tint)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // MARK: Disclaimer
                    legalSection(title: "Disclaimer", icon: "exclamationmark.triangle") {
                        Text("This app is not affiliated with or endorsed by SomaFM LLC. Stream availability depends on SomaFM's servers and may change without notice.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(16)
            }
            .scrollIndicators(.automatic)
        }
    }

    // MARK: - Helper Views

    @ViewBuilder
    private func legalSection<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(.tint)
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
            }

            content()
                .padding(10)
                .background(.quaternary.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func dataItem(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .fontWeight(.semibold)
            Text(detail)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
