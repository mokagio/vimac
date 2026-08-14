import Foundation

/// The comma-separated key sequences that drive scroll mode.
///
/// Four sequences cover the cardinal directions; six add explicit half-page
/// down and up; eight add jump-to-bottom and jump-to-top. Half-page bindings
/// for all four directions also exist implicitly as the uppercased base keys.
enum ScrollKeys {
    static let defaultValue = "h,j,k,l,d,u,G,gg"
    static let allowedCounts = [4, 6, 8]

    /// In the order the sequences are read, longest form first.
    static let roleNames = ["left", "down", "up", "right", "half-down", "half-up", "bottom", "top"]

    enum Problem: Equatable {
        case wrongCount(Int)
        case emptySequence
        case duplicateSequences([String])

        var message: String {
            switch self {
            case .wrongCount:
                return "Enter 4, 6, or 8 comma-separated sequences."
            case .emptySequence:
                return "Every sequence needs at least one key."
            case .duplicateSequences(let sequences):
                let list = sequences.map { "\"\($0)\"" }.joined(separator: ", ")
                return "Each sequence must be distinct. Repeated: \(list)."
            }
        }
    }

    static func problem(with value: String) -> Problem? {
        let sequences = self.sequences(in: value)

        if !allowedCounts.contains(sequences.count) {
            return .wrongCount(sequences.count)
        }
        if sequences.contains(where: \.isEmpty) {
            return .emptySequence
        }

        let duplicates = duplicateSequences(in: sequences)
        if !duplicates.isEmpty {
            return .duplicateSequences(duplicates)
        }
        return nil
    }

    static func isValid(_ value: String) -> Bool { problem(with: value) == nil }

    static func sequences(in value: String) -> [String] {
        value.components(separatedBy: ",")
    }

    /// What one typed sequence scrolls.
    struct RoleAssignment: Identifiable, Equatable {
        let role: String
        let sequence: String

        var id: String { role }
    }

    /// The roles each sequence in `value` fills, for labelling the field.
    static func roleAssignments(in value: String) -> [RoleAssignment] {
        zip(roleNames, sequences(in: value)).map { RoleAssignment(role: $0, sequence: $1) }
    }

    static func config(from value: String) -> ScrollKeyConfig {
        let sequences = self.sequences(in: isValid(value) ? value : defaultValue)
        let (left, down, up, right) = (sequences[0], sequences[1], sequences[2], sequences[3])

        func binding(_ sequence: String, _ direction: ScrollDirection) -> ScrollKeyConfig.Binding {
            ScrollKeyConfig.Binding(keys: Array(sequence), direction: direction)
        }

        var bindings: [ScrollKeyConfig.Binding] = [
            binding(left, .left),
            binding(down, .down),
            binding(up, .up),
            binding(right, .right),

            binding(left.uppercased(), .halfLeft),
            binding(down.uppercased(), .halfDown),
            binding(up.uppercased(), .halfUp),
            binding(right.uppercased(), .halfRight),
        ]

        if sequences.count >= 6 {
            bindings.append(binding(sequences[4], .halfDown))
            bindings.append(binding(sequences[5], .halfUp))
        }

        if sequences.count >= 8 {
            bindings.append(binding(sequences[6], .bottom))
            bindings.append(binding(sequences[7], .top))
        }

        return ScrollKeyConfig(bindings: bindings)
    }

    private static func duplicateSequences(in sequences: [String]) -> [String] {
        var seen: Set<String> = []
        var reported: Set<String> = []
        var duplicates: [String] = []
        for sequence in sequences {
            if seen.contains(sequence), !reported.contains(sequence) {
                duplicates.append(sequence)
                reported.insert(sequence)
            }
            seen.insert(sequence)
        }
        return duplicates
    }
}

/// Scroll speed, as a share of the maximum.
enum ScrollSensitivity {
    static let defaultValue = 20
    static let range = 0...100

    static func isValid(_ value: Int) -> Bool { range.contains(value) }
}
