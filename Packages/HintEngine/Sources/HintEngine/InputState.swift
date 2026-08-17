//
//  InputState.swift
//  HintEngine
//
//  Created by Dexter Leng on 8/11/20.
//  Copyright © 2020 Dexter Leng. All rights reserved.
//

/// Resolves keystrokes, one character at a time, against a set of registered
/// words — hint labels in hint mode, key sequences in scroll mode.
///
/// Registration and matching are separate phases: every word must be added
/// before the first `advance(_:)`, and `resetInput()` returns to the start of
/// the word set without forgetting it.
public final class InputState {
    public enum State {
        /// Nothing registered yet — no keystroke can be resolved.
        case initialized
        /// Words registered, waiting on the first keystroke.
        case wordsAdded
        /// Typed so far is a prefix of at least one word.
        case advancable
        /// Typed so far matches no word; only `resetInput()` moves on.
        case deadend
        /// Typed so far is a whole word, available from `matchedWord()`.
        case matched
    }

    public enum StateMachineError: Error {
        case invalidTransition
    }

    private var trie: Trie
    private var currentTrieNode: TrieNode
    public private(set) var state: State

    public init() {
        self.trie = Trie()
        self.currentTrieNode = trie.root
        self.state = .initialized
    }

    /// Registers a word, unless it would be ambiguous with one already
    /// registered — a prefix of one, or prefixed by one.
    ///
    /// - Returns: whether the word was registered.
    @discardableResult
    public func addWord(_ word: [Character]) throws -> Bool {
        if state != .initialized && state != .wordsAdded {
            throw StateMachineError.invalidTransition
        }

        if self.trie.isPrefix(word) || self.trie.doesPrefixWordExist(word) {
            return false
        }

        self.trie.addWord(word)
        self.state = .wordsAdded
        return true
    }

    public func advance(_ c: Character) throws {
        if state != .advancable && state != .wordsAdded {
            throw StateMachineError.invalidTransition
        }

        guard let newCurrentTrieNode = self.currentTrieNode.getChild(c: c) else {
            self.state = .deadend
            return
        }

        self.currentTrieNode = newCurrentTrieNode

        if self.currentTrieNode.isTerminating() {
            assert(self.currentTrieNode.getChildren().count == 0)
            self.state = .matched
            return
        }

        self.state = .advancable
    }

    public func matchedWord() throws -> [Character] {
        if state != .matched {
            throw StateMachineError.invalidTransition
        }
        return typed()
    }

    private func typed() -> [Character] {
        var seqRev: [Character] = []
        var s: TrieNode? = self.currentTrieNode
        while s != nil {
            seqRev.append(s!.character)
            s = s!.parent
        }
        // pop root node's garbage character
        _ = seqRev.popLast()
        return seqRev.reversed()
    }

    public func resetInput() {
        self.currentTrieNode = self.trie.root
        self.state = .wordsAdded
    }
}
