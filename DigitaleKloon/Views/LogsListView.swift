import SwiftData
import SwiftUI

struct LogsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LogEntry.createdAt, order: .reverse) private var logs: [LogEntry]
    @State private var showingEditor = false

    var body: some View {
        NavigationStack {
            Group {
                if logs.isEmpty {
                    ContentUnavailableView(
                        "Nog geen logs",
                        systemImage: "list.bullet.rectangle",
                        description: Text("Leg gebeurtenissen vast met automatische tijd- en datumregistratie.")
                    )
                } else {
                    List {
                        ForEach(logs) { log in
                            NavigationLink {
                                LogEditorView(log: log)
                            } label: {
                                LogRow(log: log)
                            }
                        }
                        .onDelete(perform: delete)
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color.backgroundPrimary)
                }
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("Logs")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingEditor = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Color.accent)
                    }
                    .accessibilityLabel("Nieuwe log")
                }
            }
            .sheet(isPresented: $showingEditor) {
                LogEditorView(log: nil)
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(logs[index])
        }
        try? modelContext.save()
    }
}

struct LogRow: View {
    let log: LogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(log.text)
                .font(.body)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(2)

            Text(log.createdAt, format: .dateTime.day().month(.wide).year().hour().minute())
                .font(.caption.monospacedDigit())
                .foregroundStyle(Color.textSecondary)
        }
        .padding(.vertical, 4)
        .listRowBackground(Color.backgroundSecondary)
    }
}

struct LogEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let log: LogEntry?
    @State private var text: String

    init(log: LogEntry?) {
        self.log = log
        _text = State(initialValue: log?.text ?? "")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Wat is er gebeurd?", text: $text, axis: .vertical)
                        .lineLimit(6...)
                        .foregroundStyle(Color.textPrimary)

                    if let log {
                        Text("Aangemaakt \(log.createdAt.formatted(.dateTime.day().month(.wide).year().hour().minute()))")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }
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
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .foregroundStyle(Color.accent)
                }
            }
        }
    }

    private func save() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let log {
            log.text = trimmed
            log.updatedAt = .now
        } else {
            modelContext.insert(LogEntry(text: trimmed))
        }
        try? modelContext.save()
        dismiss()
    }
}