import Foundation

/// A sequence of characters that activates a mode when typed in quick
/// succession, e.g. "fd".
enum KeySequence {
    /// `VimacKeySequenceListener` drops sequences of one character, so a single
    /// key here is dead config rather than a hair trigger.
    static let minimumCount = 2

    enum Problem: Equatable {
        case empty
        case tooShort(minimum: Int)
        case containsWhitespace

        var message: String {
            switch self {
            case .empty:
                return "Enter a sequence, or turn this off."
            case .tooShort(let minimum):
                return "Enter at least \(minimum) characters — shorter sequences are ignored."
            case .containsWhitespace:
                return "Spaces cannot be part of a sequence."
            }
        }
    }

    static func problem(with value: String) -> Problem? {
        if value.isEmpty { return .empty }
        if value.contains(where: \.isWhitespace) { return .containsWhitespace }
        if value.count < minimumCount { return .tooShort(minimum: minimumCount) }
        return nil
    }

    static func isValid(_ value: String) -> Bool { problem(with: value) == nil }
}

/// How long the key-sequence listener waits before forgetting a partial match.
enum ResetDelay {
    static let defaultValue = "0.25"

    enum Problem: Equatable {
        case notANumber
        case notPositive

        var message: String {
            switch self {
            case .notANumber:
                return "Enter a number of seconds."
            case .notPositive:
                return "Enter a delay above 0."
            }
        }
    }

    static func problem(with value: String) -> Problem? {
        guard let delay = Double(value) else { return .notANumber }
        guard delay > 0 else { return .notPositive }
        return nil
    }

    static func isValid(_ value: String) -> Bool { problem(with: value) == nil }

    static func seconds(from value: String) -> TimeInterval {
        Double(isValid(value) ? value : defaultValue)!
    }
}
