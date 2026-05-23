import SwiftUI

/// Settings panel for audio quality preferences.
struct SettingsView: View {

    @ObservedObject var viewModel: RadioViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Einstellungen")
                .font(.headline)

            // Stream Format
            VStack(alignment: .leading, spacing: 4) {
                Text("Audio-Format")
                    .font(.caption)
                    .fontWeight(.medium)
                Picker("Format", selection: $viewModel.selectedFormat) {
                    ForEach(StreamFormat.allCases, id: \.self) { format in
                        Text(format.displayName).tag(format)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            // Stream Quality
            VStack(alignment: .leading, spacing: 4) {
                Text("Qualität")
                    .font(.caption)
                    .fontWeight(.medium)
                Picker("Qualität", selection: $viewModel.selectedQuality) {
                    ForEach(StreamQuality.allCases, id: \.self) { quality in
                        Text(quality.displayName).tag(quality)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            Divider()

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text("playSom v1.0")
                    .font(.caption)
                    .fontWeight(.medium)
                Text("Ein SomaFM Radio Player für macOS")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Link("somafm.com", destination: URL(string: "https://somafm.com")!)
                    .font(.caption2)
            }

            Spacer()
        }
        .padding()
        .frame(width: 280, height: 240)
    }
}
