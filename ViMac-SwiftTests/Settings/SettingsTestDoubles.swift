import Foundation
@testable import Vimac

/// Stands in for `UserDefaults`, keeping written values apart from registered
/// ones so tests can prove which of the two a reader consults.
final class InMemorySettingsStorage: SettingsStorage, @unchecked Sendable {
    private var stored: [String: Any]
    private var registered: [String: Any]

    init(stored: [String: Any] = [:], registered: [String: Any] = [:]) {
        self.stored = stored
        self.registered = registered
    }

    func object(forKey key: String) -> Any? {
        stored[key] ?? registered[key]
    }

    func persistedObject(forKey key: String) -> Any? {
        stored[key]
    }

    func set(_ value: Any?, forKey key: String) {
        stored[key] = value
    }

    func removeObject(forKey key: String) {
        stored[key] = nil
    }

    func register(_ value: Any, forKey key: String) {
        registered[key] = value
    }
}

final class FakeLoginItem: LoginItemControlling, @unchecked Sendable {
    struct Failure: Error, LocalizedError {
        let errorDescription: String? = "Registration was refused."
    }

    var status: LoginItemStatus
    var failureOnNextChange: Error?
    private(set) var openedSystemSettings = false

    init(status: LoginItemStatus = .disabled) {
        self.status = status
    }

    func setEnabled(_ enabled: Bool) throws {
        if let failureOnNextChange {
            self.failureOnNextChange = nil
            throw failureOnNextChange
        }
        status = enabled ? .enabled : .disabled
    }

    func openSystemSettings() {
        openedSystemSettings = true
    }
}
