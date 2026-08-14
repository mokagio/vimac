import Carbon
import Cocoa
import MASShortcut
import Testing
@testable import Vimac

@Suite("Shortcut setting")
struct ShortcutSettingTests {
    private let combination = KeyCombination(keyCode: kVK_ANSI_K, modifierFlags: .command)

    @Test("An absent value means the shortcut was never set")
    func absentIsUnset() {
        #expect(ShortcutSetting.decode(nil) == .unset)
    }

    @Test("An empty dictionary means the shortcut was cleared on purpose")
    func emptyDictionaryIsDisabled() {
        #expect(ShortcutSetting.decode([String: Any]()) == .disabled)
    }

    @Test("A key and modifiers decode to that combination")
    func dictionaryIsCustom() {
        let stored: [String: Any] = ["keyCode": kVK_ANSI_K, "modifierFlags": NSEvent.ModifierFlags.command.rawValue]

        #expect(ShortcutSetting.decode(stored) == .custom(combination))
    }

    @Test("A dictionary missing its parts is treated as never set")
    func malformedIsUnset() {
        #expect(ShortcutSetting.decode(["keyCode": 40]) == .unset)
    }

    @Test("Anything that is not a dictionary is treated as never set")
    func foreignValueIsUnset() {
        #expect(ShortcutSetting.decode(Data([0x01])) == .unset)
        #expect(ShortcutSetting.decode("ctrl-f") == .unset)
    }

    @Test("Each state encodes back to what it decoded from")
    func encodingRoundTrips() {
        #expect(ShortcutSetting.unset.storageValue == nil)
        #expect((ShortcutSetting.disabled.storageValue as? [String: Any])?.isEmpty == true)
        #expect(ShortcutSetting.decode(ShortcutSetting.custom(combination).storageValue) == .custom(combination))
    }

    // MARK: - Resolution

    private let fallback = KeyCombination(keyCode: kVK_ANSI_F, modifierFlags: .control)

    @Test("Never set runs on the default")
    func unsetResolvesToDefault() {
        #expect(ShortcutSetting.unset.resolved(default: fallback) == fallback)
    }

    @Test("Cleared on purpose runs on nothing — this is the whole point of the format")
    func disabledResolvesToNothing() {
        #expect(ShortcutSetting.disabled.resolved(default: fallback) == nil)
    }

    @Test("A custom combination runs on itself")
    func customResolvesToItself() {
        #expect(ShortcutSetting.custom(combination).resolved(default: fallback) == combination)
    }
}

@Suite("Shortcut store")
struct ShortcutStoreTests {
    private func makeStore(
        stored: [String: Any] = [:],
        registered: [String: Any] = [:]
    ) -> (ShortcutStore, InMemorySettingsStorage) {
        let storage = InMemorySettingsStorage(stored: stored, registered: registered)
        return (ShortcutStore(storage: storage), storage)
    }

