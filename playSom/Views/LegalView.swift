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

                    // MARK: SomaFM Support — first and most prominent
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.caption)
                                .foregroundStyle(.tint)
                            Text("Support SomaFM")
                                .font(.caption)
                                .fontWeight(.bold)
                        }

                        Text("playSom is a free, open-source client — but the music isn't free to make. SomaFM pays for servers, bandwidth, and music licensing entirely through listener support.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Button {
                            NSWorkspace.shared.open(URL(string: "https://somafm.com/support/")!)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "heart.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.red)
                                Text("Support SomaFM at somafm.com/support")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.tint)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.accentColor.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.accentColor.opacity(0.25), lineWidth: 0.75)
                    )

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
                                NSWorkspace.shared.open(URL(string: "https://github.com/FlintBeastwood/playSom")!)
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
