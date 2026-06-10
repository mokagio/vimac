//
//  UserPreferencesTests.swift
//  VimacTests
//

import XCTest
@testable import Vimac

// Coverage for the preference value rules and the scroll-key parsing. The
// validators are pure, so they are exercised directly. `readAsConfig()` reads
// `UserDefaults.standard`, so each test snapshots and restores that one key —
// that coupling to global state is itself a refactoring target these tests guard.
class UserPreferencesTests: XCTestCase {

    // MARK: - Hint characters: at least six, all distinct

    func test_hint_characters_below_minimum_length_are_invalid() {
        XCTAssertFalse(UserPreferences.HintMode.CustomCharactersProperty.isValid(value: "sadfj"))
    }

    func test_six_distinct_hint_characters_are_valid() {
        XCTAssertTrue(UserPreferences.HintMode.CustomCharactersProperty.isValid(value: "sadfjk"))
    }

    func test_repeated_hint_characters_are_invalid_even_at_length() {
        XCTAssertFalse(UserPreferences.HintMode.CustomCharactersProperty.isValid(value: "aabbcc"))
    }

    func test_default_hint_characters_are_valid() {
        XCTAssertTrue(UserPreferences.HintMode.CustomCharactersProperty.isValid(value: "sadfjklewcmpgh"))
    }

    func test_empty_hint_characters_are_invalid() {
        XCTAssertFalse(UserPreferences.HintMode.CustomCharactersProperty.isValid(value: ""))
    }

    // MARK: - Hint text size: a number in (0, 100]

    func test_text_size_within_range_is_valid() {
        XCTAssertTrue(UserPreferences.HintMode.TextSizeProperty.isValid(value: "11.0"))
    }

    func test_text_size_at_upper_bound_is_valid() {
        XCTAssertTrue(UserPreferences.HintMode.TextSizeProperty.isValid(value: "100"))
    }

    func test_text_size_of_zero_is_invalid() {
        XCTAssertFalse(UserPreferences.HintMode.TextSizeProperty.isValid(value: "0"))
    }

    func test_text_size_above_upper_bound_is_invalid() {
        XCTAssertFalse(UserPreferences.HintMode.TextSizeProperty.isValid(value: "100.1"))
    }

    func test_negative_text_size_is_invalid() {
        XCTAssertFalse(UserPreferences.HintMode.TextSizeProperty.isValid(value: "-5"))
    }

    func test_non_numeric_text_size_is_invalid() {
        XCTAssertFalse(UserPreferences.HintMode.TextSizeProperty.isValid(value: "abc"))
    }

    // MARK: - Scroll keys: 4, 6, or 8 distinct comma-separated sequences

    func test_four_scroll_sequences_are_valid() {
        XCTAssertTrue(UserPreferences.ScrollMode.ScrollKeysProperty.isValid(value: "h,j,k,l"))
    }

    func test_default_eight_scroll_sequences_are_valid() {
        XCTAssertTrue(UserPreferences.ScrollMode.ScrollKeysProperty.isValid(value: "h,j,k,l,d,u,G,gg"))
    }

    func test_odd_scroll_sequence_count_is_invalid() {
        XCTAssertFalse(UserPreferences.ScrollMode.ScrollKeysProperty.isValid(value: "h,j,k,l,d"))
    }

    func test_repeated_scroll_sequences_are_invalid() {
        XCTAssertFalse(UserPreferences.ScrollMode.ScrollKeysProperty.isValid(value: "h,j,k,j"))
    }

    // MARK: - Scroll sensitivity: 0...100

    func test_scroll_sensitivity_bounds_are_valid() {
        XCTAssertTrue(UserPreferences.ScrollMode.ScrollSensitivityProperty.isValid(value: 0))
        XCTAssertTrue(UserPreferences.ScrollMode.ScrollSensitivityProperty.isValid(value: 100))
    }

    func test_scroll_sensitivity_outside_bounds_is_invalid() {
        XCTAssertFalse(UserPreferences.ScrollMode.ScrollSensitivityProperty.isValid(value: -1))
        XCTAssertFalse(UserPreferences.ScrollMode.ScrollSensitivityProperty.isValid(value: 101))
    }

    // MARK: - readAsConfig() binding generation

    private let scrollKey = "ScrollCharacters"
    private var savedScrollKey: Any?

    override func setUp() {
        super.setUp()
        savedScrollKey = UserDefaults.standard.object(forKey: scrollKey)
    }

    override func tearDown() {
        UserDefaults.standard.set(savedScrollKey, forKey: scrollKey)
        super.tearDown()
    }

    private func readConfig(from value: String) -> ScrollKeyConfig {
        UserDefaults.standard.set(value, forKey: scrollKey)
        return UserPreferences.ScrollMode.ScrollKeysProperty.readAsConfig()
    }

    private func keys(_ config: ScrollKeyConfig, for direction: ScrollDirection) -> [[Character]] {
        config.bindings.filter { $0.direction == direction }.map { $0.keys }
    }

    func test_four_keys_yield_four_base_and_four_uppercase_half_bindings() {
        let config = readConfig(from: "a,b,c,d")

        XCTAssertEqual(config.bindings.count, 8)
        XCTAssertEqual(keys(config, for: .left), [["a"]])
        XCTAssertEqual(keys(config, for: .down), [["b"]])
        XCTAssertEqual(keys(config, for: .up), [["c"]])
        XCTAssertEqual(keys(config, for: .right), [["d"]])
        // Half-directions are derived from the uppercased base keys.
        XCTAssertEqual(keys(config, for: .halfLeft), [["A"]])
        XCTAssertEqual(keys(config, for: .halfDown), [["B"]])
        XCTAssertEqual(keys(config, for: .halfUp), [["C"]])
        XCTAssertEqual(keys(config, for: .halfRight), [["D"]])
    }

    func test_six_keys_add_explicit_half_down_and_half_up_bindings() {
        let config = readConfig(from: "a,b,c,d,e,f")

        XCTAssertEqual(config.bindings.count, 10)
        // Explicit half keys coexist with the uppercase-derived ones.
        XCTAssertEqual(Set(keys(config, for: .halfDown).map { String($0) }), ["B", "e"])
        XCTAssertEqual(Set(keys(config, for: .halfUp).map { String($0) }), ["C", "f"])
    }

    func test_eight_keys_add_bottom_and_top_bindings() {
        let config = readConfig(from: "a,b,c,d,e,f,g,hh")

        XCTAssertEqual(config.bindings.count, 12)
        XCTAssertEqual(keys(config, for: .bottom), [["g"]])
        XCTAssertEqual(keys(config, for: .top), [["h", "h"]])
    }

    func test_invalid_stored_value_falls_back_to_the_default_config() {
        // "x,y" is invalid (2 sequences), so read() returns the default and
        // readAsConfig() parses that — proving validation gates parsing.
        let config = readConfig(from: "x,y")

        XCTAssertEqual(config.bindings.count, 12)
        XCTAssertEqual(keys(config, for: .left), [["h"]])
        XCTAssertEqual(keys(config, for: .bottom), [["G"]])
        XCTAssertEqual(keys(config, for: .top), [["g", "g"]])
    }
}
