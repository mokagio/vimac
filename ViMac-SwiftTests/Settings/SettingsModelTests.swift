import Carbon
import Cocoa
import Testing
@testable import Vimac

@MainActor
@Suite("Settings model")
struct SettingsModelTests {
    private func makeModel(
        stored: [String: Any] = [:],
        loginItem: FakeLoginItem = FakeLoginItem()
    ) -> (SettingsModel, InMemorySettingsStorage) {
        let storage = InMemorySettingsStorage(stored: stored)
        let model = SettingsModel(
            store: SettingsStore(storage: storage),
            shortcutStore: ShortcutStore(storage: storage),
            loginItem: loginItem,
            keyboardLayouts: [KeyboardLayout(id: "com.apple.keylayout.ABC", name: "ABC")]
        )
        return (model, storage)
    }

    // MARK: - Loading

    @Test("A fresh install shows the shipped defaults")
    func freshInstall() {
        let (model, _) = makeModel()

        #expect(model.holdSpaceForHintMode)
        #expect(!model.hintModeKeySequenceEnabled)
        #expect(model.scrollSensitivity == 20)
        #expect(!model.reverseVerticalScroll)
        #expect(model.forcedKeyboardLayoutID == "")
    }

    // Text fields show what is stored, not the resolved value, so an empty
    // field can mean "use the default" and show the default as a placeholder.
    @Test("Text fields start empty when nothing was ever stored")
    func textFieldsStartEmpty() {
        let (model, _) = makeModel()

        #expect(model.hintCharacters == "")
        #expect(model.hintTextSize == "")
        #expect(model.scrollKeys == "")
        #expect(model.keySequenceResetDelay == "")
    }

    @Test("Stored values are loaded into their fields")
    func loadsStoredValues() {
        let (model, _) = makeModel(stored: [
            "HintCharacters": "qwerty",
            "ScrollCharacters": "a,b,c,d",
            "ScrollSensitivity": 75,
            "IsVerticalScrollReversed": true,
        ])

        #expect(model.hintCharacters == "qwerty")
        #expect(model.scrollKeys == "a,b,c,d")
        #expect(model.scrollSensitivity == 75)
        #expect(model.reverseVerticalScroll)
    }

    @Test("Loading does not write anything back")
    func loadingDoesNotWrite() {
        let (_, storage) = makeModel()

        #expect(storage.persistedObject(forKey: "HintCharacters") == nil)
        #expect(storage.persistedObject(forKey: "holdSpaceHintModeActivationEnabled") == nil)
    }

    // MARK: - Writing through

    @Test("Editing a field stores it straight away")
    func editsArePersisted() {
        let (model, storage) = makeModel()

        model.hintCharacters = "qwertyui"
        model.hintTextSize = "14"
        model.scrollKeys = "a,b,c,d"
        model.scrollSensitivity = 60
        model.reverseHorizontalScroll = true
        model.holdSpaceForHintMode = false
        model.hintModeKeySequenceEnabled = true
        model.hintModeKeySequence = "fd"
        model.electronSupport = true
        model.forcedKeyboardLayoutID = "com.apple.keylayout.ABC"

        #expect(storage.persistedObject(forKey: "HintCharacters") as? String == "qwertyui")
        #expect(storage.persistedObject(forKey: "HintTextSize") as? String == "14")
        #expect(storage.persistedObject(forKey: "ScrollCharacters") as? String == "a,b,c,d")
        #expect(storage.persistedObject(forKey: "ScrollSensitivity") as? Int == 60)
        #expect(storage.persistedObject(forKey: "IsHorizontalScrollReversed") as? Bool == true)
        #expect(storage.persistedObject(forKey: "holdSpaceHintModeActivationEnabled") as? Bool == false)
        #expect(storage.persistedObject(forKey: "keySequenceHintModeEnabled") as? Bool == true)
        #expect(storage.persistedObject(forKey: "keySequenceHintMode") as? String == "fd")
        #expect(storage.persistedObject(forKey: "AXManualAccessibilityEnabled") as? Bool == true)
        #expect(storage.persistedObject(forKey: "ForceKeyboardLayout") as? String == "com.apple.keylayout.ABC")
    }

    @Test("Sensitivity is stored as a whole number")
    func sensitivityIsRounded() {
        let (model, storage) = makeModel()

        model.scrollSensitivity = 42.7

        #expect(storage.persistedObject(forKey: "ScrollSensitivity") as? Int == 43)
    }

    @Test("A value that fails its rule is kept, so nothing typed is thrown away")
    func invalidValuesAreKept() {
        let (model, storage) = makeModel()

        model.hintCharacters = "aa"

        #expect(storage.persistedObject(forKey: "HintCharacters") as? String == "aa")
    }

