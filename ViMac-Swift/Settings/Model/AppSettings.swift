import Foundation
import RxCocoa
import RxSwift

/// What the running app reads. Every accessor resolves through `SettingsStore`,
/// so an unusable stored value falls back to the setting's default rather than
/// reaching the modes.
enum AppSettings {
    static let store = SettingsStore()

    // MARK: - Hint mode

    static var hintCharacters: String {
        store.value(for: VimacSettings.hintCharacters)
    }

    static var hintTextSize: Double {
        HintTextSize.points(from: store.value(for: VimacSettings.hintTextSize))
    }

    // MARK: - Scroll mode

    static var scrollKeyConfig: ScrollKeyConfig {
        ScrollKeys.config(from: store.value(for: VimacSettings.scrollKeys))
    }

    static var scrollSensitivity: Int {
        store.value(for: VimacSettings.scrollSensitivity)
    }

    static var isHorizontalScrollReversed: Bool {
        store.value(for: VimacSettings.reverseHorizontalScroll)
    }

    static var isVerticalScrollReversed: Bool {
        store.value(for: VimacSettings.reverseVerticalScroll)
    }
}

extension Setting {
    /// Emits the setting's current value, then again on every change.
    func observe(_ defaults: UserDefaults = .standard) -> Observable<Value> {
        defaults.rx.observe(Any.self, key).map { stored in
            guard let stored, let value = Value.decodeSetting(stored), isValid(value) else {
                return defaultValue
            }
            return value
        }
    }
}
