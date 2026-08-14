import Testing
@testable import Vimac

@Suite("Hint characters")
struct HintCharactersTests {
    @Test("Six distinct characters are enough")
    func sixDistinct() {
        #expect(HintCharacters.problem(with: "sadfjk") == nil)
    }

    @Test("The shipped default is usable")
    func defaultIsUsable() {
        #expect(HintCharacters.problem(with: HintCharacters.defaultValue) == nil)
    }

    @Test("Fewer than six is too short", arguments: ["", "s", "sadfj"])
    func tooShort(value: String) {
        #expect(HintCharacters.problem(with: value) == .tooShort(minimum: 6))
    }

    @Test("A repeated character is rejected however long the string")
    func repeatsRejected() {
        #expect(HintCharacters.problem(with: "aabbcc") == .repeatedCharacters(["a", "b", "c"]))
    }

    @Test("Repeats are reported once each, in the order they first repeat")
    func repeatsReportedOnce() {
        #expect(HintCharacters.problem(with: "abcabca") == .repeatedCharacters(["a", "b", "c"]))
    }

    @Test("A repeat is reported ahead of the length, since it is the sharper complaint")
    func repeatBeatsLength() {
        #expect(HintCharacters.problem(with: "aa") == .repeatedCharacters(["a"]))
    }

    @Test("The message names the repeated characters")
    func messageNamesRepeats() {
        let message = HintCharacters.Problem.repeatedCharacters(["a", "b"]).message
        #expect(message.contains("\"a\""))
        #expect(message.contains("\"b\""))
    }
}

@Suite("Hint text size")
struct HintTextSizeTests {
    @Test("Sizes inside the range are accepted", arguments: ["11.0", "0.5", "100", "1"])
    func accepted(value: String) {
        #expect(HintTextSize.problem(with: value) == nil)
    }

    @Test("Zero and below are out of range", arguments: ["0", "-5"])
    func nonPositive(value: String) {
        #expect(HintTextSize.problem(with: value) == .outOfRange(maximum: 100))
    }

    @Test("Above the maximum is out of range")
    func tooLarge() {
        #expect(HintTextSize.problem(with: "100.1") == .outOfRange(maximum: 100))
    }

    @Test("Text that is not a number is called out as such", arguments: ["abc", "", "11pt"])
    func notANumber(value: String) {
        #expect(HintTextSize.problem(with: value) == .notANumber)
    }

    @Test("An unusable size resolves to the default")
    func unusableResolvesToDefault() {
        #expect(HintTextSize.points(from: "abc") == 11)
        #expect(HintTextSize.points(from: "0") == 11)
    }

    @Test("A usable size resolves to itself")
    func usableResolvesToItself() {
        #expect(HintTextSize.points(from: "18.5") == 18.5)
    }
}

@Suite("Key sequences")
struct KeySequenceTests {
    @Test("Two or more characters are fine", arguments: ["fd", "jk", "abc"])
    func accepted(value: String) {
        #expect(KeySequence.problem(with: value) == nil)
    }

    @Test("An empty sequence asks to be filled in or turned off")
    func empty() {
        #expect(KeySequence.problem(with: "") == .empty)
    }

    @Test("A single character is flagged, because the listener drops it")
    func single() {
        #expect(KeySequence.problem(with: "f") == .tooShort(minimum: 2))
    }

    @Test("Whitespace is flagged ahead of length")
    func whitespace() {
        #expect(KeySequence.problem(with: "f d") == .containsWhitespace)
        #expect(KeySequence.problem(with: " ") == .containsWhitespace)
    }
}

@Suite("Reset delay")
struct ResetDelayTests {
    @Test("A positive number of seconds is fine", arguments: ["0.25", "1", "0.001"])
    func accepted(value: String) {
        #expect(ResetDelay.problem(with: value) == nil)
    }

    @Test("Zero and below are rejected", arguments: ["0", "-1"])
    func nonPositive(value: String) {
        #expect(ResetDelay.problem(with: value) == .notPositive)
    }

    @Test("Text that is not a number is called out as such", arguments: ["", "soon"])
    func notANumber(value: String) {
        #expect(ResetDelay.problem(with: value) == .notANumber)
    }

    @Test("An unusable delay resolves to the default")
    func unusableResolvesToDefault() {
        #expect(ResetDelay.seconds(from: "") == 0.25)
        #expect(ResetDelay.seconds(from: "-3") == 0.25)
    }

    @Test("A usable delay resolves to itself")
    func usableResolvesToItself() {
        #expect(ResetDelay.seconds(from: "0.5") == 0.5)
    }
}
