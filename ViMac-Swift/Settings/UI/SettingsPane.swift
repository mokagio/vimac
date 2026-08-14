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

/// The System Settings sidebar look: a tinted, rounded glyph beside the title.
struct SettingsPaneLabel: View {
    let pane: SettingsPane

    var body: some View {
        Label {
            Text(pane.title)
        } icon: {
            Image(systemName: pane.symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(pane.tint.gradient, in: .rect(cornerRadius: 5))
        }
    }
}
