//
//  ScrollModeInputListenerTests.swift
//  VimacTests
//

import Cocoa
import Testing
@testable import Vimac

// `doesEventMatchBinding` decides whether a key event triggers a scroll binding.
// The contract is a plain character-string equality against the binding's keys;
// these tests pin that down (including the multi-key and case-sensitive cases)
// so the matching can be reimplemented without silently changing behaviour.
@Suite("Scroll mode input listener")
struct ScrollModeInputListenerTests {
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

    @Test("A key matches the binding bound to it")
    func singleCharacterMatch() {
        #expect(ScrollModeInputListener.doesEventMatchBinding(event: keyDown("j"), binding: binding("j")))
    }

    @Test("A key does not match a binding bound to another")
    func singleCharacterMismatch() {
        #expect(!ScrollModeInputListener.doesEventMatchBinding(event: keyDown("k"), binding: binding("j")))
    }

    @Test("A multi-character sequence matches the binding bound to it")
    func multiCharacterMatch() {
        #expect(ScrollModeInputListener.doesEventMatchBinding(event: keyDown("gg"), binding: binding("gg")))
    }

    @Test("Part of a sequence does not match the whole binding")
    func partialSequence() {
        #expect(!ScrollModeInputListener.doesEventMatchBinding(event: keyDown("g"), binding: binding("gg")))
    }

    @Test("Matching is case sensitive")
    func caseSensitive() {
        #expect(!ScrollModeInputListener.doesEventMatchBinding(event: keyDown("g"), binding: binding("G")))
        #expect(ScrollModeInputListener.doesEventMatchBinding(event: keyDown("G"), binding: binding("G")))
    }
}
