import Testing
import Foundation
@testable import DigitaleKloon

struct DigitaleKloonTests {

    @Test
    func passwordGeneratorRespectsLength() {
        let options = PasswordGenerator.Options(
            length: 24,
            includeLowercase: true,
            includeUppercase: true,
            includeDigits: true,
            includeSymbols: true
        )
        let password = PasswordGenerator.generate(options: options)
        #expect(password.count == 24)
    }

    @Test
    func passwordStrengthIncreasesWithLength() {
        let short = PasswordStrength.level(of: "abc")
        let long = PasswordStrength.level(of: "aB3$efGhiJkLmNopQr")
        #expect(short.rawValue < long.rawValue)
    }

    @Test
    func cryptoRoundtrip() throws {
        let key = SymmetricKeyBox.generate()
        let plaintext = "geheim wachtwoord 123"
        let sealed = try CryptoService.encrypt(plaintext, using: key)
        #expect(sealed != Data(plaintext.utf8))
        let decrypted = try CryptoService.decrypt(sealed, using: key)
        #expect(decrypted == plaintext)
    }

    @Test
    func backupRoundtrip() throws {
        let payload = BackupService.BackupPayload(
            items: [],
            notes: [],
            logs: [BackupService.BackupLog(
                text: "test",
                createdAt: .now,
                updatedAt: .now,
                lastOpenedAt: .now
            )]
        )
        let json = try JSONEncoder().encode(payload)
        let decoded = try JSONDecoder().decode(BackupService.BackupPayload.self, from: json)
        #expect(decoded.logs.count == 1)
        #expect(decoded.logs.first?.text == "test")
    }

    @Test
    func pbkdf2KeyDerivation() throws {
        let passphrase = "correct-horse-battery-staple"
        let salt = Data([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
                         0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10])
        let key1 = try BackupCrypto.key(fromPassphrase: passphrase, salt: salt, rounds: 1_000)
        let key2 = try BackupCrypto.key(fromPassphrase: passphrase, salt: salt, rounds: 1_000)
        #expect(key1 == key2)

        let differentSalt = Data([0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18,
                                  0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F, 0x20])
        let key3 = try BackupCrypto.key(fromPassphrase: passphrase, salt: differentSalt, rounds: 1_000)
        #expect(key1 != key3)
    }

    @Test
    func backupServiceExportAndDecryptRoundtrip() throws {
        let passphrase = "sterke-wachtzin-voor-backup-123"
        let exportData = try BackupService.export(
            items: [],
            notes: [],
            logs: [],
            passphrase: passphrase
        )
        #expect(exportData.count > 16)

        let decryptedPayload = try BackupService.decrypt(exportData, passphrase: passphrase)
        #expect(decryptedPayload.items.isEmpty)
        #expect(decryptedPayload.notes.isEmpty)
        #expect(decryptedPayload.logs.isEmpty)
    }
}