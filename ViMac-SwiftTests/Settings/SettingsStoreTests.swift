import Testing
@testable import Vimac

@Suite("Settings store")
struct SettingsStoreTests {
    private let evenNumbers = Setting(key: "even", default: 0, validator: { $0.isMultiple(of: 2) })

    @Test("An unset setting reads as its default")
    func unsetReadsDefault() {
        let store = SettingsStore(storage: InMemorySettingsStorage())

        #expect(store.value(for: evenNumbers) == 0)
        #expect(store.storedValue(for: evenNumbers) == nil)
    }

    @Test("A stored value round trips")
    func roundTrip() {
        let store = SettingsStore(storage: InMemorySettingsStorage())

        store.setValue(4, for: evenNumbers)

        #expect(store.value(for: evenNumbers) == 4)
        #expect(store.storedValue(for: evenNumbers) == 4)
    }

    @Test("A stored value that fails the rule reads as the default")
    func invalidReadsDefault() {
        let store = SettingsStore(storage: InMemorySettingsStorage())

        store.setValue(3, for: evenNumbers)

        #expect(store.value(for: evenNumbers) == 0)
    }

    @Test("An invalid value is still kept, so the field it came from does not lose it")
    func invalidIsStillStored() {
        let store = SettingsStore(storage: InMemorySettingsStorage())

        store.setValue(3, for: evenNumbers)

        #expect(store.storedValue(for: evenNumbers) == 3)
    }

    @Test("A value of the wrong type reads as the default")
    func wrongTypeReadsDefault() {
        let store = SettingsStore(storage: InMemorySettingsStorage(stored: ["even": "banana"]))

        #expect(store.value(for: evenNumbers) == 0)
        #expect(store.storedValue(for: evenNumbers) == nil)
    }

    @Test("Resetting forgets the stored value")
    func reset() {
        let storage = InMemorySettingsStorage()
        let store = SettingsStore(storage: storage)

        store.setValue(4, for: evenNumbers)
        store.reset(evenNumbers)

        #expect(store.storedValue(for: evenNumbers) == nil)
        #expect(store.value(for: evenNumbers) == 0)
    }

    @Test("Every shipped setting keeps its own default usable")
    func shippedDefaultsAreValid() {
        #expect(HintCharacters.isValid(VimacSettings.hintCharacters.defaultValue))
        #expect(HintTextSize.isValid(VimacSettings.hintTextSize.defaultValue))
        #expect(ScrollKeys.isValid(VimacSettings.scrollKeys.defaultValue))
        #expect(ScrollSensitivity.isValid(VimacSettings.scrollSensitivity.defaultValue))
        #expect(ResetDelay.isValid(VimacSettings.keySequenceResetDelay.defaultValue))
    }

    @Test("Setting keys are the ones earlier versions wrote")
    func keysAreStable() {
        #expect(VimacSettings.hintCharacters.key == "HintCharacters")
        #expect(VimacSettings.hintTextSize.key == "HintTextSize")
        #expect(VimacSettings.scrollKeys.key == "ScrollCharacters")
        #expect(VimacSettings.scrollSensitivity.key == "ScrollSensitivity")
        #expect(VimacSettings.reverseHorizontalScroll.key == "IsHorizontalScrollReversed")
        #expect(VimacSettings.reverseVerticalScroll.key == "IsVerticalScrollReversed")
        #expect(VimacSettings.holdSpaceForHintMode.key == "holdSpaceHintModeActivationEnabled")
        #expect(VimacSettings.hintModeKeySequenceEnabled.key == "keySequenceHintModeEnabled")
        #expect(VimacSettings.hintModeKeySequence.key == "keySequenceHintMode")
        #expect(VimacSettings.scrollModeKeySequenceEnabled.key == "keySequenceScrollModeEnabled")
        #expect(VimacSettings.scrollModeKeySequence.key == "keySequenceScrollMode")
        #expect(VimacSettings.keySequenceResetDelay.key == "keySequenceResetDelay")
        #expect(VimacSettings.forcedKeyboardLayout.key == "ForceKeyboardLayout")
        #expect(VimacSettings.electronSupport.key == "AXManualAccessibilityEnabled")
        #expect(VimacSettings.emulateVoiceOver.key == "AXEnhancedUserInterfaceEnabled")
    }
}
