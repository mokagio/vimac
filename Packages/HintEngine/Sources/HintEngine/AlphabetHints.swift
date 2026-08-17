//
//  AlphabetHints.swift
//  HintEngine
//
//  Created by Dexter Leng on 12/9/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

/// Labels for the actionable elements of a window, drawn from a user-chosen
/// alphabet.
///
/// The algorithm is Vimium's:
/// https://github.com/philc/vimium/blob/881a6fdc3644f55fc02ad56454203f654cc76618/content_scripts/link_hints.coffee#L434
public enum AlphabetHints {
    /// Uppercased labels, one per element, none of them a prefix of another —
    /// so typing a label is never ambiguous.
    public static func hintStrings(linkCount: Int, hintCharacters: String) -> [String] {
        if linkCount == 0 {
            return []
        }

        var hints = [""]
        var offset = 0
        while hints.count - offset < linkCount || hints.count == 1 {
            let hint = hints[offset]
            offset += 1
            for allowedCharacter in hintCharacters {
                hints.append(String(allowedCharacter) + hint)
            }
        }
        return Array(hints[offset...offset+linkCount-1]).sorted().map { String($0.reversed()) }.map { $0.uppercased() }
    }
}
