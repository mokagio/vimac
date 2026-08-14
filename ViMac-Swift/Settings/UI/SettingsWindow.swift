import Cocoa

/// AppKit leaves a text field focused when you click away from it, which in a
/// settings window reads as a field you cannot get out of. A click no control
/// claims hands focus back to the window.
final class SettingsWindow: NSWindow {
    override func mouseDown(with event: NSEvent) {
        if firstResponder is NSText {
            makeFirstResponder(nil)
        }
        super.mouseDown(with: event)
    }
}
