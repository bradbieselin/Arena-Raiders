import SwiftUI

struct GameScreenView: View {
    @Environment(AppState.self) private var appState
    @State private var vm: GameViewModel

    init(session: GameSession) {
        _vm = State(initialValue: GameViewModel(session: session))
    }

    var body: some View {
        ZStack {
            // Textured game board background
            GameBoardBackground()

            VStack(spacing: 0) {
                // Turn indicator pill (top center)
                TurnBanner(isPlayerTurn: true)
                    .padding(.top, 6)

                // Phase content
                switch vm.phase {
                case .raid:
                    RaidPhaseView(vm: vm)
                case .arena:
                    ArenaPhaseView(vm: vm)
                }
            }

            // Game over overlay
            if vm.isGameOver {
                gameOverOverlay
            }
        }
    }

    // MARK: - Game Over

    private var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 60))
                    .foregroundColor(GameTheme.gold)
                    .shadow(color: GameTheme.gold.opacity(0.5), radius: 16)

                Text("VICTORY")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundColor(GameTheme.gold)

                Text("\(vm.winnerName) wins!")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))

                Button(action: { appState.endGame() }) {
                    Text("RETURN TO MENU")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(GameTheme.darkNavy)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(GameTheme.gold)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: GameTheme.gold.opacity(0.4), radius: 8)
                }
                .padding(.top, 8)
            }
        }
        .transition(.opacity)
    }
}