    @Test("A value that fails its rule does not reach the app")
    func invalidValuesDoNotReachTheApp() {
        let (model, storage) = makeModel()
        let store = SettingsStore(storage: storage)

        model.hintCharacters = "aa"

        #expect(store.value(for: VimacSettings.hintCharacters) == HintCharacters.defaultValue)
    }

    // MARK: - Problems

    @Test("An empty field is not a complaint — it means use the default")
    func emptyIsNotAProblem() {
        let (model, _) = makeModel()

        #expect(model.hintCharactersProblem == nil)
        #expect(model.hintTextSizeProblem == nil)
        #expect(model.scrollKeysProblem == nil)
        #expect(model.keySequenceResetDelayProblem == nil)
    }

    @Test("Problems surface once a field holds something unusable")
    func problemsSurface() {
        let (model, _) = makeModel()

        model.hintCharacters = "aa"
        model.hintTextSize = "1000"
        model.scrollKeys = "h,j"
        model.keySequenceResetDelay = "soon"

        #expect(model.hintCharactersProblem == .repeatedCharacters(["a"]))
        #expect(model.hintTextSizeProblem == .outOfRange(maximum: 100))
        #expect(model.scrollKeysProblem == .wrongCount(2))
        #expect(model.keySequenceResetDelayProblem == .notANumber)
    }

    @Test("A key sequence is only complained about while it is switched on")
    func keySequenceProblemsFollowTheToggle() {
        let (model, _) = makeModel()
        model.hintModeKeySequence = "f"

        #expect(model.hintModeKeySequenceProblem == nil)

        model.hintModeKeySequenceEnabled = true

        #expect(model.hintModeKeySequenceProblem == .tooShort(minimum: 2))
    }

    @Test("The role legend falls back to the default while the field is unusable")
    func roleLegendFallsBack() {
        let (model, _) = makeModel()

        model.scrollKeys = "a,b,c,d"
        #expect(model.scrollKeyRoles.map(\.sequence) == ["a", "b", "c", "d"])

        model.scrollKeys = "a,b"
        #expect(model.scrollKeyRoles.map(\.sequence) == ["h", "j", "k", "l", "d", "u", "G", "gg"])
    }

    // MARK: - Shortcuts

    @Test("An untouched shortcut reads as never set")
    func shortcutStartsUnset() {
        let (model, _) = makeModel()

        #expect(model.shortcutSetting(for: .hintMode) == .unset)
    }

    @Test("Restoring the default puts a cleared shortcut back to never set")
    func restoringDefault() {
        let (model, storage) = makeModel(stored: ["HintModeShortcut": [String: Any]()])
        #expect(model.shortcutSetting(for: .hintMode) == .disabled)

        model.restoreDefaultShortcut(.hintMode)

        #expect(model.shortcutSetting(for: .hintMode) == .unset)
        #expect(storage.persistedObject(forKey: "HintModeShortcut") == nil)
    }

    @Test("Refreshing picks up what the recorder wrote behind the model's back")
    func refreshPicksUpExternalWrites() {
        let (model, storage) = makeModel()

        storage.set([String: Any](), forKey: "ScrollModeShortcut")
        #expect(model.shortcutSetting(for: .scrollMode) == .unset)

        model.refreshShortcuts()

        #expect(model.shortcutSetting(for: .scrollMode) == .disabled)
    }

    // MARK: - Launch at login

    @Test("Turning launch at login on registers the app")
    func launchAtLoginOn() {
        let loginItem = FakeLoginItem()
        let (model, _) = makeModel(loginItem: loginItem)

        model.launchAtLogin = true

        #expect(model.launchAtLogin)
        #expect(loginItem.status == .enabled)
        #expect(model.loginItemFailure == nil)
    }

    @Test("A refused registration is reported and leaves the toggle off")
    func launchAtLoginFailure() {
        let loginItem = FakeLoginItem()
        loginItem.failureOnNextChange = FakeLoginItem.Failure()
        let (model, _) = makeModel(loginItem: loginItem)

        model.launchAtLogin = true

        #expect(!model.launchAtLogin)
        #expect(model.loginItemFailure == "Registration was refused.")
    }

    @Test("A later success clears the earlier complaint")
    func launchAtLoginRecovers() {
        let loginItem = FakeLoginItem()
        loginItem.failureOnNextChange = FakeLoginItem.Failure()
        let (model, _) = makeModel(loginItem: loginItem)
        model.launchAtLogin = true

        model.launchAtLogin = true

        #expect(model.launchAtLogin)
        #expect(model.loginItemFailure == nil)
    }

    @Test("Approval withheld in System Settings reads as off")
    func launchAtLoginRequiresApproval() {
        let (model, _) = makeModel(loginItem: FakeLoginItem(status: .requiresApproval))

        #expect(!model.launchAtLogin)
        #expect(model.loginItemStatus == .requiresApproval)
    }
}
