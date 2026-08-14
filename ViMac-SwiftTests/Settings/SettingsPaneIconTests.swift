import AppKit
import Testing
@testable import Vimac

@Suite("Settings pane icons")
struct SettingsPaneIconTests {
    private let light = NSAppearance(named: .aqua)!
    private let dark = NSAppearance(named: .darkAqua)!

    // A sidebar row draws under a vibrant appearance rather than plain aqua.
    // SwiftUI's `colorScheme` did not report those as dark, which left the
    // icons in their light styling on a dark sidebar.
    private let vibrantDark = NSAppearance(named: .vibrantDark)!
    private let vibrantLight = NSAppearance(named: .vibrantLight)!

    @Test("Vibrant appearances count as the appearance they are a variant of")
    func vibrantAppearancesResolve() {
        #expect(SettingsPane.isDark(vibrantDark))
        #expect(!SettingsPane.isDark(vibrantLight))
        #expect(SettingsPane.isDark(dark))
        #expect(!SettingsPane.isDark(light))
    }

    @Test("In light the tile carries the colour and the glyph is white", arguments: SettingsPane.allCases)
    func lightStyling(pane: SettingsPane) {
        #expect(pane.tileColor(for: light) == pane.tint)
        #expect(pane.glyphColor(for: light) == .white)
    }

    @Test("In dark the glyph carries the colour and the tile goes dark", arguments: SettingsPane.allCases)
    func darkStyling(pane: SettingsPane) {
        #expect(pane.glyphColor(for: dark) == pane.tint)
        #expect(isNearBlack(pane.tileColor(for: dark)))
    }

    @Test("A vibrant sidebar row is styled as dark, not light", arguments: SettingsPane.allCases)
    func vibrantDarkStyling(pane: SettingsPane) {
        #expect(pane.glyphColor(for: vibrantDark) == pane.tint)
        #expect(isNearBlack(pane.tileColor(for: vibrantDark)))
    }

    @Test("Every pane is told apart by its colour")
    func tintsAreDistinct() {
        let tints = SettingsPane.allCases.map(\.tint)
        #expect(Set(tints).count == tints.count)
    }

    private func isNearBlack(_ color: NSColor) -> Bool {
        guard let rgb = color.usingColorSpace(.sRGB) else { return false }
        return rgb.redComponent < 0.1 && rgb.greenComponent < 0.1 && rgb.blueComponent < 0.1
    }
}
