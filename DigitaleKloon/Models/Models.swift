import Foundation
import SwiftData
import UIKit

@Model
final class VaultItem: Identifiable {
    var id: UUID
    var title: String
    var categoryRaw: String
    var notes: String
    var favorite: Bool
    var createdAt: Date
    var updatedAt: Date
    var lastOpenedAt: Date
    @Relationship(deleteRule: .cascade, inverse: \VaultField.item)
    var fields: [VaultField]

    init(
        id: UUID = UUID(),
        title: String,
        category: VaultCategory,
        notes: String = "",
        favorite: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        lastOpenedAt: Date = .now,
        fields: [VaultField] = []
    ) {
        self.id = id
        self.title = title
        self.categoryRaw = category.rawValue
        self.notes = notes
        self.favorite = favorite
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastOpenedAt = lastOpenedAt
        self.fields = fields
    }

    var category: VaultCategory {
        get { VaultCategory(rawValue: categoryRaw) ?? .account }
        set { categoryRaw = newValue.rawValue }
    }
}

@Model
final class VaultField: Identifiable {
    var id: UUID
    var label: String
    var isSecret: Bool
    /// Plaintext value for non-secret fields.
    var plainValue: String
    /// AES-GCM sealed box (`combined`) for secret fields; empty otherwise.
    var secretData: Data
    var item: VaultItem?

    init(
        id: UUID = UUID(),
        label: String,
        isSecret: Bool,
        value: String = "",
        item: VaultItem? = nil
    ) {
        self.id = id
        self.label = label
        self.isSecret = isSecret
        self.plainValue = isSecret ? "" : value
        self.secretData = Data()
        self.item = item
    }
}

@Model
final class Note: Identifiable {
    var id: UUID
    var title: String
    var body: String
    var pinned: Bool
    var createdAt: Date
    var updatedAt: Date
    var lastOpenedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        body: String = "",
        pinned: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        lastOpenedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.pinned = pinned
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastOpenedAt = lastOpenedAt
    }
}

@Model
final class LogEntry: Identifiable {
    var id: UUID
    var text: String
    var createdAt: Date
    var updatedAt: Date
    var lastOpenedAt: Date

    init(
        id: UUID = UUID(),
        text: String,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        lastOpenedAt: Date = .now
    ) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastOpenedAt = lastOpenedAt
    }
}