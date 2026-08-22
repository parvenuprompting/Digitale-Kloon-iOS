import Foundation
import SwiftUI

enum PasswordGenerator {
    struct Options {
        var length = 20
        var includeLowercase = true
        var includeUppercase = true
        var includeDigits = true
        var includeSymbols = true
    }

    static func generate(options: Options) -> String {
        var sets: [String] = []
        if options.includeLowercase { sets.append("abcdefghijklmnopqrstuvwxyz") }
        if options.includeUppercase { sets.append("ABCDEFGHIJKLMNOPQRSTUVWXYZ") }
        if options.includeDigits { sets.append("0123456789") }
        if options.includeSymbols { sets.append("!@#$%^&*()-_=+[]{};:,.?") }

        guard !sets.isEmpty else { return "" }
        let all = sets.joined()

        var result = ""
        // Ensure at least one character from each selected set.
        for set in sets {
            result.append(set.randomElement()!)
        }
        while result.count < options.length {
            result.append(all.randomElement()!)
        }
        return String(result.shuffled())
    }
}

enum PasswordStrength {
    enum Level: Int, Comparable {
        case weak = 0, fair = 1, good = 2, strong = 3

        static func < (lhs: Level, rhs: Level) -> Bool { lhs.rawValue < rhs.rawValue }

        var label: String {
            switch self {
            case .weak: return "Zwak"
            case .fair: return "Matig"
            case .good: return "Goed"
            case .strong: return "Sterk"
            }
        }

        var color: SwiftUI.Color {
            switch self {
            case .weak: return .orange
            case .fair: return .yellow
            case .good: return .green
            case .strong: return Color.accent
            }
        }
    }

    static func level(of password: String) -> Level {
        guard !password.isEmpty else { return .weak }

        var score = 0
        if password.count >= 8 { score += 1 }
        if password.count >= 12 { score += 1 }
        if password.count >= 16 { score += 1 }

        var classes = 0
        if password.rangeOfCharacter(from: .lowercaseLetters) != nil { classes += 1 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { classes += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { classes += 1 }
        if password.rangeOfCharacter(from: .symbols) != nil || password.rangeOfCharacter(from: .punctuationCharacters) != nil { classes += 1 }

        score += classes

        switch score {
        case ..<4: return .weak
        case 4: return .fair
        case 5: return .good
        default: return .strong
        }
    }
}