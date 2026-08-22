import SwiftData
import SwiftUI

struct VaultListView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \VaultItem.title) private var items: [VaultItem]
    @State private var selectedCategory: VaultCategory?
    @State private var searchText = ""
    @State private var showingNewItem = false

    private var filteredItems: [VaultItem] {
        items.filter { item in
            let matchesCategory = selectedCategory == nil || item.category == selectedCategory
            let matchesSearch = searchText.isEmpty
                || item.title.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty && searchText.isEmpty {
                    emptyState
                } else if filteredItems.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    list
                }
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("Kluis")
            .searchable(text: $searchText, prompt: "Zoek in je kluis")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNewItem = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Color.accent)
                    }
                    .accessibilityLabel("Nieuw item")
                }
            }
            .sheet(isPresented: $showingNewItem) {
                VaultItemFormView(defaultCategory: settings.defaultCategory)
            }
        }
    }

    private var list: some View {
        List {
            categoryFilter

            ForEach(filteredItems) { item in
                NavigationLink {
                    VaultItemDetailView(item: item)
                } label: {
                    VaultItemRow(item: item)
                }
            }
            .onDelete(perform: delete)
        }
        .scrollContentBackground(.hidden)
        .background(Color.backgroundPrimary)
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryChip(title: "Alles", systemImage: "square.grid.2x2", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(VaultCategory.allCases) { category in
                    CategoryChip(title: category.displayName, systemImage: category.systemImage, isSelected: selectedCategory == category) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 110, height: 110)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

            Text("Je kluis is leeg")
                .font(.headline)
                .foregroundStyle(Color.textPrimary)

            Text("Voeg wachtwoorden, API-keys, bankgegevens en meer toe.")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                showingNewItem = true
            } label: {
                Label("Pluk je eerste geheim", systemImage: "plus")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.accent)
            .foregroundStyle(Color.backgroundPrimary)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredItems[index])
        }
        try? modelContext.save()
    }
}

struct CategoryChip: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .foregroundStyle(isSelected ? Color.backgroundPrimary : Color.textSecondary)
                .background(isSelected ? Color.accent : Color.backgroundSecondary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct VaultItemRow: View {
    let item: VaultItem

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: item.category.systemImage)
                .font(.title3)
                .foregroundStyle(Color.accent)
                .frame(width: 40, height: 40)
                .background(Color.accent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)

                Text(item.category.displayName)
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            if item.favorite {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(Color.accent)
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(Color.backgroundSecondary)
    }
}