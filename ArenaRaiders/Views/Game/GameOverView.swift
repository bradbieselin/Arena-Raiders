import SwiftUI
import SwiftData

/// Full-screen result overlay shown when a match ends. Persists the match
/// result (exactly once) and shows rewards plus a small stat breakdown.
struct GameOverView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    var vm: GameViewModel

    @State private var showContent = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                // Result banner
                Image(systemName: vm.didPlayerWin ? "trophy.fill" : "shield.slash.fill")
                    .font(.system(size: 56))
                    .foregroundColor(vm.didPlayerWin ? GameTheme.gold : GameTheme.hpRed)
                    .scaleEffect(showContent ? 1 : 0.4)

                Text(vm.didPlayerWin ? "VICTORY" : "DEFEAT")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .tracking(3)
                    .foregroundColor(vm.didPlayerWin ? GameTheme.gold : GameTheme.hpRed)

                Text(vm.didPlayerWin
                     ? "\(vm.championName) triumphs!"
                     : "\(vm.winnerName) wins this time…")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))

                // Gold reward
                if vm.goldReward > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(GameTheme.gold)
                        Text("+\(vm.goldReward) Gold")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(GameTheme.gold)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(GameTheme.gold.opacity(0.12))
                    .clipShape(Capsule())
                    .accessibilityLabel("Earned \(vm.goldReward) gold")
                }

                // Match stats
                HStack(spacing: 0) {
                    statColumn(value: "\(vm.currentTurn)", label: "Turns")
                    divider
                    statColumn(value: "\(vm.chestsBroken)", label: "Chests")
                    divider
                    statColumn(value: "\(vm.damageDealtToOpponent)", label: "Damage")
                }
                .padding(.vertical, 10)
                .frame(width: 300)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Button {
                    SoundManager.shared.play(.buttonTap)
                    appState.endGame()
                } label: {
                    Text("RETURN TO MENU")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(GameTheme.darkNavy)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(GameTheme.gold)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.top, 4)
                .accessibilityLabel("Return to main menu")
            }
        }
        .onAppear {
            recordResultIfNeeded()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                showContent = true
            }
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.1))
            .frame(width: 1, height: 32)
    }

    private func statColumn(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(label.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .tracking(1)
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }

    private func recordResultIfNeeded() {
        guard !vm.didRecordResult else { return }
        SaveSystem.recordMatch(vm.buildMatchRecord(), context: modelContext)
        vm.markResultRecorded()
    }
}
