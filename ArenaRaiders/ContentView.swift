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
                // Game view placeholder - will be built out later
                ZStack {
                    Color(red: 15/255, green: 23/255, blue: 42/255)
                        .ignoresSafeArea()

                    VStack(spacing: 20) {
                        Text("Game In Progress")
                            .font(.title.bold())
                            .foregroundColor(.white)

                        Button("End Game") {
                            appState.endGame()
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
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
