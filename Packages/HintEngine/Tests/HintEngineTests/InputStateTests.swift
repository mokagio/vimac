import Testing
@testable import HintEngine

@Suite("Input state")
struct InputStateTests {
    // MARK: - Registration

    @Test("A duplicate word is rejected")
    func duplicate() throws {
        let inputState = InputState()

        #expect(try inputState.addWord(Array("abc")))
        #expect(try !inputState.addWord(Array("abc")))
    }

    @Test("A word that prefixes a registered one is rejected")
    func prefixOfRegistered() throws {
        let inputState = InputState()

        #expect(try inputState.addWord(Array("abc")))
        #expect(try !inputState.addWord(Array("ab")))
    }

    @Test("A word prefixed by a registered one is rejected")
    func prefixedByRegistered() throws {
        let inputState = InputState()

        #expect(try inputState.addWord(Array("ab")))
        #expect(try !inputState.addWord(Array("abcd")))
    }

    @Test("Words sharing a prefix are accepted while they end apart")
    func commonPrefix() throws {
        let inputState = InputState()

        #expect(try inputState.addWord(Array("gg")))
        #expect(try inputState.addWord(Array("gi")))
    }

    // MARK: - Matching

    @Test("Registering a word readies the matcher")
    func wordsAdded() throws {
        let inputState = InputState()
        #expect(inputState.state == .initialized)

        try inputState.addWord(Array("abcd"))

        #expect(inputState.state == .wordsAdded)
    }

    @Test("Advancing before any word is registered is rejected")
    func advanceBeforeRegistration() {
        let inputState = InputState()

        #expect(throws: InputState.StateMachineError.invalidTransition) {
            try inputState.advance("c")
        }
    }

    @Test("A keystroke no word begins with is a deadend")
    func deadend() throws {
        let inputState = InputState()
        try inputState.addWord(Array("abcd"))

        try inputState.advance("c")

        #expect(inputState.state == .deadend)
    }

    @Test("A keystroke a word begins with advances")
    func advancable() throws {
        let inputState = InputState()
        try inputState.addWord(Array("abcd"))

        try inputState.advance("a")

        #expect(inputState.state == .advancable)
    }

    @Test("The matcher stays advancable until the last keystroke of a word")
    func matchOnLastKeystroke() throws {
        let inputState = InputState()
        try inputState.addWord(Array("abcd"))

        for c in "abc" {
            try inputState.advance(c)
            #expect(inputState.state == .advancable)
        }
        try inputState.advance("d")

        #expect(inputState.state == .matched)
    }

    @Test("The matched word is what was typed")
    func matchedWord() throws {
        let inputState = InputState()
        try inputState.addWord(Array("gg"))
        try inputState.addWord(Array("gi"))

        try inputState.advance("g")
        try inputState.advance("i")

        #expect(inputState.state == .matched)
        #expect(try inputState.matchedWord() == Array("gi"))
    }

    @Test("Asking for a match before there is one is rejected")
    func matchedWordBeforeMatch() throws {
        let inputState = InputState()
        try inputState.addWord(Array("abcd"))
        try inputState.advance("a")

        #expect(throws: InputState.StateMachineError.invalidTransition) {
            try inputState.matchedWord()
        }
    }

    @Test("Resetting returns to the start of the word set, keeping the words")
    func reset() throws {
        let inputState = InputState()
        try inputState.addWord(Array("abcd"))
        try inputState.advance("c")
        #expect(inputState.state == .deadend)

        inputState.resetInput()

        #expect(inputState.state == .wordsAdded)
        try inputState.advance("a")
        #expect(inputState.state == .advancable)
    }
}
