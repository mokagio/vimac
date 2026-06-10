//
//  ScrollModeInputStateTests.swift
//  VimacTests
//

import XCTest
@testable import Vimac

class ScrollModeInputStateTests: XCTestCase {
    private var subject: ScrollModeInputState!

    override func setUp() {
        super.setUp()
        subject = ScrollModeInputState()
    }

    private func register(_ keys: String, _ direction: ScrollDirection) {
        _ = try! subject.registerBinding(binding: ScrollKeyConfig.Binding(
            keys: Array(keys),
            direction: direction
        ))
    }

    func test_single_key_match_resolves_direction() {
        register("j", .down)

        guard case let .match(direction) = try! subject.advance(key: "j") else {
            return XCTFail("expected .match")
        }
        XCTAssertEqual(direction, .down)
    }

    func test_unknown_key_is_a_deadend() {
        register("j", .down)
        register("k", .up)

        if case .deadend = try! subject.advance(key: "x") {
            // ok
        } else {
            XCTFail("expected .deadend for unbound key")
        }
    }

    func test_partial_prefix_is_advancable_then_resolves() {
        register("gg", .top)
        register("gj", .down)

        if case .advancable = try! subject.advance(key: "g") {
            // ok
        } else {
            XCTFail("expected .advancable after first key of multi-char binding")
        }

        guard case let .match(direction) = try! subject.advance(key: "g") else {
            return XCTFail("expected .match after completing binding")
        }
        XCTAssertEqual(direction, .top)
    }

    func test_distinct_multi_key_bindings_resolve_independently() {
        register("gg", .top)
        register("GG", .bottom)

        _ = try! subject.advance(key: "G")
        guard case let .match(direction) = try! subject.advance(key: "G") else {
            return XCTFail("expected .match")
        }
        XCTAssertEqual(direction, .bottom)
    }

    func test_duplicate_binding_registration_is_rejected() {
        let first = try! subject.registerBinding(binding: ScrollKeyConfig.Binding(
            keys: Array("j"),
            direction: .down
        ))
        XCTAssertTrue(first)

        let second = try! subject.registerBinding(binding: ScrollKeyConfig.Binding(
            keys: Array("j"),
            direction: .up
        ))
        XCTAssertFalse(second)
    }
}
