//
//  ScrollModeInputListenerTests.swift
//  VimacTests
//

import XCTest
@testable import Vimac

// `doesEventMatchBinding` decides whether a key event triggers a scroll binding.
// The contract is a plain character-string equality against the binding's keys;
// these tests pin that down (including the multi-key and case-sensitive cases)
// so the matching can be reimplemented without silently changing behaviour.
class ScrollModeInputListenerTests: XCTestCase {

    private func keyDown(_ characters: String) -> NSEvent {
        NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: characters,
            charactersIgnoringModifiers: characters,
            isARepeat: false,
            keyCode: 0
        )!
    }

    private func binding(_ keys: String, _ direction: ScrollDirection = .down) -> ScrollKeyConfig.Binding {
        ScrollKeyConfig.Binding(keys: Array(keys), direction: direction)
    }

    func test_single_character_match() {
        XCTAssertTrue(
            ScrollModeInputListener.doesEventMatchBinding(event: keyDown("j"), binding: binding("j"))
        )
    }

    func test_single_character_mismatch() {
        XCTAssertFalse(
            ScrollModeInputListener.doesEventMatchBinding(event: keyDown("k"), binding: binding("j"))
        )
    }

    func test_multi_character_sequence_match() {
        XCTAssertTrue(
            ScrollModeInputListener.doesEventMatchBinding(event: keyDown("gg"), binding: binding("gg"))
        )
    }

    func test_partial_sequence_does_not_match() {
        XCTAssertFalse(
            ScrollModeInputListener.doesEventMatchBinding(event: keyDown("g"), binding: binding("gg"))
        )
    }

    func test_matching_is_case_sensitive() {
        XCTAssertFalse(
            ScrollModeInputListener.doesEventMatchBinding(event: keyDown("g"), binding: binding("G"))
        )
        XCTAssertTrue(
            ScrollModeInputListener.doesEventMatchBinding(event: keyDown("G"), binding: binding("G"))
        )
    }
}
