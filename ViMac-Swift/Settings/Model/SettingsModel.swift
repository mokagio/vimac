import Foundation
import Observation

/// A keyboard layout offered by the "force layout" picker.
struct KeyboardLayout: Identifiable, Hashable {
    let id: String
    let name: String
}

/// Everything the settings screen shows and edits.
///
/// Every property writes straight through to storage, so there is no save
/// button and no draft state to reconcile. Values that fail their rules are
/// still stored — the field keeps what was typed and says what is wrong —
/// while readers fall back to the setting's default, exactly as they do for a
/// value that was never set.
@MainActor
@Observable
final class SettingsModel {
    private let store: SettingsStore
    private let shortcutStore: ShortcutStore
    private let loginItem: LoginItemControlling

    let keyboardLayouts: [KeyboardLayout]

    init(
        store: SettingsStore = AppSettings.store,
        shortcutStore: ShortcutStore = ShortcutStore(),
        loginItem: LoginItemControlling = LoginItem(),
        keyboardLayouts: [KeyboardLayout] = InputSourceManager.inputSources.map {
            KeyboardLayout(id: $0.id, name: $0.name)
        }
    ) {
        self.store = store
        self.shortcutStore = shortcutStore
        self.loginItem = loginItem
        self.keyboardLayouts = keyboardLayouts

        forcedKeyboardLayoutID = store.value(for: VimacSettings.forcedKeyboardLayout)

        holdSpaceForHintMode = store.value(for: VimacSettings.holdSpaceForHintMode)
        hintModeKeySequenceEnabled = store.value(for: VimacSettings.hintModeKeySequenceEnabled)
        hintModeKeySequence = store.value(for: VimacSettings.hintModeKeySequence)
        scrollModeKeySequenceEnabled = store.value(for: VimacSettings.scrollModeKeySequenceEnabled)
        scrollModeKeySequence = store.value(for: VimacSettings.scrollModeKeySequence)
        keySequenceResetDelay = store.storedValue(for: VimacSettings.keySequenceResetDelay) ?? ""

        hintCharacters = store.storedValue(for: VimacSettings.hintCharacters) ?? ""
        hintTextSize = store.storedValue(for: VimacSettings.hintTextSize) ?? ""

        scrollKeys = store.storedValue(for: VimacSettings.scrollKeys) ?? ""
        scrollSensitivity = Double(store.value(for: VimacSettings.scrollSensitivity))
        reverseHorizontalScroll = store.value(for: VimacSettings.reverseHorizontalScroll)
        reverseVerticalScroll = store.value(for: VimacSettings.reverseVerticalScroll)

        electronSupport = store.value(for: VimacSettings.electronSupport)
        emulateVoiceOver = store.value(for: VimacSettings.emulateVoiceOver)

        loginItemStatus = loginItem.status
        shortcutSettings = Dictionary(
            uniqueKeysWithValues: ShortcutStore.Shortcut.allCases.map { ($0, shortcutStore.setting(for: $0)) }
        )
    }

    /// Emptying a field is how the user asks for the default back, so it
    /// forgets the stored value rather than storing an empty one — which is
    /// also what leaves the placeholder showing the default on the next launch.
    private func write(_ value: String, to setting: Setting<String>) {
        if value.isEmpty {
            store.reset(setting)
        } else {
            store.setValue(value, for: setting)
        }
    }

    // MARK: - General

    var forcedKeyboardLayoutID: String {
        didSet { store.setValue(forcedKeyboardLayoutID, for: VimacSettings.forcedKeyboardLayout) }
    }

    private(set) var loginItemStatus: LoginItemStatus
    private(set) var loginItemFailure: String?

    var launchAtLogin: Bool {
        get { loginItemStatus.isEnabled }
        set {
            do {
                try loginItem.setEnabled(newValue)
                loginItemFailure = nil
            } catch {
                loginItemFailure = error.localizedDescription
            }
            loginItemStatus = loginItem.status
        }
    }

    func openLoginItemsSettings() {
        loginItem.openSystemSettings()
    }

    // MARK: - Activation

    var holdSpaceForHintMode: Bool {
        didSet { store.setValue(holdSpaceForHintMode, for: VimacSettings.holdSpaceForHintMode) }
    }

    var hintModeKeySequenceEnabled: Bool {
        didSet { store.setValue(hintModeKeySequenceEnabled, for: VimacSettings.hintModeKeySequenceEnabled) }
    }

