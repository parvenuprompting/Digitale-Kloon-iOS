import Foundation

/// Lazily cached master key used to encrypt/decrypt secret field values.
enum SecretStore {
    nonisolated(unsafe) private static var cachedKey: SymmetricKeyBox?

    static func encrypt(_ plaintext: String) throws -> Data {
        let key = try key()
        return try CryptoService.encrypt(plaintext, using: key)
    }

    static func decrypt(_ sealedData: Data) throws -> String {
        let key = try key()
        return try CryptoService.decrypt(sealedData, using: key)
    }

    private static func key() throws -> SymmetricKeyBox {
        if let cachedKey { return cachedKey }
        let key = try MasterKeyService.loadOrCreate()
        cachedKey = key
        return key
    }
}

extension VaultField {
    /// The readable value of this field: plaintext for open fields, decrypted
    /// for secret fields. Returns nil if decryption fails.
    var readableValue: String? {
        guard isSecret else { return plainValue }
        guard secretData.isEmpty == false else { return "" }
        return try? SecretStore.decrypt(secretData)
    }

    /// Sets the field value, encrypting it when the field is secret.
    func setValue(_ value: String) {
        if isSecret {
            secretData = (try? SecretStore.encrypt(value)) ?? Data()
            plainValue = ""
        } else {
            plainValue = value
        }
    }
}