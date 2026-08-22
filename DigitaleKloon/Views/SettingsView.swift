import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var security: SecurityState
    @EnvironmentObject private var settings: AppSettings
    @Query private var items: [VaultItem]
    @Query private var notes: [Note]
    @Query private var logs: [LogEntry]

    @State private var showingPassphrase = false
    @State private var passphrase = ""
    @State private var passphraseConfirm = ""
    @State private var exportURL: URL?
    @State private var showingImporter = false
    @State private var importPassphrase = ""
    @State private var pendingImportData: Data?
    @State private var showingImportPassphrase = false
    @State private var alertMessage: String?
    @State private var showingWipeConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                beveiligingSection
                klembordSection
                standaardSection
                backupSection
                dangerSection
            }
            .scrollContentBackground(.hidden)
            .background(Color.backgroundPrimary)
            .foregroundStyle(Color.textPrimary)
            .navigationTitle("Instellingen")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingPassphrase) {
                passphraseSheet
            }
            .sheet(item: $exportURL, onDismiss: cleanupExportFile) { url in
                ActivityView(urls: [url])
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.data],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result)
            }
            .sheet(isPresented: $showingImportPassphrase) {
                importPassphraseSheet
            }
            .alert("Let op", isPresented: Binding(
                get: { alertMessage != nil },
                set: { if !$0 { alertMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage ?? "")
            }
            .confirmationDialog("Alle gegevens wissen?", isPresented: $showingWipeConfirm, titleVisibility: .visible) {
                Button("Alles wissen", role: .destructive) { wipeAll() }
                Button("Annuleer", role: .cancel) {}
            } message: {
                Text("Hiermee worden alle items, notities en logs permanent verwijderd. Dit kan niet ongedaan worden gemaakt.")
            }
        }
    }

    // MARK: - Sections

    private var beveiligingSection: some View {
        Section {
            Toggle(isOn: $security.useBiometrics) {
                Label {
                    Text("Ontgrendel met \(BiometricGate.biometricName)")
                } icon: {
                    Image(systemName: "faceid")
                        .foregroundStyle(Color.accent)
                }
            }
            .disabled(!BiometricGate.isAvailable)

            Text("De kluis vergrendelt automatisch zodra de app naar de achtergrond gaat.")
                .font(.footnote)
                .foregroundStyle(Color.textSecondary)
        } header: {
            Text("Beveiliging")
        }
    }

    private var klembordSection: some View {
        Section {
            Picker("Wis klembord na", selection: $settings.clipboardClearSeconds) {
                Text("Niet wissen").tag(0)
                Text("15 seconden").tag(15)
                Text("30 seconden").tag(30)
                Text("60 seconden").tag(60)
            }
        } header: {
            Text("Klembord")
        } footer: {
            Text("Gekopieerde geheimen worden na deze tijd automatisch van het klembord gewist.")
        }
    }

    private var standaardSection: some View {
        Section {
            Picker("Standaardcategorie", selection: $settings.defaultCategoryRaw) {
                ForEach(VaultCategory.allCases) { category in
                    Label(category.displayName, systemImage: category.systemImage)
                        .tag(category.rawValue)
                }
            }
        } header: {
            Text("Nieuwe items")
        }
    }

    private var backupSection: some View {
        Section {
            Button {
                showingPassphrase = true
            } label: {
                Label("Exporteer versleutelde back-up", systemImage: "square.and.arrow.up")
            }

            Button {
                showingImporter = true
            } label: {
                Label("Importeer back-up", systemImage: "square.and.arrow.down")
            }
        } header: {
            Text("Back-up")
        } footer: {
            Text("Je back-up wordt met een eigen wachtzin versleuteld. Alleen jij kunt hem met die wachtzin weer openen. Items: \(items.count), notities: \(notes.count), logs: \(logs.count).")
        }
    }

    private var dangerSection: some View {
        Section {
            Button(role: .destructive) {
                showingWipeConfirm = true
            } label: {
                Label("Wis alle gegevens", systemImage: "trash")
            }
        } header: {
            Text("Gevaarlijke zone")
        }
    }

    // MARK: - Passphrase sheets

    private var passphraseSheet: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Wachtzin", text: $passphrase)
                    SecureField("Herhaal wachtzin", text: $passphraseConfirm)
                } footer: {
                    Text("Gebruik een sterke wachtzin die je goed onthoudt.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.backgroundPrimary)
            .foregroundStyle(Color.textPrimary)
            .navigationTitle("Back-up exporteren")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleer") { dismissPassphrase() }
                        .foregroundStyle(Color.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Exporteer") { performExport() }
                        .disabled(!canExport)
                        .foregroundStyle(Color.accent)
                }
            }
        }
    }

    private var importPassphraseSheet: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Wachtzin", text: $importPassphrase)
                } footer: {
                    Text("De wachtzin waarmee de back-up is versleuteld.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.backgroundPrimary)
            .foregroundStyle(Color.textPrimary)
            .navigationTitle("Back-up importeren")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleer") {
                        importPassphrase = ""
                        pendingImportData = nil
                        showingImportPassphrase = false
                    }
                    .foregroundStyle(Color.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Importeer") { performImport() }
                        .disabled(importPassphrase.isEmpty)
                        .foregroundStyle(Color.accent)
                }
            }
        }
    }

    // MARK: - Actions

    private var canExport: Bool {
        passphrase.count >= 6 && passphrase == passphraseConfirm
    }

    private func dismissPassphrase() {
        passphrase = ""
        passphraseConfirm = ""
        showingPassphrase = false
    }

    private func performExport() {
        cleanupTemporaryBackups()
        do {
            let data = try BackupService.export(items: items, notes: notes, logs: logs, passphrase: passphrase)
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("DigitaleKloon-\(formattedDate())-\(UUID().uuidString.prefix(8)).kloonbackup")
            try data.write(to: url)
            passphrase = ""
            passphraseConfirm = ""
            showingPassphrase = false
            exportURL = url
        } catch {
            alertMessage = "De back-up kon niet worden aangemaakt."
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            let data = try Data(contentsOf: url)
            pendingImportData = data
            importPassphrase = ""
            showingImportPassphrase = true
        } catch {
            alertMessage = "Het bestand kon niet worden gelezen."
        }
    }

    private func performImport() {
        guard let data = pendingImportData else { return }
        do {
            let payload = try BackupService.decrypt(data, passphrase: importPassphrase)
            restore(payload)
            importPassphrase = ""
            pendingImportData = nil
            showingImportPassphrase = false
            alertMessage = "Back-up succesvol geïmporteerd."
        } catch {
            alertMessage = BackupService.BackupError.wrongPassphrase.errorDescription
        }
    }

    private func restore(_ payload: BackupService.BackupPayload) {
        for item in items { modelContext.delete(item) }
        for note in notes { modelContext.delete(note) }
        for log in logs { modelContext.delete(log) }

        for backupItem in payload.items {
            let item = VaultItem(
                title: backupItem.title,
                category: VaultCategory(rawValue: backupItem.categoryRaw) ?? .account,
                notes: backupItem.notes,
                favorite: backupItem.favorite,
                createdAt: backupItem.createdAt,
                updatedAt: backupItem.updatedAt,
                lastOpenedAt: backupItem.lastOpenedAt
            )
            modelContext.insert(item)
            for backupField in backupItem.fields {
                let field = VaultField(label: backupField.label, isSecret: backupField.isSecret)
                field.setValue(backupField.value)
                field.item = item
                modelContext.insert(field)
            }
        }

        for backupNote in payload.notes {
            modelContext.insert(Note(
                title: backupNote.title,
                body: backupNote.body,
                pinned: backupNote.pinned,
                createdAt: backupNote.createdAt,
                updatedAt: backupNote.updatedAt,
                lastOpenedAt: backupNote.lastOpenedAt
            ))
        }

        for backupLog in payload.logs {
            modelContext.insert(LogEntry(
                text: backupLog.text,
                createdAt: backupLog.createdAt,
                updatedAt: backupLog.updatedAt,
                lastOpenedAt: backupLog.lastOpenedAt
            ))
        }

        try? modelContext.save()
    }

    private func wipeAll() {
        for item in items { modelContext.delete(item) }
        for note in notes { modelContext.delete(note) }
        for log in logs { modelContext.delete(log) }
        try? modelContext.save()
    }

    private func formattedDate() -> String {
        Date.now.formatted(.dateTime.year().month(.twoDigits).day(.twoDigits))
    }

    private func cleanupExportFile() {
        if let exportURL {
            try? FileManager.default.removeItem(at: exportURL)
            self.exportURL = nil
        }
    }

    private func cleanupTemporaryBackups() {
        let tempDir = FileManager.default.temporaryDirectory
        if let files = try? FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil) {
            for file in files where file.pathExtension == "kloonbackup" {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }
}