//
//  AlphabetHintsTests.swift
//  VimacTests
//

import XCTest
@testable import Vimac

class AlphabetHintsTests: XCTestCase {
    private let subject = AlphabetHints()

    func test_zero_links_yields_empty_hints() {
        XCTAssertEqual(subject.hintStrings(linkCount: 0, hintCharacters: "abc"), [])
    }

    func test_single_link_uses_a_single_character() {
        let hints = subject.hintStrings(linkCount: 1, hintCharacters: "abc")
        XCTAssertEqual(hints.count, 1)
        XCTAssertEqual(hints.first?.count, 1)
    }

    func test_hints_fit_within_alphabet_size_when_count_matches() {
        let hints = subject.hintStrings(linkCount: 3, hintCharacters: "abc")
        XCTAssertEqual(Set(hints), Set(["A", "B", "C"]))
    }

    func test_no_hint_is_a_prefix_of_another() {
        // The correctness invariant: typing one hint must not be ambiguous
        // with another. The algorithm avoids this by consuming shorter hints
        // before emitting longer ones, but the property is easier to assert
        // than the algorithm.
        let hints = subject.hintStrings(linkCount: 200, hintCharacters: "asdfghjkl")
        for h in hints {
            for other in hints where other != h {
                XCTAssertFalse(other.hasPrefix(h), "'\(h)' is a prefix of '\(other)'")
            }
        }
    }

    func test_hints_are_unique() {
        let hints = subject.hintStrings(linkCount: 50, hintCharacters: "asdfghjkl")
        XCTAssertEqual(Set(hints).count, hints.count)
    }

    func test_hints_are_uppercased() {
        let hints = subject.hintStrings(linkCount: 5, hintCharacters: "asdfg")
        XCTAssertTrue(hints.allSatisfy { $0 == $0.uppercased() })
    }

    func test_hints_use_only_supplied_characters() {
        let alphabet = "asdfghjkl"
        let allowed = Set(alphabet.uppercased())
        let hints = subject.hintStrings(linkCount: 100, hintCharacters: alphabet)
        for hint in hints {
            for ch in hint {
                XCTAssertTrue(allowed.contains(ch), "hint '\(hint)' contains '\(ch)' outside alphabet")
            }
        }
    }

    func test_handles_count_larger_than_alphabet_squared() {
        // 3-char alphabet: 3 + 9 = 12 unique hints up to length 2; 100 forces
        // length 3 combinations.
        let hints = subject.hintStrings(linkCount: 100, hintCharacters: "abc")
        XCTAssertEqual(hints.count, 100)
        XCTAssertEqual(Set(hints).count, 100)
    }
}
