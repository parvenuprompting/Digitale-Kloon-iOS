import CommonCrypto
import CryptoKit
import Foundation

/// Encrypts and decrypts secret field values with AES-GCM using the master key.
enum CryptoService {
    enum CryptoError: Error {
        case invalidSealedBox
    }

    static func encrypt(_ plaintext: String, using key: SymmetricKeyBox) throws -> Data {
        let symmetricKey = SymmetricKey(data: key.data)
        let sealed = try AES.GCM.seal(Data(plaintext.utf8), using: symmetricKey)
        return sealed.combined ?? Data()
    }

    static func decrypt(_ sealedData: Data, using key: SymmetricKeyBox) throws -> String {
        guard sealedData.isEmpty == false else { return "" }
        let symmetricKey = SymmetricKey(data: key.data)
        guard let sealed = try? AES.GCM.SealedBox(combined: sealedData) else {
            throw CryptoError.invalidSealedBox
        }
        let decrypted = try AES.GCM.open(sealed, using: symmetricKey)
        return String(decoding: decrypted, as: UTF8.self)
    }
}

/// Derives an independent 256-bit key from a user passphrase for encrypted
/// backups using PBKDF2-HMAC-SHA256 (600,000 rounds) to prevent offline brute-force attacks.
enum BackupCrypto {
    static let defaultRounds: UInt32 = 600_000

    enum BackupCryptoError: Error {
        case keyDerivationFailed
    }

    static func key(fromPassphrase passphrase: String, salt: Data, rounds: UInt32 = defaultRounds) throws -> SymmetricKey {
        var derivedBytes = [UInt8](repeating: 0, count: 32)
        let passwordData = Data(passphrase.utf8)

        let status = derivedBytes.withUnsafeMutableBytes { derivedKeyBuffer in
            salt.withUnsafeBytes { saltBuffer in
                CCKeyDerivationPBKDF(
                    CCPBKDFAlgorithm(kCCPBKDF2),
                    passphrase,
                    passwordData.count,
                    saltBuffer.bindMemory(to: UInt8.self).baseAddress,
                    salt.count,
                    CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                    rounds,
                    derivedKeyBuffer.bindMemory(to: UInt8.self).baseAddress,
                    32
                )
            }
        }

        guard status == kCCSuccess else {
            throw BackupCryptoError.keyDerivationFailed
        }

        return SymmetricKey(data: derivedBytes)
    }

    static func randomSalt() -> Data {
        var bytes = [UInt8](repeating: 0, count: 16)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes)
    }
}