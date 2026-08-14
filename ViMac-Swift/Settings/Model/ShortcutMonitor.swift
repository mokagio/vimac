import Cocoa
import MASShortcut
import RxSwift

/// Registers the mode-activation shortcuts with the system and reports when
/// they fire. The storage rules live in `ShortcutStore`; this is the glue that
/// makes MASShortcut act on them.
final class ShortcutMonitor {
    static let shared = ShortcutMonitor()

    private let store: ShortcutStore

    init(store: ShortcutStore = ShortcutStore()) {
        self.store = store
    }

    func setUp() {
        store.migrateLegacyStorage()

        MASShortcutBinder.shared().bindingOptions = [
            NSBindingOption.valueTransformerName.rawValue: MASDictionaryTransformerName
        ]

        // Only fills keys that are absent, which is what leaves a cleared
        // shortcut cleared. See `ShortcutSetting`.
        MASShortcutBinder.shared().registerDefaultShortcuts(
            ShortcutStore.Shortcut.allCases.reduce(into: [:]) { defaults, shortcut in
                defaults[shortcut.key] = MASShortcut(
                    keyCode: shortcut.defaultCombination.keyCode,
                    modifierFlags: NSEvent.ModifierFlags(rawValue: shortcut.defaultCombination.modifierFlags)
                )
            }
        )
    }

    func activation(of shortcut: ShortcutStore.Shortcut) -> Observable<Void> {
        Observable.create { observer in
            MASShortcutBinder.shared().bindShortcut(withDefaultsKey: shortcut.key) {
                observer.onNext(())
            }
            return Disposables.create()
        }
    }
}