    @Test("Defaults are the shortcuts Vimac has always shipped")
    func defaults() {
        #expect(ShortcutStore.Shortcut.hintMode.defaultCombination
            == KeyCombination(keyCode: kVK_ANSI_F, modifierFlags: .control))
        #expect(ShortcutStore.Shortcut.scrollMode.defaultCombination
            == KeyCombination(keyCode: kVK_ANSI_J, modifierFlags: .control))
        #expect(ShortcutStore.Shortcut.hintMode.key == "HintModeShortcut")
        #expect(ShortcutStore.Shortcut.scrollMode.key == "ScrollModeShortcut")
    }

    // The regression this fork exists for: `MASShortcutBinder` registers the
    // defaults, so a plain `object(forKey:)` answers with a shortcut for a key
    // nobody set. Reading past the registration domain is what keeps "never
    // set" and "set to the default" from collapsing into one state.
    @Test("A registered default does not make an untouched shortcut look custom")
    func registeredDefaultIsNotCustom() {
        let (store, _) = makeStore(registered: [
            "HintModeShortcut": ["keyCode": kVK_ANSI_F, "modifierFlags": NSEvent.ModifierFlags.control.rawValue]
        ])

        #expect(store.setting(for: .hintMode) == .unset)
        #expect(store.combination(for: .hintMode) == ShortcutStore.Shortcut.hintMode.defaultCombination)
    }

    @Test("A cleared shortcut stays cleared, even with the default registered")
    func clearedStaysCleared() {
        let (store, _) = makeStore(
            stored: ["HintModeShortcut": [String: Any]()],
            registered: [
                "HintModeShortcut": ["keyCode": kVK_ANSI_F, "modifierFlags": NSEvent.ModifierFlags.control.rawValue]
            ]
        )

        #expect(store.setting(for: .hintMode) == .disabled)
        #expect(store.combination(for: .hintMode) == nil)
    }

    @Test("Clearing then reading back reports no shortcut")
    func clearingPersists() {
        let (store, _) = makeStore()

        store.set(.disabled, for: .scrollMode)

        #expect(store.setting(for: .scrollMode) == .disabled)
        #expect(store.combination(for: .scrollMode) == nil)
    }

    @Test("Restoring the default removes the stored value entirely")
    func restoringDefaultRemovesTheKey() {
        let (store, storage) = makeStore()
        store.set(.disabled, for: .hintMode)

        store.set(.unset, for: .hintMode)

        #expect(storage.persistedObject(forKey: "HintModeShortcut") == nil)
        #expect(store.setting(for: .hintMode) == .unset)
    }

    @Test("A custom shortcut round trips")
    func customRoundTrips() {
        let (store, _) = makeStore()
        let combination = KeyCombination(keyCode: kVK_ANSI_K, modifierFlags: [.command, .shift])

        store.set(.custom(combination), for: .scrollMode)

        #expect(store.setting(for: .scrollMode) == .custom(combination))
        #expect(store.combination(for: .scrollMode) == combination)
    }

    // MARK: - Migration from the archived format

    @Test("Migration leaves a cleared shortcut alone")
    func migrationLeavesClearedAlone() {
        let (store, storage) = makeStore(stored: ["HintModeShortcut": [String: Any]()])

        store.migrateLegacyStorage()

        #expect(store.setting(for: .hintMode) == .disabled)
        #expect((storage.persistedObject(forKey: "HintModeShortcut") as? [String: Any])?.isEmpty == true)
    }

    @Test("Migration leaves an untouched shortcut absent")
    func migrationLeavesUnsetAbsent() {
        let (store, storage) = makeStore()

        store.migrateLegacyStorage()

        #expect(storage.persistedObject(forKey: "HintModeShortcut") == nil)
        #expect(storage.persistedObject(forKey: "ScrollModeShortcut") == nil)
    }

    @Test("Migration leaves an already-converted shortcut alone")
    func migrationLeavesDictionariesAlone() {
        let combination = KeyCombination(keyCode: kVK_ANSI_K, modifierFlags: .command)
        let (store, _) = makeStore(stored: ["ScrollModeShortcut": combination.dictionaryValue])

        store.migrateLegacyStorage()

        #expect(store.setting(for: .scrollMode) == .custom(combination))
    }

    @Test("An archived shortcut is converted rather than lost")
    func migrationConvertsArchives() throws {
        let archived = try NSKeyedArchiver.archivedData(
            withRootObject: MASShortcut(keyCode: Int(kVK_ANSI_F), modifierFlags: [.control]),
            requiringSecureCoding: true
        )
        let (store, _) = makeStore(stored: ["HintModeShortcut": archived])

        store.migrateLegacyStorage()

        #expect(store.setting(for: .hintMode)
            == .custom(KeyCombination(keyCode: kVK_ANSI_F, modifierFlags: .control)))
    }

    @Test("Data that will not unarchive is dropped instead of left to break reads")
    func migrationDropsCorruptData() {
        let (store, storage) = makeStore(stored: ["HintModeShortcut": Data([0xDE, 0xAD, 0xBE, 0xEF])])

        store.migrateLegacyStorage()

        #expect(storage.persistedObject(forKey: "HintModeShortcut") == nil)
        #expect(store.setting(for: .hintMode) == .unset)
    }
}
