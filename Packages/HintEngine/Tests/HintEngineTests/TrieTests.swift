import Testing
@testable import HintEngine

@Suite("Trie")
struct TrieTests {
    @Test("A word is contained once added")
    func containsAddedWord() {
        let trie = Trie()

        #expect(!trie.contains(Array("abc")))

        trie.addWord(Array("abc"))

        #expect(trie.contains(Array("abc")))
    }

    @Test("A prefix of an added word is not itself contained")
    func doesNotContainPrefix() {
        let trie = Trie()

        trie.addWord(Array("abc"))

        #expect(!trie.contains(Array("ab")))
    }

    @Test("A prefix of an added word is a prefix", arguments: ["ab", "abc", ""])
    func isPrefix(word: String) {
        let trie = Trie()

        trie.addWord(Array("abc"))

        #expect(trie.isPrefix(Array(word)))
    }

    @Test("Anything the added word does not begin with is not a prefix", arguments: ["x", "abcd"])
    func isNotPrefix(word: String) {
        let trie = Trie()

        trie.addWord(Array("abc"))

        #expect(!trie.isPrefix(Array(word)))
    }

    @Test("A word is prefixed by a shorter added word")
    func prefixWordExists() {
        let trie = Trie()

        trie.addWord(Array("ab"))

        #expect(trie.doesPrefixWordExist(Array("abcd")))
    }

    @Test("A word that diverges from every added word is prefixed by none")
    func prefixWordDoesNotExist() {
        let trie = Trie()

        trie.addWord(Array("abc"))

        #expect(!trie.doesPrefixWordExist(Array("abd")))
    }

    @Test("A word is prefixed by itself")
    func wordPrefixesItself() {
        let trie = Trie()

        trie.addWord(Array("abd"))

        #expect(trie.doesPrefixWordExist(Array("abd")))
    }
}
