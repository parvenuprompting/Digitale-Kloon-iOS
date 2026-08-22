import CryptoKit
import Foundation
import SwiftData

/// Serializes the entire vault into an encrypted backup file, and restores it.
/// The backup is protected by a user-chosen passphrase so it stays private even
/// when the `.kloonbackup` file is shared or moved between devices.
enum BackupService {
    private static let saltLength = 16

    struct BackupPayload: Codable {
        var version = 1
        var items: [BackupItem]
        var notes: [BackupNote]
        var logs: [BackupLog]
    }

    struct BackupItem: Codable {
        var title: String
        var categoryRaw: String
        var notes: String
        var favorite: Bool
        var createdAt: Date
        var updatedAt: Date
        var lastOpenedAt: Date
        var fields: [BackupField]
    }

    struct BackupField: Codable {
        var label: String
        var isSecret: Bool
        /// Plaintext (decrypted) value at export time.
        var value: String
    }

    struct BackupNote: Codable {
        var title: String
        var body: String
        var pinned: Bool
        var createdAt: Date
        var updatedAt: Date
        var lastOpenedAt: Date
    }

    struct BackupLog: Codable {
        var text: String
        var createdAt: Date
        var updatedAt: Date
        var lastOpenedAt: Date
    }

    // MARK: - Export

    static func export(items: [VaultItem], notes: [Note], logs: [LogEntry], passphrase: String) throws -> Data {
        let payload = BackupPayload(
            items: items.map { item in
                BackupItem(
                    title: item.title,
                    categoryRaw: item.categoryRaw,
                    notes: item.notes,
                    favorite: item.favorite,
                    createdAt: item.createdAt,
                    updatedAt: item.updatedAt,
                    lastOpenedAt: item.lastOpenedAt,
                    fields: item.fields.map {
                        BackupField(label: $0.label, isSecret: $0.isSecret, value: $0.readableValue ?? "")
                    }
                )
            },
            notes: notes.map { BackupNote(title: $0.title, body: $0.body, pinned: $0.pinned, createdAt: $0.createdAt, updatedAt: $0.updatedAt, lastOpenedAt: $0.lastOpenedAt) },
            logs: logs.map { BackupLog(text: $0.text, createdAt: $0.createdAt, updatedAt: $0.updatedAt, lastOpenedAt: $0.lastOpenedAt) }
        )

        let json = try JSONEncoder().encode(payload)
        let salt = BackupCrypto.randomSalt()
        let key = try BackupCrypto.key(fromPassphrase: passphrase, salt: salt)
        let sealed = try AES.GCM.seal(json, using: key)
        guard let combined = sealed.combined else { throw BackupError.sealFailed }

        var data = Data()
        data.append(salt)
        data.append(combined)
        return data
    }

    // MARK: - Import

    static func decrypt(_ data: Data, passphrase: String) throws -> BackupPayload {
        guard data.count > saltLength else { throw BackupError.invalidFile }
        let salt = data.prefix(saltLength)
        let combined = data.dropFirst(saltLength)
        let key = try BackupCrypto.key(fromPassphrase: passphrase, salt: Data(salt))
        guard let sealed = try? AES.GCM.SealedBox(combined: Data(combined)) else {
            throw BackupError.invalidFile
        }
        let json = try AES.GCM.open(sealed, using: key)
        return try JSONDecoder().decode(BackupPayload.self, from: json)
    }

    enum BackupError: LocalizedError {
        case sealFailed
        case invalidFile
        case wrongPassphrase

        var errorDescription: String? {
            switch self {
            case .sealFailed: return "De back-up kon niet worden versleuteld."
            case .invalidFile: return "Ongeldig back-upbestand."
            case .wrongPassphrase: return "Wachtzin onjuist of bestand beschadigd."
            }
        }
    }
}