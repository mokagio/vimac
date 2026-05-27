//
//  HintModeInputIntentTests.swift
//  VimacTests
//

import XCTest
import Carbon
@testable import Vimac

class HintModeInputIntentTests: XCTestCase {

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

    func test_escape_maps_to_exit() {
        let intent = HintModeInputIntent.from(event: keyDown(chars: "", keyCode: kVK_Escape))
        XCTAssertEqual(intent, .exit)
    }

    func test_control_left_bracket_maps_to_exit() {
        let intent = HintModeInputIntent.from(event: keyDown(
            chars: "[",
            keyCode: kVK_ANSI_LeftBracket,
            modifiers: [.control]
        ))
        XCTAssertEqual(intent, .exit)
    }

    func test_left_bracket_without_control_does_not_exit() {
        let intent = HintModeInputIntent.from(event: keyDown(
            chars: "[",
            keyCode: kVK_ANSI_LeftBracket
        ))
        if case .exit = intent { XCTFail("should not be .exit") }
    }

    func test_delete_maps_to_backspace() {
        let intent = HintModeInputIntent.from(event: keyDown(chars: "", keyCode: kVK_Delete))
        XCTAssertEqual(intent, .backspace)
    }

    func test_space_maps_to_rotate() {
        let intent = HintModeInputIntent.from(event: keyDown(chars: " ", keyCode: kVK_Space))
        XCTAssertEqual(intent, .rotate)
    }

    func test_plain_letter_advances_with_left_click() {
        let intent = HintModeInputIntent.from(event: keyDown(chars: "a", keyCode: kVK_ANSI_A))
        guard case let .advance(by, action) = intent else {
            return XCTFail("expected .advance, got \(String(describing: intent))")
        }
        XCTAssertEqual(by, "a")
        XCTAssertEqual(action, .leftClick)
    }

    func test_shift_modifier_advances_with_right_click() {
        let intent = HintModeInputIntent.from(event: keyDown(chars: "a", keyCode: kVK_ANSI_A, modifiers: [.shift]))
        guard case let .advance(_, action) = intent else { return XCTFail() }
        XCTAssertEqual(action, .rightClick)
    }

    func test_command_modifier_advances_with_double_left_click() {
        let intent = HintModeInputIntent.from(event: keyDown(chars: "a", keyCode: kVK_ANSI_A, modifiers: [.command]))
        guard case let .advance(_, action) = intent else { return XCTFail() }
        XCTAssertEqual(action, .doubleLeftClick)
    }

    func test_option_modifier_advances_with_move() {
        let intent = HintModeInputIntent.from(event: keyDown(chars: "a", keyCode: kVK_ANSI_A, modifiers: [.option]))
        guard case let .advance(_, action) = intent else { return XCTFail() }
        XCTAssertEqual(action, .move)
    }

    func test_non_keydown_event_yields_nil() {
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
        XCTAssertNil(HintModeInputIntent.from(event: mouseEvent))
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
