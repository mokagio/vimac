import Carbon
import Cocoa

/// A key and its modifiers, in the shape `MASDictionaryTransformer` stores.
struct KeyCombination: Equatable {
    let keyCode: Int
    let modifierFlags: UInt

    init(keyCode: Int, modifierFlags: NSEvent.ModifierFlags) {
        self.init(keyCode: keyCode, rawModifierFlags: modifierFlags.rawValue)
    }

    init(keyCode: Int, rawModifierFlags: UInt) {
        self.keyCode = keyCode
        self.modifierFlags = rawModifierFlags
    }

    var dictionaryValue: [String: Any] {
        ["keyCode": keyCode, "modifierFlags": modifierFlags]
    }

    static func decode(_ dictionary: [String: Any]) -> KeyCombination? {
        guard
            let keyCode = dictionary["keyCode"] as? Int,
            let modifierFlags = dictionary["modifierFlags"] as? UInt
        else { return nil }
        return KeyCombination(keyCode: keyCode, rawModifierFlags: modifierFlags)
    }
}

/// The three states a shortcut can be in, which is the distinction the whole
/// storage format exists to preserve.
///
/// `NSUserDefaults.registerDefaults` only fills keys that are absent, so
/// "cleared" has to be a value rather than the absence of one. An
/// `NSKeyedArchive` cannot express that — a cleared shortcut and one that was
/// never set both archive to nil, and the default gets re-applied on next
/// launch. `MASDictionaryTransformer` writes an empty dictionary for cleared
/// and leaves the key absent for never-set, which keeps the two apart.
enum ShortcutSetting: Equatable {
    /// No stored value: the shortcut runs on its default.
    case unset
    /// Stored as an empty dictionary: the user cleared it and wants no shortcut.
    case disabled
    /// Stored as a key and modifiers.
    case custom(KeyCombination)

    static func decode(_ stored: Any?) -> ShortcutSetting {
        guard let dictionary = stored as? [String: Any] else { return .unset }
        if dictionary.isEmpty { return .disabled }
        guard let combination = KeyCombination.decode(dictionary) else { return .unset }
        return .custom(combination)
    }

    /// What to write to storage, or nil to remove the key entirely.
    var storageValue: Any? {
        switch self {
        case .unset: return nil
        case .disabled: return [String: Any]()
        case .custom(let combination): return combination.dictionaryValue
        }
    }

    /// The combination this state resolves to, given the shortcut's default.
    func resolved(default defaultCombination: KeyCombination) -> KeyCombination? {
        switch self {
        case .unset: return defaultCombination
        case .disabled: return nil
        case .custom(let combination): return combination
        }
    }
}
