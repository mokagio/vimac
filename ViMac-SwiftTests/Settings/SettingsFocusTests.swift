import AppKit
import SwiftUI
import Testing
@testable import Vimac

/// Clicking away from a settings field should let go of it.
///
/// AppKit calls `mouseDown` on the window only for a click no view claimed,
/// which is exactly "clicked away", so these drive that entry point directly.
/// Synthesising the click and letting AppKit route it needs a key window, and
/// the other UI suites contend for that.
@MainActor
@Suite("Settings focus")
struct SettingsFocusTests {
    @Test("A click no control claims gives up focus")
    func unclaimedClickDropsFocus() throws {
        let window = try hostedPane()
        defer { window.orderOut(nil) }

        focusFirstField(in: window)
        try #require(window.firstResponder is NSText, "nothing was focused to begin with")

        window.mouseDown(with: click())

        #expect(!(window.firstResponder is NSText))
    }

    @Test("A click leaves focus alone when no field holds it")
    func unclaimedClickLeavesOtherFocusAlone() throws {
        let window = try hostedPane()
        defer { window.orderOut(nil) }

        let contentView = try #require(window.contentView)
        window.makeFirstResponder(contentView)
        let before = window.firstResponder

        window.mouseDown(with: click())

        #expect(window.firstResponder === before)
    }

    // MARK: - Harness

    private func hostedPane() throws -> SettingsWindow {
        let storage = InMemorySettingsStorage()
        let model = SettingsModel(
            store: SettingsStore(storage: storage),
            shortcutStore: ShortcutStore(storage: storage),
            loginItem: FakeLoginItem(),
            keyboardLayouts: []
        )

        let hostingView = NSHostingView(rootView: HintModeSettingsView(model: model))
        hostingView.frame = NSRect(x: 0, y: 0, width: 760, height: 520)

        let window = SettingsWindow(
            contentRect: NSRect(x: -10_000, y: -10_000, width: 760, height: 520),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        window.contentView = hostingView
        window.orderBack(nil)
        hostingView.layoutSubtreeIfNeeded()
        RunLoop.current.run(until: Date().addingTimeInterval(0.3))
        window.display()
        return window
    }

    /// SwiftUI backs each `TextField` with a view that takes focus, which is
    /// what makes any of this observable from a test.
    private func focusFirstField(in window: NSWindow) {
        window.recalculateKeyViewLoop()
        window.selectNextKeyView(nil)
        RunLoop.current.run(until: Date().addingTimeInterval(0.2))
    }

    private func click() -> NSEvent {
        NSEvent.mouseEvent(
            with: .leftMouseDown,
            location: NSPoint(x: 40, y: 40),
            modifierFlags: [],
            timestamp: ProcessInfo.processInfo.systemUptime,
            windowNumber: 0,
            context: nil,
            eventNumber: 0,
            clickCount: 1,
            pressure: 1
        )!
    }
}
