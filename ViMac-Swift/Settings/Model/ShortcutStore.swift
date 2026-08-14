import Carbon
import Cocoa
import MASShortcut

/// Reads and writes the mode-activation shortcuts, keeping "never set" apart
/// from "deliberately cleared". See `ShortcutSetting` for why that matters.
struct ShortcutStore {
    enum Shortcut: String, CaseIterable, Identifiable {
        case hintMode = "HintModeShortcut"
        case scrollMode = "ScrollModeShortcut"

        var id: String { rawValue }

        /// The `UserDefaults` key, which is also the raw value.
        var key: String { rawValue }

        var title: String {
            switch self {
            case .hintMode: return "Hint Mode"
            case .scrollMode: return "Scroll Mode"
            }
        }

        var defaultCombination: KeyCombination {
            switch self {
            case .hintMode: return KeyCombination(keyCode: kVK_ANSI_F, modifierFlags: .control)
            case .scrollMode: return KeyCombination(keyCode: kVK_ANSI_J, modifierFlags: .control)
            }
        }
    }

    private let storage: SettingsStorage

    init(storage: SettingsStorage = UserDefaultsStorage.standard) {
        self.storage = storage
    }

    func setting(for shortcut: Shortcut) -> ShortcutSetting {
        ShortcutSetting.decode(storage.persistedObject(forKey: shortcut.key))
    }

    func set(_ setting: ShortcutSetting, for shortcut: Shortcut) {
        guard let value = setting.storageValue else {
            storage.removeObject(forKey: shortcut.key)
            return
        }
        storage.set(value, forKey: shortcut.key)
    }

    /// The combination actually in force, or nil when the user cleared it.
    func combination(for shortcut: Shortcut) -> KeyCombination? {
        setting(for: shortcut).resolved(default: shortcut.defaultCombination)
    }

    /// Converts shortcuts stored as `NSKeyedArchive` data by earlier versions
    /// into the dictionary form. Without this, upgrading silently drops every
    /// custom shortcut on first launch.
    func migrateLegacyStorage() {
        for shortcut in Shortcut.allCases {
            let value = storage.persistedObject(forKey: shortcut.key)
            if value == nil || value is [String: Any] { continue }

            guard
                let data = value as? Data,
                let legacy = try? NSKeyedUnarchiver.unarchivedObject(ofClass: MASShortcut.self, from: data)
            else {
                storage.removeObject(forKey: shortcut.key)
                continue
            }

            set(
                .custom(KeyCombination(keyCode: legacy.keyCode, rawModifierFlags: legacy.modifierFlags.rawValue)),
                for: shortcut
            )
        }
    }
}
