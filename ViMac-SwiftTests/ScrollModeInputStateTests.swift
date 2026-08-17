//
//  ScrollModeInputStateTests.swift
//  VimacTests
//

import Testing
@testable import Vimac

@Suite("Scroll mode input state")
struct ScrollModeInputStateTests {
    private let subject = ScrollModeInputState()

    private func register(_ keys: String, _ direction: ScrollDirection) throws {
        _ = try subject.registerBinding(binding: ScrollKeyConfig.Binding(
            keys: Array(keys),
            direction: direction
        ))
    }

    @Test("A single key resolves to the direction bound to it")
    func singleKeyMatch() throws {
        try register("j", .down)

        guard case let .match(direction) = try subject.advance(key: "j") else {
            Issue.record("expected .match")
            return
        }
        #expect(direction == .down)
    }

    @Test("An unbound key is a deadend")
    func unknownKey() throws {
        try register("j", .down)
        try register("k", .up)

        guard case .deadend = try subject.advance(key: "x") else {
            Issue.record("expected .deadend for unbound key")
            return
        }
    }

    @Test("The first key of a multi-key binding advances, the last resolves")
    func partialPrefix() throws {
        try register("gg", .top)
        try register("gj", .down)

        guard case .advancable = try subject.advance(key: "g") else {
            Issue.record("expected .advancable after first key of multi-char binding")
            return
        }
        guard case let .match(direction) = try subject.advance(key: "g") else {
            Issue.record("expected .match after completing binding")
            return
        }
        #expect(direction == .top)
    }

    @Test("Bindings differing only in case resolve apart")
    func caseDistinguishesBindings() throws {
        try register("gg", .top)
        try register("GG", .bottom)

        _ = try subject.advance(key: "G")

        guard case let .match(direction) = try subject.advance(key: "G") else {
            Issue.record("expected .match")
            return
        }
        #expect(direction == .bottom)
    }

    @Test("Keys already bound cannot be bound again")
    func duplicateRegistration() throws {
        let first = try subject.registerBinding(binding: ScrollKeyConfig.Binding(
            keys: Array("j"),
            direction: .down
        ))
        let second = try subject.registerBinding(binding: ScrollKeyConfig.Binding(
            keys: Array("j"),
            direction: .up
        ))

        #expect(first)
        #expect(!second)
    }
}
