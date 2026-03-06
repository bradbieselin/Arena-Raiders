import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            switch appState.currentScreen {
            case .splash:
                SplashScreenView()
            case .main:
                MainTabView()
            case .game:
                if let session = appState.gameSession {
                    GameScreenView(session: session)
                } else {
                    ZStack {
                        GameTheme.darkNavy.ignoresSafeArea()
                        Text("No active game").foregroundColor(.white)
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(AppState())
        .modelContainer(for: PlayerProfile.self, inMemory: true)
}
