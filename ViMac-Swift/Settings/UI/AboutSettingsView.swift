import SwiftUI

struct AboutSettingsView: View {
    private static let forkURL = URL(string: "https://github.com/mokagio/vimac/")!
    private static let originalURL = URL(string: "https://github.com/dexterleng/vimac/")!

    var body: some View {
        VStack(spacing: 24) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)
                .accessibilityHidden(true)

            VStack(spacing: 6) {
                Text("Vimac")
                    .font(.title.weight(.semibold))

                Text(Self.versionSummary)
                    .foregroundStyle(.secondary)

                Text("Copyright © 2026 Gio Lodi")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    Link("Original version", destination: Self.originalURL)
                        .underline()
                    Text("by Dexter Leng — 2021")
                }
                .font(.callout)
                .foregroundStyle(.secondary)
            }

            Link("Source Code", destination: Self.forkURL)
                .buttonStyle(.bordered)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }

    private static var versionSummary: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? "?"
        return "Version \(short) (\(build))"
    }
}