    var hintModeKeySequence: String {
        didSet { store.setValue(hintModeKeySequence, for: VimacSettings.hintModeKeySequence) }
    }

    var scrollModeKeySequenceEnabled: Bool {
        didSet { store.setValue(scrollModeKeySequenceEnabled, for: VimacSettings.scrollModeKeySequenceEnabled) }
    }

    var scrollModeKeySequence: String {
        didSet { store.setValue(scrollModeKeySequence, for: VimacSettings.scrollModeKeySequence) }
    }

    var keySequenceResetDelay: String {
        didSet { write(keySequenceResetDelay, to: VimacSettings.keySequenceResetDelay) }
    }

    /// Only worth complaining about a sequence the listener is actually asked to use.
    var hintModeKeySequenceProblem: KeySequence.Problem? {
        hintModeKeySequenceEnabled ? KeySequence.problem(with: hintModeKeySequence) : nil
    }

    var scrollModeKeySequenceProblem: KeySequence.Problem? {
        scrollModeKeySequenceEnabled ? KeySequence.problem(with: scrollModeKeySequence) : nil
    }

    /// An empty field means "use the default", which is what the placeholder says.
    var keySequenceResetDelayProblem: ResetDelay.Problem? {
        keySequenceResetDelay.isEmpty ? nil : ResetDelay.problem(with: keySequenceResetDelay)
    }

    // MARK: - Shortcuts

    private(set) var shortcutSettings: [ShortcutStore.Shortcut: ShortcutSetting]

    func shortcutSetting(for shortcut: ShortcutStore.Shortcut) -> ShortcutSetting {
        shortcutSettings[shortcut] ?? .unset
    }

    /// Re-reads storage after the recorder has written to it.
    func refreshShortcuts() {
        shortcutSettings = Dictionary(
            uniqueKeysWithValues: ShortcutStore.Shortcut.allCases.map { ($0, shortcutStore.setting(for: $0)) }
        )
    }

    func restoreDefaultShortcut(_ shortcut: ShortcutStore.Shortcut) {
        shortcutStore.set(.unset, for: shortcut)
        refreshShortcuts()
    }

    // MARK: - Hint mode

    var hintCharacters: String {
        didSet { write(hintCharacters, to: VimacSettings.hintCharacters) }
    }

    var hintTextSize: String {
        didSet { write(hintTextSize, to: VimacSettings.hintTextSize) }
    }

    var hintCharactersProblem: HintCharacters.Problem? {
        hintCharacters.isEmpty ? nil : HintCharacters.problem(with: hintCharacters)
    }

    var hintTextSizeProblem: HintTextSize.Problem? {
        hintTextSize.isEmpty ? nil : HintTextSize.problem(with: hintTextSize)
    }

    // MARK: - Scroll mode

    var scrollKeys: String {
        didSet { write(scrollKeys, to: VimacSettings.scrollKeys) }
    }

    var scrollSensitivity: Double {
        didSet { store.setValue(Int(scrollSensitivity.rounded()), for: VimacSettings.scrollSensitivity) }
    }

    var reverseHorizontalScroll: Bool {
        didSet { store.setValue(reverseHorizontalScroll, for: VimacSettings.reverseHorizontalScroll) }
    }

    var reverseVerticalScroll: Bool {
        didSet { store.setValue(reverseVerticalScroll, for: VimacSettings.reverseVerticalScroll) }
    }

    var scrollKeysProblem: ScrollKeys.Problem? {
        scrollKeys.isEmpty ? nil : ScrollKeys.problem(with: scrollKeys)
    }

    /// The role each typed sequence fills, so the format line reads against
    /// what is in the field rather than against an abstract template.
    var scrollKeyRoles: [ScrollKeys.RoleAssignment] {
        scrollKeysProblem == nil && !scrollKeys.isEmpty
            ? ScrollKeys.roleAssignments(in: scrollKeys)
            : ScrollKeys.roleAssignments(in: ScrollKeys.defaultValue)
    }

    // MARK: - Experimental

    var electronSupport: Bool {
        didSet { store.setValue(electronSupport, for: VimacSettings.electronSupport) }
    }

    var emulateVoiceOver: Bool {
        didSet { store.setValue(emulateVoiceOver, for: VimacSettings.emulateVoiceOver) }
    }
}
