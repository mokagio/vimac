import ServiceManagement

enum LoginItemStatus: Equatable {
    case enabled
    case disabled
    /// Registered, but switched off by the user in System Settings. Only they
    /// can turn it back on, so the app can do nothing but point them there.
    case requiresApproval
    case unavailable

    var isEnabled: Bool { self == .enabled }
}

protocol LoginItemControlling {
    var status: LoginItemStatus { get }
    func setEnabled(_ enabled: Bool) throws
    func openSystemSettings()
}

/// Launch at login, via the app's own `SMAppService` registration.
struct LoginItem: LoginItemControlling {
    var status: LoginItemStatus {
        switch SMAppService.mainApp.status {
        case .enabled: return .enabled
        case .notRegistered: return .disabled
        case .requiresApproval: return .requiresApproval
        case .notFound: return .unavailable
        @unknown default: return .unavailable
        }
    }

    func setEnabled(_ enabled: Bool) throws {
        guard enabled else {
            // Unregistering something already unregistered raises rather than
            // no-ops, and there is nothing to report about it.
            guard SMAppService.mainApp.status != .notRegistered else { return }
            try SMAppService.mainApp.unregister()
            return
        }
        try SMAppService.mainApp.register()
    }

    func openSystemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
