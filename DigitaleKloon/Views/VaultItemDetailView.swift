import SwiftData
import SwiftUI

struct VaultItemDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    let item: VaultItem
    @State private var isEditing = false
    @State private var pendingDelete = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header

                fieldsSection

                if !item.notes.isEmpty {
                    notesSection
                }

                timestampsSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
        .background(Color.backgroundPrimary)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                BrandHeader(title: item.title)
            }
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 14) {
                    Button {
                        item.favorite.toggle()
                        try? modelContext.save()
                    } label: {
                        Image(systemName: item.favorite ? "star.fill" : "star")
                            .foregroundStyle(Color.accent)
                    }
                    .accessibilityLabel("Favoriet")

                    Button {
                        isEditing = true
                    } label: {
                        Image(systemName: "pencil")
                            .foregroundStyle(Color.accent)
                    }
                    .accessibilityLabel("Bewerk")
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            VaultItemFormView(item: item)
        }
        .confirmationDialog("Item verwijderen?", isPresented: $pendingDelete, titleVisibility: .visible) {
            Button("Verwijder", role: .destructive) {
                modelContext.delete(item)
                try? modelContext.save()
                dismiss()
            }
            Button("Annuleer", role: .cancel) {}
        } message: {
            Text("Dit kan niet ongedaan worden gemaakt.")
        }
        .onAppear {
            item.lastOpenedAt = .now
            try? modelContext.save()
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            Image(systemName: item.category.systemImage)
                .font(.title)
                .foregroundStyle(Color.accent)
                .frame(width: 56, height: 56)
                .background(Color.accent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.textPrimary)

                Text(item.category.displayName)
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var fieldsSection: some View {
        VStack(spacing: 12) {
            ForEach(item.fields) { field in
                FieldDetailRow(
                    label: field.label,
                    value: field.readableValue ?? "",
                    isSecret: field.isSecret,
                    copyClearSeconds: settings.clipboardClearSeconds
                )
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Notitie")
            Text(item.notes)
                .font(.subheadline)
                .foregroundStyle(Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .kloonCard(cornerRadius: 14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var timestampsSection: some View {
        VStack(spacing: 10) {
            timestampRow(label: "Aangemaakt", date: item.createdAt)
            timestampRow(label: "Bewerkt", date: item.updatedAt)
            timestampRow(label: "Geopend", date: item.lastOpenedAt)

            Button(role: .destructive) {
                pendingDelete = true
            } label: {
                Label("Verwijder item", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .padding(.top, 8)
        }
    }

    private func timestampRow(label: String, date: Date) -> some View {
        HStack {
            Text(label)
                .font(.footnote)
                .foregroundStyle(Color.textSecondary)
            Spacer()
            Text(date, format: .dateTime.day().month(.wide).year().hour().minute())
                .font(.footnote.monospacedDigit())
                .foregroundStyle(Color.textSecondary)
        }
        .padding(.horizontal, 4)
    }
}