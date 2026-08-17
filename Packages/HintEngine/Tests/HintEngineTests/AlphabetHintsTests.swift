import Testing
import HintEngine

@Suite("Alphabet hints")
struct AlphabetHintsTests {
    @Test("No elements need no hints")
    func zeroLinks() {
        #expect(AlphabetHints.hintStrings(linkCount: 0, hintCharacters: "abc") == [])
    }

    @Test("A single element gets a single-character hint")
    func singleLink() {
        let hints = AlphabetHints.hintStrings(linkCount: 1, hintCharacters: "abc")

        #expect(hints.count == 1)
        #expect(hints.first?.count == 1)
    }

    @Test("As many elements as characters exhausts the alphabet")
    func alphabetSized() {
        #expect(Set(AlphabetHints.hintStrings(linkCount: 3, hintCharacters: "abc")) == ["A", "B", "C"])
    }

    @Test("No hint is a prefix of another")
    func unambiguous() {
        // The correctness invariant: typing one hint must not be ambiguous
        // with another. The algorithm avoids this by consuming shorter hints
        // before emitting longer ones, but the property is easier to assert
        // than the algorithm.
        let hints = AlphabetHints.hintStrings(linkCount: 200, hintCharacters: "asdfghjkl")

        for hint in hints {
            for other in hints where other != hint {
                #expect(!other.hasPrefix(hint), "'\(hint)' is a prefix of '\(other)'")
            }
        }
    }

    @Test("Hints are unique")
    func unique() {
        let hints = AlphabetHints.hintStrings(linkCount: 50, hintCharacters: "asdfghjkl")

        #expect(Set(hints).count == hints.count)
    }

    @Test("Hints are uppercased")
    func uppercased() {
        let hints = AlphabetHints.hintStrings(linkCount: 5, hintCharacters: "asdfg")

        #expect(hints.allSatisfy { $0 == $0.uppercased() })
    }

    @Test("Hints use only the supplied characters")
    func withinAlphabet() {
        let alphabet = "asdfghjkl"
        let allowed = Set(alphabet.uppercased())
        let hints = AlphabetHints.hintStrings(linkCount: 100, hintCharacters: alphabet)

        for hint in hints {
            for character in hint {
                #expect(allowed.contains(character), "hint '\(hint)' contains '\(character)' outside alphabet")
            }
        }
    }

    @Test("More elements than the alphabet squared still gets one hint each")
    func beyondTwoCharacters() {
        // 3-char alphabet: 3 + 9 = 12 unique hints up to length 2; 100 forces
        // length 3 combinations.
        let hints = AlphabetHints.hintStrings(linkCount: 100, hintCharacters: "abc")

        #expect(hints.count == 100)
        #expect(Set(hints).count == 100)
    }
}
