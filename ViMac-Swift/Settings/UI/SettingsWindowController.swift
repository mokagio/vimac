import Cocoa
import SwiftUI

@MainActor
final class SettingsWindowController: NSWindowController {
    private let navigation = SettingsNavigation()

    init() {
        let model = SettingsModel()
        let navigation = self.navigation

        let hostingController = NSHostingController(
            rootView: SettingsView(model: model, navigation: navigation)
        )

        let window = SettingsWindow(
            contentRect: NSRect(x: 0, y: 0, width: 760, height: 520),
            // `fullSizeContentView` alongside a unified toolbar is what lets the
            // sidebar run the height of the window and sit flush against its
            // edge, the way System Settings does. Without it the sidebar draws
            // as a card inset from the frame.
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.contentViewController = hostingController

        // `toolbarStyle` only takes effect when a toolbar exists. There are no
        // toolbar items to show — the title is the whole point.
        window.toolbar = NSToolbar()
        window.toolbarStyle = .unified

        // Left nil, AppKit hands the first pass of focus to the first control
        // in the key view loop — a text field, which selects its contents as it
        // takes focus. Naming a view that refuses focus opens the window with
        // the cursor nowhere, which is where it belongs until asked for.
        window.initialFirstResponder = hostingController.view

        window.setContentSize(NSSize(width: 760, height: 520))
        window.contentMinSize = NSSize(width: 680, height: 420)
        window.setFrameAutosaveName("SettingsWindow")
        window.isReleasedWhenClosed = false

        super.init(window: window)

        trackTitle()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("SettingsWindowController is not loaded from a nib")
    }

    func show(pane: SettingsPane? = nil) {
        if let pane {
            navigation.pane = pane
        }

        if window?.isVisible != true {
            window?.center()
        }

        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }

    /// Keeps the title bar on the selected pane, the way System Settings does.
    /// `withObservationTracking` fires once, so it re-arms itself each time.
    private func trackTitle() {
        withObservationTracking {
            window?.title = navigation.pane.title
        } onChange: { [weak self] in
            Task { @MainActor in self?.trackTitle() }
        }
    }
}
