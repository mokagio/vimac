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

    var tint: Color {
        switch self {
        case .general: return .gray
        case .bindings: return .blue
        case .hintMode: return .orange
        case .scrollMode: return .green
        case .experimental: return .purple
        case .about: return .pink
        }
    }
}

/// The System Settings sidebar look: a rounded tile beside the title.
///
/// Which way round the tile and the glyph are coloured follows the appearance,
/// the way the system's own sidebar icons do — a filled tile under a white
/// glyph in light, a dark tile under a coloured glyph in dark. Whether the user
/// asked for dark icons specifically is not something an app can read, so the
/// appearance is the closest signal available.
struct SettingsPaneLabel: View {
    let pane: SettingsPane

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Label {
            Text(pane.title)
        } icon: {
            Image(systemName: pane.symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(isDark ? AnyShapeStyle(pane.tint) : AnyShapeStyle(.white))
                .frame(width: 20, height: 20)
                .background(tile, in: .rect(cornerRadius: 5))
        }
    }

    private var isDark: Bool { colorScheme == .dark }

    private var tile: AnyShapeStyle {
        isDark
            ? AnyShapeStyle(Color.black.opacity(0.45))
            : AnyShapeStyle(pane.tint.gradient)
    }
}
