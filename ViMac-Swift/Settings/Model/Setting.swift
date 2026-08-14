import Foundation

/// A type that survives a round trip through a property list.
protocol SettingValue {
    static func decodeSetting(_ stored: Any) -> Self?
    var settingStorageValue: Any { get }
}

extension Bool: SettingValue {
    static func decodeSetting(_ stored: Any) -> Bool? { stored as? Bool }
    var settingStorageValue: Any { self }
}

extension Int: SettingValue {
    static func decodeSetting(_ stored: Any) -> Int? { stored as? Int }
    var settingStorageValue: Any { self }
}

extension String: SettingValue {
    static func decodeSetting(_ stored: Any) -> String? { stored as? String }
    var settingStorageValue: Any { self }
}

/// Everything the app knows about one preference: where it lives, what it falls
/// back to, and what counts as a usable value.
struct Setting<Value: SettingValue> {
    let key: String
    let defaultValue: Value

    private let validator: (Value) -> Bool

    init(key: String, default defaultValue: Value, validator: @escaping (Value) -> Bool = { _ in true }) {
        self.key = key
        self.defaultValue = defaultValue
        self.validator = validator
    }

    func isValid(_ value: Value) -> Bool { validator(value) }
}

/// Reads and writes `Setting` values, falling back to the default whenever what
/// is stored is missing, of the wrong type, or fails the setting's own rules.
struct SettingsStore {
    private let storage: SettingsStorage

    init(storage: SettingsStorage = UserDefaultsStorage.standard) {
        self.storage = storage
    }

    /// What is actually stored, whether or not it is usable. The settings UI
    /// edits this so a half-typed value is not swapped out from under the field.
    func storedValue<Value>(for setting: Setting<Value>) -> Value? {
        storage.object(forKey: setting.key).flatMap(Value.decodeSetting)
    }

    /// The value the rest of the app acts on.
    func value<Value>(for setting: Setting<Value>) -> Value {
        guard let stored = storedValue(for: setting), setting.isValid(stored) else {
            return setting.defaultValue
        }
        return stored
    }

    func setValue<Value>(_ value: Value, for setting: Setting<Value>) {
        storage.set(value.settingStorageValue, forKey: setting.key)
    }

    /// Forgets the stored value, so the setting reads as its default again.
    func reset<Value>(_ setting: Setting<Value>) {
        storage.removeObject(forKey: setting.key)
    }
}
