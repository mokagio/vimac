//
//  HintModeInputIntentTests.swift
//  VimacTests
//

import Carbon
import Cocoa
import Testing
@testable import Vimac

@Suite("Hint mode input intent")
struct HintModeInputIntentTests {
    private func keyDown(
        chars: String,
        keyCode: Int,
        modifiers: NSEvent.ModifierFlags = []
    ) -> NSEvent {
        NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: modifiers,
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: chars,
            charactersIgnoringModifiers: chars,
            isARepeat: false,
            keyCode: UInt16(keyCode)
        )!
    }

    @Test("Escape exits")
    func escape() {
        #expect(HintModeInputIntent.from(event: keyDown(chars: "", keyCode: kVK_Escape)) == .exit)
    }

    @Test("Control-[ exits")
    func controlLeftBracket() {
        let intent = HintModeInputIntent.from(event: keyDown(
            chars: "[",
            keyCode: kVK_ANSI_LeftBracket,
            modifiers: [.control]
        ))

        #expect(intent == .exit)
    }

    @Test("[ on its own does not exit")
    func leftBracketWithoutControl() {
        let intent = HintModeInputIntent.from(event: keyDown(
            chars: "[",
            keyCode: kVK_ANSI_LeftBracket
        ))

        #expect(intent != .exit)
    }

    @Test("Delete backspaces")
    func delete() {
        #expect(HintModeInputIntent.from(event: keyDown(chars: "", keyCode: kVK_Delete)) == .backspace)
    }

    @Test("Space rotates")
    func space() {
        #expect(HintModeInputIntent.from(event: keyDown(chars: " ", keyCode: kVK_Space)) == .rotate)
    }

    @Test("A plain letter advances the hint text, clicking on match")
    func plainLetter() throws {
        let intent = HintModeInputIntent.from(event: keyDown(chars: "a", keyCode: kVK_ANSI_A))

        let advance = try #require(intent)
        #expect(advance == .advance(by: "a", action: .leftClick))
    }

    @Test("A modifier picks the action a match performs", arguments: [
        (NSEvent.ModifierFlags.shift, HintAction.rightClick),
        (.command, .doubleLeftClick),
        (.option, .move),
    ])
    func modifierAction(modifier: NSEvent.ModifierFlags, expected: HintAction) throws {
        let intent = HintModeInputIntent.from(event: keyDown(chars: "a", keyCode: kVK_ANSI_A, modifiers: modifier))

        guard case let .advance(_, action) = try #require(intent) else {
            Issue.record("expected .advance, got \(String(describing: intent))")
            return
        }
        #expect(action == expected)
    }

    @Test("An event that is not a keystroke means nothing")
    func nonKeyDownEvent() {
        let mouseEvent = NSEvent.mouseEvent(
            with: .leftMouseDown,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            eventNumber: 0,
            clickCount: 1,
            pressure: 1
        )!

        #expect(HintModeInputIntent.from(event: mouseEvent) == nil)
    }
}

extension HintModeInputIntent: Equatable {
    public static func == (lhs: HintModeInputIntent, rhs: HintModeInputIntent) -> Bool {
        switch (lhs, rhs) {
        case (.exit, .exit), (.rotate, .rotate), (.backspace, .backspace):
            return true
        case let (.advance(lBy, lAction), .advance(rBy, rAction)):
            return lBy == rBy && lAction == rAction
        default:
            return false
        }
    }
}
