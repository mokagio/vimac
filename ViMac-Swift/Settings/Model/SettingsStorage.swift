import Foundation

/// The slice of `UserDefaults` the settings layer touches, so tests can drive
/// the model off an in-memory double instead of a real suite.
protocol SettingsStorage: AnyObject {
    func object(forKey key: String) -> Any?

    /// What was actually written for `key`, ignoring the registration domain.
    ///
    /// `MASShortcutBinder` registers the default shortcuts, so a plain read
    /// answers with a shortcut even for a key nobody ever set — which is the
    /// exact distinction `ShortcutSetting` exists to keep.
    func persistedObject(forKey key: String) -> Any?

    func set(_ value: Any?, forKey key: String)
    func removeObject(forKey key: String)
}

final class UserDefaultsStorage: SettingsStorage {
    static let standard = UserDefaultsStorage()

    private let defaults: UserDefaults
    private let domainName: String

    init(defaults: UserDefaults = .standard, domainName: String = Bundle.main.bundleIdentifier ?? "") {
        self.defaults = defaults
        self.domainName = domainName
    }

    func object(forKey key: String) -> Any? {
        defaults.object(forKey: key)
    }

    func persistedObject(forKey key: String) -> Any? {
        defaults.persistentDomain(forName: domainName)?[key]
    }

    func set(_ value: Any?, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    func removeObject(forKey key: String) {
        defaults.removeObject(forKey: key)
    }
}
