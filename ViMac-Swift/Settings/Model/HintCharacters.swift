import Foundation

/// The alphabet hint labels are drawn from.
enum HintCharacters {
    static let defaultValue = "sadfjklewcmpgh"
    static let minimumCount = 6

    enum Problem: Equatable {
        case tooShort(minimum: Int)
        case repeatedCharacters([Character])

        var message: String {
            switch self {
            case .tooShort(let minimum):
                return "Enter at least \(minimum) characters."
            case .repeatedCharacters(let characters):
                let list = characters.map { "\"\($0)\"" }.joined(separator: ", ")
                return "Each character must appear once. Repeated: \(list)."
            }
        }
    }

    static func problem(with value: String) -> Problem? {
        let repeats = repeatedCharacters(in: value)
        if !repeats.isEmpty {
            return .repeatedCharacters(repeats)
        }
        if value.count < minimumCount {
            return .tooShort(minimum: minimumCount)
        }
        return nil
    }

    static func isValid(_ value: String) -> Bool { problem(with: value) == nil }

    /// Repeated characters in the order they first appear, so the message reads
    /// left to right against what the user typed.
    private static func repeatedCharacters(in value: String) -> [Character] {
        var seen: Set<Character> = []
        var reported: Set<Character> = []
        var repeats: [Character] = []
        for character in value {
            if seen.contains(character), !reported.contains(character) {
                repeats.append(character)
                reported.insert(character)
            }
            seen.insert(character)
        }
        return repeats
    }
}
