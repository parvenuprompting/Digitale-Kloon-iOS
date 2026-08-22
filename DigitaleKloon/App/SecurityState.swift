import Foundation
import SwiftData

/// Tracks whether the vault is locked and drives the root view transition.
@MainActor
final class SecurityState: ObservableObject {
    @Published var isLocked = true
    @Published var useBiometrics: Bool {
        didSet { UserDefaults.standard.set(useBiometrics, forKey: Keys.useBiometrics) }
    }

    private enum Keys {
        static let useBiometrics = "security.useBiometrics"
    }

    init() {
        let stored = UserDefaults.standard.object(forKey: Keys.useBiometrics)
        useBiometrics = stored as? Bool ?? true
    }

    func lock() {
        isLocked = true
    }

    func didUnlock() {
        isLocked = false
    }
}

enum ContainerFactory {
    static let schema = Schema([
        VaultItem.self,
        VaultField.self,
        Note.self,
        LogEntry.self
    ])

    static func makeContainer() -> ModelContainer {
        let dir = URL.applicationSupportDirectory
            .appending(path: "DigitaleKloon", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        excludeFromBackup(dir)

        let url = dir.appending(path: "kloon.store")
        let config = ModelConfiguration(schema: schema, url: url)

        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            excludeFromBackup(url)
            return container
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    /// Marks a file/directory so it is excluded from iCloud, device and Mac backups.
    /// This keeps vault data out of any OS-level backup path.
    private static func excludeFromBackup(_ url: URL) {
        var mutableURL = url
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? mutableURL.setResourceValues(values)
    }
}