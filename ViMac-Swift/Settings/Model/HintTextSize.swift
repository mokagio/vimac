import Foundation

/// The point size hint labels are drawn at. Stored as a string so the field can
/// hold what the user is midway through typing.
enum HintTextSize {
    static let defaultValue = "11.0"
    static let maximum: Double = 100

    enum Problem: Equatable {
        case notANumber
        case outOfRange(maximum: Double)

        var message: String {
            switch self {
            case .notANumber:
                return "Enter a number."
            case .outOfRange(let maximum):
                return "Enter a size above 0 and up to \(Int(maximum))."
            }
        }
    }

    static func problem(with value: String) -> Problem? {
        guard let size = Double(value) else { return .notANumber }
        guard size > 0, size <= maximum else { return .outOfRange(maximum: maximum) }
        return nil
    }

    static func isValid(_ value: String) -> Bool { problem(with: value) == nil }

    static func points(from value: String) -> Double {
        Double(isValid(value) ? value : defaultValue)!
    }
}
