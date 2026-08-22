import SwiftData
import SwiftUI

struct NotesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Note.updatedAt, order: .reverse) private var notes: [Note]
    @State private var showingEditor = false

    private var sortedNotes: [Note] {
        notes.sorted { a, b in
            if a.pinned != b.pinned { return a.pinned && !b.pinned }
            return a.updatedAt > b.updatedAt
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if notes.isEmpty {
                    ContentUnavailableView(
                        "Nog geen notities",
                        systemImage: "note.text",
                        description: Text("Leg ideeën en aantekeningen vast in je tweede brein.")
                    )
                } else {
                    List {
                        ForEach(sortedNotes) { note in
                            NavigationLink {
                                NoteEditorView(note: note)
                            } label: {
                                NoteRow(note: note)
                            }
                        }
                        .onDelete(perform: delete)
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color.backgroundPrimary)
                }
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("Notities")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingEditor = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .foregroundStyle(Color.accent)
                    }
                    .accessibilityLabel("Nieuwe notitie")
                }
            }
            .sheet(isPresented: $showingEditor) {
                NoteEditorView(note: nil)
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sortedNotes[index])
        }
        try? modelContext.save()
    }
}

struct NoteRow: View {
    let note: Note

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(note.title.isEmpty ? "Naamloze notitie" : note.title)
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)

                if note.pinned {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundStyle(Color.accent)
                }
            }

            if !note.body.isEmpty {
                Text(note.body)
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(2)
            }

            Text(note.updatedAt, format: .dateTime.day().month(.abbreviated).year())
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
        }
        .padding(.vertical, 4)
        .listRowBackground(Color.backgroundSecondary)
    }
}

struct NoteEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let note: Note?

    @State private var title: String
    @State private var bodyText: String
    @State private var pinned: Bool
    @State private var showingDeleteConfirm = false

    init(note: Note?) {
        self.note = note
        _title = State(initialValue: note?.title ?? "")
        _bodyText = State(initialValue: note?.body ?? "")
        _pinned = State(initialValue: note?.pinned ?? false)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    TextField("Titel", text: $title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.textPrimary)

                    TextField("Schrijf je notitie…", text: $bodyText, axis: .vertical)
                        .lineLimit(8...)
                        .foregroundStyle(Color.textPrimary)
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.backgroundPrimary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleer") { dismiss() }
                        .foregroundStyle(Color.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Bewaar") { save() }
                        .foregroundStyle(Color.accent)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        pinned.toggle()
                    } label: {
                        Image(systemName: pinned ? "pin.fill" : "pin")
                            .foregroundStyle(pinned ? Color.accent : Color.textSecondary)
                    }
                    .accessibilityLabel("Vastpinnen")
                }
            }
        }
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        if let note {
            note.title = trimmedTitle
            note.body = bodyText
            note.pinned = pinned
            note.updatedAt = .now
        } else {
            let newNote = Note(title: trimmedTitle, body: bodyText, pinned: pinned)
            modelContext.insert(newNote)
        }
        try? modelContext.save()
        dismiss()
    }
}