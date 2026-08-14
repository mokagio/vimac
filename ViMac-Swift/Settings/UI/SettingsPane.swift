import SwiftUI

enum SettingsPane: String, CaseIterable, Identifiable {
    case general
    case bindings
    case hintMode
    case scrollMode
    case experimental
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: return "General"
        case .bindings: return "Bindings"
        case .hintMode: return "Hint Mode"
        case .scrollMode: return "Scroll Mode"
        case .experimental: return "Experimental"
        case .about: return "About"
        }
    }

    var symbol: String {
        switch self {
        case .general: return "gearshape"
        case .bindings: return "keyboard"
        case .hintMode: return "cursorarrow.motionlines"
        case .scrollMode: return "arrow.up.and.down.and.arrow.left.and.right"
        case .experimental: return "flask"
        case .about: return "info.circle"
        }
    }

    var tint: NSColor {
        switch self {
        case .general: return .systemGray
        case .bindings: return .systemBlue
        case .hintMode: return .systemOrange
        case .scrollMode: return .systemGreen
        case .experimental: return .systemPurple
        case .about: return .systemPink
        }
    }

    /// The system's own sidebar icons invert between appearances: a filled tile
    /// under a white glyph in light, a dark tile under a coloured glyph in dark.
    ///
    /// Decided from the `NSAppearance` rather than SwiftUI's `colorScheme`,
    /// because a sidebar row draws under a vibrant appearance and `bestMatch`
    /// is what maps those back onto light and dark.
    func tileColor(for appearance: NSAppearance) -> NSColor {
        Self.isDark(appearance) ? NSColor.black.withAlphaComponent(0.45) : tint
    }

    func glyphColor(for appearance: NSAppearance) -> NSColor {
        Self.isDark(appearance) ? tint : .white
    }

    static func isDark(_ appearance: NSAppearance) -> Bool {
        appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
    }
}

/// The System Settings sidebar look: a rounded tile beside the title.
///
/// Whether the user asked for dark icons specifically is not something an app
/// can read, so the appearance stands in for it.
struct SettingsPaneLabel: View {
    let pane: SettingsPane

    var body: some View {
        Label {
            Text(pane.title)
        } icon: {
            Image(systemName: pane.symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(dynamic(pane.glyphColor))
                .frame(width: 20, height: 20)
                .background(dynamic(pane.tileColor), in: .rect(cornerRadius: 5))
        }
    }

    /// Resolved as it draws, so the row's own appearance decides rather than
    /// whatever the environment was when the view was built.
    private func dynamic(_ resolve: @escaping (NSAppearance) -> NSColor) -> Color {
        Color(nsColor: NSColor(name: nil) { resolve($0) })
    }
}
