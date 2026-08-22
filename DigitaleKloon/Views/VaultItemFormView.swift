import SwiftData
import SwiftUI

struct FieldDraft: Identifiable {
    let id: UUID
    var label: String
    var value: String
    var isSecret: Bool
}

struct VaultItemFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    let item: VaultItem?

    @State private var title = ""
    @State private var category: VaultCategory
    @State private var notes = ""
    @State private var favorite = false
    @State private var fieldDrafts: [FieldDraft] = []
    @State private var generatorFieldID: UUID?
    @State private var showingSaveError = false

    init(item: VaultItem? = nil, defaultCategory: VaultCategory = .password) {
        self.item = item
        let startCategory = item?.category ?? defaultCategory
        _category = State(initialValue: startCategory)
        _title = State(initialValue: item?.title ?? "")
        _notes = State(initialValue: item?.notes ?? "")
        _favorite = State(initialValue: item?.favorite ?? false)
        _fieldDrafts = State(initialValue: (item?.fields.map {
            FieldDraft(id: $0.id, label: $0.label, value: $0.readableValue ?? "", isSecret: $0.isSecret)
        }) ?? startCategory.fieldTemplates.map {
            FieldDraft(id: UUID(), label: $0.label, value: "", isSecret: $0.isSecret)
        })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Naam") {
                    TextField("Titel", text: $title)
                }

                if item == nil {
                    Section("Categorie") {
                        Picker("Categorie", selection: $category) {
                            ForEach(VaultCategory.allCases) { category in
                                Label(category.displayName, systemImage: category.systemImage)
                                    .tag(category)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: category) { _, newValue in
                            applyTemplate(newValue)
                        }
                    }
                }

                Section("Velden") {
                    ForEach($fieldDrafts) { $draft in
                        FieldEditorRow(
                            draft: $draft,
                            onGenerate: { generatorFieldID = draft.id }
                        )
                    }
                    .onDelete { offsets in
                        fieldDrafts.remove(atOffsets: offsets)
                    }

                    Button {
                        fieldDrafts.append(FieldDraft(id: UUID(), label: "Nieuw veld", value: "", isSecret: false))
                    } label: {
                        Label("Voeg veld toe", systemImage: "plus")
                            .foregroundStyle(Color.accent)
                    }
                }

                Section("Notitie") {
                    TextField("Optionele notitie", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Toggle("Favoriet", isOn: $favorite)
                }

                Section {
                    Button {
                        save()
                    } label: {
                        Label(item == nil ? "Vergrendel in je kluis" : "Wijzigingen opslaan", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.accent)
                    .foregroundStyle(Color.backgroundPrimary)
                    .disabled(!canSave)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.backgroundPrimary)
            .foregroundStyle(Color.textPrimary)
            .navigationTitle(item == nil ? "Nieuw item" : "Bewerken")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleer") { dismiss() }
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .sheet(item: $generatorFieldID) { fieldID in
                PasswordGeneratorView { generatedPassword in
                    if let index = fieldDrafts.firstIndex(where: { $0.id == fieldID }) {
                        fieldDrafts[index].value = generatedPassword
                    }
                }
            }
            .alert("Opslaan mislukt", isPresented: $showingSaveError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Het item kon niet worden opgeslagen.")
            }
        }
    }

    private func applyTemplate(_ newCategory: VaultCategory) {
        fieldDrafts = newCategory.fieldTemplates.map {
            FieldDraft(id: UUID(), label: $0.label, value: "", isSecret: $0.isSecret)
        }
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        if let item {
            item.title = trimmedTitle
            item.notes = trimmedNotes
            item.favorite = favorite
            item.updatedAt = .now
            reconcileFields(for: item)
        } else {
            let newItem = VaultItem(title: trimmedTitle, category: category, notes: trimmedNotes, favorite: favorite)
            modelContext.insert(newItem)
            for draft in fieldDrafts {
                let field = VaultField(label: trimmed(draft.label), isSecret: draft.isSecret)
                field.setValue(draft.value)
                field.item = newItem
                modelContext.insert(field)
            }
        }

        do {
            try modelContext.save()
        } catch {
            showingSaveError = true
            return
        }
        dismiss()
    }

    private func reconcileFields(for item: VaultItem) {
        let draftIDs = Set(fieldDrafts.map(\.id))

        for field in item.fields where !draftIDs.contains(field.id) {
            modelContext.delete(field)
        }

        for draft in fieldDrafts {
            if let field = item.fields.first(where: { $0.id == draft.id }) {
                field.label = trimmed(draft.label)
                field.isSecret = draft.isSecret
                field.setValue(draft.value)
            } else {
                let field = VaultField(label: trimmed(draft.label), isSecret: draft.isSecret)
                field.setValue(draft.value)
                field.item = item
                modelContext.insert(field)
            }
        }
    }

    private func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

/// One editable field row: label, value (with reveal/generate for secrets).
struct FieldEditorRow: View {
    @Binding var draft: FieldDraft
    let onGenerate: () -> Void
    @State private var revealed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                TextField("Label", text: $draft.label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)

                if draft.isSecret {
                    Button {
                        draft.isSecret.toggle()
                        revealed = false
                    } label: {
                        Image(systemName: "eye.slash")
                            .foregroundStyle(Color.accent)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Maak van dit veld een geheim veld")
                } else {
                    Button {
                        draft.isSecret.toggle()
                        revealed = false
                    } label: {
                        Image(systemName: "eye")
                            .foregroundStyle(Color.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Maak van dit veld een open veld")
                }
            }

            if draft.isSecret {
                HStack(spacing: 8) {
                    Group {
                        if revealed {
                            TextField("Waarde", text: $draft.value, axis: .vertical)
                                .privacySensitive()
                        } else {
                            SecureField("Waarde", text: $draft.value)
                        }
                    }
                    .font(.system(.body, design: .monospaced))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                    Button {
                        revealed.toggle()
                    } label: {
                        Image(systemName: revealed ? "eye.slash" : "eye")
                            .foregroundStyle(Color.accent)
                    }
                    .buttonStyle(.plain)

                    Button(action: onGenerate) {
                        Image(systemName: "wand.and.stars")
                            .foregroundStyle(Color.accent)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Genereer wachtwoord")
                }

                if !draft.value.isEmpty {
                    StrengthBar(password: draft.value)
                }
            } else {
                TextField("Waarde", text: $draft.value, axis: .vertical)
                    .font(.system(.body, design: .monospaced))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        }
        .padding(.vertical, 2)
    }
}