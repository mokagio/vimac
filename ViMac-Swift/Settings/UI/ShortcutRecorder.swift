import MASShortcut
import SwiftUI

/// The shortcut capture field.
///
/// It binds itself to the shortcut's `UserDefaults` key through
/// `MASDictionaryTransformer`, which is what writes an empty dictionary when
/// the user clears a shortcut rather than removing the key. `ShortcutSetting`
/// explains why that difference matters.
struct ShortcutRecorder: NSViewRepresentable {
    let shortcut: ShortcutStore.Shortcut
    let onChange: () -> Void

    func makeNSView(context: Context) -> MASShortcutView {
        let view = MASShortcutView()
        view.setAssociatedUserDefaultsKey(shortcut.key, withTransformerName: MASDictionaryTransformerName)
        view.shortcutValueChange = { _ in onChange() }
        return view
    }

    func updateNSView(_ view: MASShortcutView, context: Context) {}
}
