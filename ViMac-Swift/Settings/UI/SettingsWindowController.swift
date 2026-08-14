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

        let window = NSWindow(contentViewController: hostingController)
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
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
