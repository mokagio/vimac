//
//  KeyboardShortcutsTests.swift
//  VimacTests
//

import XCTest
import MASShortcut
@testable import Vimac

class KeyboardShortcutsTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var subject: KeyboardShortcuts!

    override func setUp() {
        super.setUp()
        suiteName = "vimac.tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        subject = KeyboardShortcuts(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        subject = nil
        suiteName = nil
        super.tearDown()
    }

    // Read straight from the suite's persistent domain so registered defaults
    // (set globally by MASShortcutBinder when the host app initialised) don't
    // mask a key that's actually absent from our test suite.
    private func storedValue(forKey key: String) -> Any? {
        defaults.persistentDomain(forName: suiteName)?[key]
    }

    // Regression: explicitly cleared shortcuts must not be repopulated by the
    // migration path. MASDictionaryTransformer encodes "cleared" as an empty
    // dictionary; if the migration touches it the bug returns.
    func test_cleared_shortcut_stays_cleared() {
        defaults.set([String: Any](), forKey: subject.hintModeShortcutKey)

        subject.migrateLegacyShortcutStorage()

        let stored = storedValue(forKey: subject.hintModeShortcutKey) as? [String: Any]
        XCTAssertNotNil(stored)
        XCTAssertTrue(stored!.isEmpty)
    }

    func test_unset_shortcut_remains_absent() {
        subject.migrateLegacyShortcutStorage()

        XCTAssertNil(storedValue(forKey: subject.hintModeShortcutKey))
        XCTAssertNil(storedValue(forKey: subject.scrollModeShortcutKey))
    }

    func test_existing_dictionary_shortcut_preserved() {
        let custom: [String: Any] = [
            "keyCode": Int(kVK_ANSI_K),
            "modifierFlags": NSEvent.ModifierFlags.command.rawValue,
        ]
        defaults.set(custom, forKey: subject.scrollModeShortcutKey)

        subject.migrateLegacyShortcutStorage()

        let stored = storedValue(forKey: subject.scrollModeShortcutKey) as? [String: Any]
        XCTAssertEqual(stored?["keyCode"] as? Int, custom["keyCode"] as? Int)
        XCTAssertEqual(stored?["modifierFlags"] as? UInt, custom["modifierFlags"] as? UInt)
    }

    func test_legacy_nskeyedarchive_migrated_to_dictionary() throws {
        let shortcut = MASShortcut(keyCode: Int(kVK_ANSI_F), modifierFlags: [.control])!
        let archived = try NSKeyedArchiver.archivedData(
            withRootObject: shortcut,
            requiringSecureCoding: true
        )
        defaults.set(archived, forKey: subject.hintModeShortcutKey)

        subject.migrateLegacyShortcutStorage()

        let stored = storedValue(forKey: subject.hintModeShortcutKey) as? [String: Any]
        XCTAssertEqual(stored?["keyCode"] as? Int, Int(kVK_ANSI_F))
        XCTAssertEqual(stored?["modifierFlags"] as? UInt, NSEvent.ModifierFlags.control.rawValue)
    }

    func test_corrupt_legacy_data_is_removed() {
        let garbage = Data([0xDE, 0xAD, 0xBE, 0xEF])
        defaults.set(garbage, forKey: subject.hintModeShortcutKey)

        subject.migrateLegacyShortcutStorage()

        XCTAssertNil(storedValue(forKey: subject.hintModeShortcutKey))
    }
}
