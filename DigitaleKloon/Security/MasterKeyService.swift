import Foundation
import Security

/// Stores the single symmetric master key that encrypts all secret field values.
/// The key itself lives in the iOS Keychain (hardware-backed, excluded from
/// backups by default) and is never written to disk in plaintext.
enum MasterKeyService {
    private static let service = "nl.tiendo.digitalekloon.masterkey"
    private static let account = "master"

    /// Returns the existing master key or generates and stores a new one.
    static func loadOrCreate() throws -> SymmetricKeyBox {
        if let key = try read() {
            return key
        }
        let key = SymmetricKeyBox.generate()
        try write(key)
        return key
    }

    static func read() throws -> SymmetricKeyBox? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data else {
            throw KeychainError(code: status)
        }
        return SymmetricKeyBox(data: data)
    }

    private static func write(_ key: SymmetricKeyBox) throws {
        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: key.data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError(code: status)
        }
    }

    private static var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    struct KeychainError: Error {
        let code: OSStatus
    }
}

/// Thin wrapper around the raw 32-byte master key material.
struct SymmetricKeyBox {
    let data: Data

    static func generate() -> SymmetricKeyBox {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return SymmetricKeyBox(data: Data(bytes))
    }
}