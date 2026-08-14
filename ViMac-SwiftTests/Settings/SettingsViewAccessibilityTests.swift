import AppKit
import SwiftUI
import Testing
@testable import Vimac

/// Reads each pane the way a screen reader would, which is how the contents of a
/// rendered SwiftUI view can be asserted on without a screenshot.
///
/// The sidebar is not covered: it is an `NSTableView` underneath, and those
/// build their rows only once a real assistive client attaches, so an offscreen
/// host sees an empty group whatever the list holds.
@MainActor
@Suite("Settings panes expose their controls")
struct SettingsViewAccessibilityTests {
    @Test("General names the layout picker and the login item toggle")
    func general() {
        let labels = labels(of: .general)

        #expect(labels.contains { $0.contains("Force Keyboard Layout") })
        #expect(labels.contains { $0.contains("Launch Vimac at login") })
    }

    @Test("Bindings names both shortcuts, both key sequences, and the reset delay")
    func bindings() {
        let labels = labels(of: .bindings)

        #expect(labels.contains { $0.contains("Hold Space") })
        #expect(labels.contains { $0.contains("Restore Default") })
        #expect(labels.contains { $0.contains("Reset Delay") })
        #expect(labels.contains { $0.contains("Shortcut Activation") })
        #expect(labels.contains { $0.contains("Key Sequence Activation") })
    }

    @Test("Hint Mode names the characters and text size fields")
    func hintMode() {
        let labels = labels(of: .hintMode)

        #expect(labels.contains { $0.contains("Characters") })
        #expect(labels.contains { $0.contains("Text Size") })
    }

    @Test("Scroll Mode names the keys field, the sensitivity slider, and both reverse toggles")
    func scrollMode() {
        let labels = labels(of: .scrollMode)

        #expect(labels.contains { $0.contains("Scroll Keys") })
        #expect(labels.contains { $0.contains("Sensitivity") })
        #expect(labels.contains("Horizontal"))
        #expect(labels.contains("Vertical"))
    }

    @Test("Experimental names both opt-ins")
    func experimental() {
        let labels = labels(of: .experimental)

        #expect(labels.contains { $0.contains("Electron support") })
        #expect(labels.contains { $0.contains("Emulate VoiceOver") })
    }

    @Test("About credits both this fork and the original")
    func about() {
        let labels = labels(of: .about)

        #expect(labels.contains("Vimac"))
        #expect(labels.contains { $0.contains("Gio Lodi") })
        #expect(labels.contains { $0.contains("Dexter Leng") })
        #expect(labels.contains { $0.contains("Source Code") })
    }

    // MARK: - Reading the hierarchy

    private func labels(of pane: SettingsPane) -> Set<String> {
        let storage = InMemorySettingsStorage()
        let model = SettingsModel(
            store: SettingsStore(storage: storage),
            shortcutStore: ShortcutStore(storage: storage),
            loginItem: FakeLoginItem(),
            keyboardLayouts: [KeyboardLayout(id: "com.apple.keylayout.ABC", name: "ABC")]
        )

        let navigation = SettingsNavigation()
        navigation.pane = pane

        let hostingView = NSHostingView(rootView: SettingsView(model: model, navigation: navigation))
        hostingView.frame = NSRect(x: 0, y: 0, width: 760, height: 520)

        let window = NSWindow(
            contentRect: NSRect(x: -10_000, y: -10_000, width: 760, height: 520),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        window.contentView = hostingView
        window.orderBack(nil)
        defer { window.orderOut(nil) }

        // SwiftUI fills the tree over several passes, so it is read until it
        // stops growing rather than after a fixed wait.
        var collected: Set<String> = []
        var settledPasses = 0
        for _ in 0..<40 where settledPasses < 3 {
            hostingView.layoutSubtreeIfNeeded()
            window.display()
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))

            let before = collected.count
            collect(from: hostingView, into: &collected, depth: 0)
            settledPasses = collected.count == before ? settledPasses + 1 : 0
        }
        return collected
    }

    /// SwiftUI does not put one `NSView` per control on screen — it reports its
    /// contents through the accessibility tree, so that is what gets walked.
    private func collect(from element: Any, into collected: inout Set<String>, depth: Int) {
        guard depth < 40 else { return }
        let object = element as AnyObject

        let strings: [String?] = [
            object.accessibilityLabel?(),
            object.accessibilityTitle?(),
            // `accessibilityValue()` is declared on several AppKit protocols,
            // so it has to be sent by selector to pick one.
            send("accessibilityValue", to: object),
        ]
        for string in strings.compactMap({ $0 }) where !string.isEmpty {
            collected.insert(string)
        }

        for child in (object.accessibilityChildren?() ?? []) ?? [] {
            collect(from: child, into: &collected, depth: depth + 1)
        }
    }

    private func send(_ selectorName: String, to object: AnyObject) -> String? {
        let selector = NSSelectorFromString(selectorName)
        guard object.responds(to: selector) else { return nil }
        return object.perform(selector)?.takeUnretainedValue() as? String
    }
}
