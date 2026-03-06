import SwiftUI

/// Hearthstone-style turn indicator pill at top center.
struct TurnBanner: View {
    let isPlayerTurn: Bool

    @State private var glow: Bool = false

    private var fillGradient: LinearGradient {
        if isPlayerTurn {
            return LinearGradient(
                colors: [GameTheme.gold, GameTheme.darkGold],
                startPoint: .leading, endPoint: .trailing
            )
        } else {
            return LinearGradient(
                colors: [GameTheme.stoneGray, GameTheme.stoneDark],
                startPoint: .leading, endPoint: .trailing
            )
        }
    }

    private var strokeColor: Color {
        isPlayerTurn ? GameTheme.gold.opacity(0.8) : Color.white.opacity(0.1)
    }

    var body: some View {
        Text(isPlayerTurn ? "YOUR TURN" : "OPPONENT'S TURN")
            .font(.system(size: 11, weight: .black, design: .rounded))
            .tracking(2)
            .foregroundColor(isPlayerTurn ? GameTheme.darkNavy : .white.opacity(0.7))
            .padding(.horizontal, 20)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(fillGradient)
            )
            .overlay(
                Capsule().stroke(strokeColor, lineWidth: 1)
            )
            .shadow(
                color: isPlayerTurn ? GameTheme.gold.opacity(glow ? 0.6 : 0.2) : .clear,
                radius: glow ? 10 : 4
            )
            .onAppear {
                if isPlayerTurn {
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        glow = true
                    }
                }
            }
            .onChange(of: isPlayerTurn) {
                glow = false
                if isPlayerTurn {
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        glow = true
                    }
                }
            }
    }
}
