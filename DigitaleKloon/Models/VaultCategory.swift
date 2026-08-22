import Foundation
import SwiftUI

enum VaultCategory: String, CaseIterable, Codable, Identifiable {
    case password
    case apiKey
    case bank
    case crypto
    case account

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .password: return "Wachtwoord"
        case .apiKey: return "API-key"
        case .bank: return "Bank / IBAN"
        case .crypto: return "Crypto"
        case .account: return "Account"
        }
    }

    var systemImage: String {
        switch self {
        case .password: return "key.fill"
        case .apiKey: return "terminal.fill"
        case .bank: return "building.columns.fill"
        case .crypto: return "bitcoinsign"
        case .account: return "person.crop.circle.fill"
        }
    }
}

/// Field templates shown for a freshly created item of a given category.
struct FieldTemplate: Identifiable {
    let id = UUID()
    let label: String
    let isSecret: Bool
}

extension VaultCategory {
    var fieldTemplates: [FieldTemplate] {
        switch self {
        case .password:
            return [
                FieldTemplate(label: "Gebruikersnaam", isSecret: false),
                FieldTemplate(label: "Wachtwoord", isSecret: true)
            ]
        case .apiKey:
            return [
                FieldTemplate(label: "Naam", isSecret: false),
                FieldTemplate(label: "Key", isSecret: true)
            ]
        case .bank:
            return [
                FieldTemplate(label: "IBAN", isSecret: true),
                FieldTemplate(label: "Naam rekeninghouder", isSecret: false)
            ]
        case .crypto:
            return [
                FieldTemplate(label: "Wallet", isSecret: false),
                FieldTemplate(label: "Private key / seed", isSecret: true)
            ]
        case .account:
            return [
                FieldTemplate(label: "Accountnaam", isSecret: false),
                FieldTemplate(label: "Wachtwoord", isSecret: true)
            ]
        }
    }
}