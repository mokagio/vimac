import AppKit
import SwiftUI
import Testing
@testable import Vimac

/// Builds and draws every settings pane for real.
///
/// SwiftUI failures are runtime failures — a bad `ForEach` identity or a
/// misused binding traps when the view is laid out, not when it is compiled —
/// so the model tests alone would not catch them.
///
/// Set `VIMAC_UI_SNAPSHOT_DIR` to also write each pane out as a PNG to look at.
@MainActor
@Suite("Settings panes render")
struct SettingsViewRenderingTests {
    @Test("Every pane lays out and draws", arguments: SettingsPane.allCases)
    func paneDraws(pane: SettingsPane) throws {
        let bitmap = try #require(render(pane), "\(pane.title) produced no bitmap")

        #expect(bitmap.pixelsWide > 0 && bitmap.pixelsHigh > 0)
        #expect(distinctColorCount(in: bitmap) > 1, "\(pane.title) drew a blank rectangle")

        writeSnapshot(bitmap, named: pane.rawValue)
    }

    // MARK: - Rendering

    private static let size = NSSize(width: 760, height: 520)

    private func render(_ pane: SettingsPane) -> NSBitmapImageRep? {
        let storage = InMemorySettingsStorage()
        let model = SettingsModel(
            store: SettingsStore(storage: storage),
            shortcutStore: ShortcutStore(storage: storage),
            loginItem: FakeLoginItem(),
            keyboardLayouts: [
                KeyboardLayout(id: "com.apple.keylayout.ABC", name: "ABC"),
                KeyboardLayout(id: "com.apple.keylayout.Dvorak", name: "Dvorak"),
            ]
        )

        let navigation = SettingsNavigation()
        navigation.pane = pane

        let hostingView = NSHostingView(rootView: SettingsView(model: model, navigation: navigation))
        hostingView.frame = NSRect(origin: .zero, size: Self.size)

        // SwiftUI only lays out inside a window, and the window has to be
        // ordered in for the hierarchy to be drawn — off screen keeps it out of
        // the way of whoever is running the tests.
        let window = NSWindow(
            contentRect: NSRect(origin: NSPoint(x: -10_000, y: -10_000), size: Self.size),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        window.contentView = hostingView
        window.orderBack(nil)

        hostingView.layoutSubtreeIfNeeded()
        RunLoop.current.run(until: Date().addingTimeInterval(0.4))
        window.displayIfNeeded()

        defer { window.orderOut(nil) }

        guard let bitmap = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            return nil
        }
        hostingView.cacheDisplay(in: hostingView.bounds, to: bitmap)
        return bitmap
    }

    private func distinctColorCount(in bitmap: NSBitmapImageRep) -> Int {
        var colors: Set<Int> = []
        // Sampling on a coarse grid is enough to tell "drew something" from
        // "drew one flat colour", and keeps the pass quick.
        for x in stride(from: 0, to: bitmap.pixelsWide, by: 8) {
            for y in stride(from: 0, to: bitmap.pixelsHigh, by: 8) {
                guard let color = bitmap.colorAt(x: x, y: y) else { continue }
                let packed = Int(color.redComponent * 255) << 16
                    | Int(color.greenComponent * 255) << 8
                    | Int(color.blueComponent * 255)
                colors.insert(packed)
                if colors.count > 1 { return colors.count }
            }
        }
        return colors.count
    }

    private func writeSnapshot(_ bitmap: NSBitmapImageRep, named name: String) {
        guard let png = bitmap.representation(using: .png, properties: [:]) else { return }

        let directory = ProcessInfo.processInfo.environment["VIMAC_UI_SNAPSHOT_DIR"]
            .map { URL(fileURLWithPath: $0) }
            ?? FileManager.default.temporaryDirectory.appendingPathComponent("vimac-settings-snapshots")

        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("\(name).png")
        try? png.write(to: url)
        print("snapshot: \(url.path)")
    }
}
