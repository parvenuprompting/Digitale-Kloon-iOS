import Foundation
import UIKit
import SwiftUI
import UniformTypeIdentifiers

/// Copies secrets to the pasteboard with local-only privacy (disabling Handoff/Universal Clipboard)
/// and enforces automatic wiping via both OS expiration and timed clearing.
enum ClipboardService {
    static func copy(_ text: String, autoClearAfter seconds: Int? = nil) {
        var options: [UIPasteboard.OptionsKey: Any] = [
            .localOnly: true
        ]
        if let seconds, seconds > 0 {
            options[.expirationDate] = Date().addingTimeInterval(TimeInterval(seconds))
        }
        UIPasteboard.general.setItems([[UTType.plainText.identifier: text]], options: options)

        guard let seconds, seconds > 0 else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(seconds)) {
            if UIPasteboard.general.string == text {
                UIPasteboard.general.items = []
            }
        }
    }
}

/// Holds the user's clipboard / lock preferences, persisted in UserDefaults.
@MainActor
final class AppSettings: ObservableObject {
    @Published var clipboardClearSeconds: Int {
        didSet { UserDefaults.standard.set(clipboardClearSeconds, forKey: Keys.clipboard) }
    }
    @Published var defaultCategoryRaw: String {
        didSet { UserDefaults.standard.set(defaultCategoryRaw, forKey: Keys.defaultCategory) }
    }

    private enum Keys {
        static let clipboard = "settings.clipboardClearSeconds"
        static let defaultCategory = "settings.defaultCategory"
    }

    init() {
        let defaults = UserDefaults.standard
        clipboardClearSeconds = defaults.object(forKey: Keys.clipboard) as? Int ?? 30
        defaultCategoryRaw = defaults.string(forKey: Keys.defaultCategory) ?? VaultCategory.password.rawValue
    }

    var defaultCategory: VaultCategory {
        VaultCategory(rawValue: defaultCategoryRaw) ?? .password
    }
}