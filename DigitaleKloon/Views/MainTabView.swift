import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            VaultListView()
                .tabItem { Label("Kluis", systemImage: "lock.shield.fill") }

            NotesListView()
                .tabItem { Label("Notities", systemImage: "note.text") }

            LogsListView()
                .tabItem { Label("Logs", systemImage: "list.bullet.rectangle") }

            SettingsView()
                .tabItem { Label("Instellingen", systemImage: "gearshape.fill") }
        }
        .tint(Color.accent)
    }
}