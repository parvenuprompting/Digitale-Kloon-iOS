import SwiftData
import SwiftUI

@main
struct DigitaleKloonApp: App {
    private let container: ModelContainer
    @StateObject private var security = SecurityState()
    @StateObject private var settings = AppSettings()
    @State private var showingIntro = true
    @Environment(\.scenePhase) private var scenePhase

    init() {
        container = ContainerFactory.makeContainer()
        // Ensure a master key exists before the UI reads any secret.
        _ = try? MasterKeyService.loadOrCreate()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView()
                    .environmentObject(security)
                    .environmentObject(settings)

                if showingIntro {
                    SplashView()
                        .transition(.opacity)
                        .task {
                            try? await Task.sleep(for: .seconds(2.6))
                            guard !Task.isCancelled else { return }
                            withAnimation(.easeOut(duration: 0.35)) {
                                showingIntro = false
                            }
                        }
                }
            }
            .preferredColorScheme(.dark)
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, phase in
            // Auto-lock whenever the app leaves the foreground; the cover view
            // prevents sensitive content from appearing in the app switcher.
            if phase != .active {
                security.lock()
            }
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var security: SecurityState
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        if security.isLocked {
            LockView()
        } else {
            MainTabView()
        }
    }
}