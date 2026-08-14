import Foundation

/// Every preference Vimac stores, in one place: its `UserDefaults` key, its
/// default, and the rule that decides whether a stored value is usable.
///
/// The keys are the ones earlier versions wrote, so upgrading keeps a user's
/// configuration.
enum VimacSettings {

    // MARK: - General

    /// Empty means "do not force a layout".
    static let forcedKeyboardLayout = Setting(key: "ForceKeyboardLayout", default: "")

    // MARK: - Activation

    static let holdSpaceForHintMode = Setting(key: "holdSpaceHintModeActivationEnabled", default: true)

    static let hintModeKeySequenceEnabled = Setting(key: "keySequenceHintModeEnabled", default: false)
    static let scrollModeKeySequenceEnabled = Setting(key: "keySequenceScrollModeEnabled", default: false)

    // Deliberately unvalidated: the listener already ignores sequences it
    // cannot use, and rejecting them here would discard what the user typed.
    static let hintModeKeySequence = Setting(key: "keySequenceHintMode", default: "")
    static let scrollModeKeySequence = Setting(key: "keySequenceScrollMode", default: "")

    static let keySequenceResetDelay = Setting(
        key: "keySequenceResetDelay",
        default: ResetDelay.defaultValue,
        validator: ResetDelay.isValid
    )

    // MARK: - Hint mode

    static let hintCharacters = Setting(
        key: "HintCharacters",
        default: HintCharacters.defaultValue,
        validator: HintCharacters.isValid
    )

    static let hintTextSize = Setting(
        key: "HintTextSize",
        default: HintTextSize.defaultValue,
        validator: HintTextSize.isValid
    )

    // MARK: - Scroll mode

    static let scrollKeys = Setting(
        key: "ScrollCharacters",
        default: ScrollKeys.defaultValue,
        validator: ScrollKeys.isValid
    )

    static let scrollSensitivity = Setting(
        key: "ScrollSensitivity",
        default: ScrollSensitivity.defaultValue,
        validator: ScrollSensitivity.isValid
    )

    static let reverseHorizontalScroll = Setting(key: "IsHorizontalScrollReversed", default: false)
    static let reverseVerticalScroll = Setting(key: "IsVerticalScrollReversed", default: false)

    // MARK: - Experimental

    static let electronSupport = Setting(key: "AXManualAccessibilityEnabled", default: false)
    static let emulateVoiceOver = Setting(key: "AXEnhancedUserInterfaceEnabled", default: false)
}
