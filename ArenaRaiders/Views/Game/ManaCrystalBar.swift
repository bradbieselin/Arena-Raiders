import SwiftUI

/// Mana crystals displayed as a row of filled/empty gems (like Hearthstone).
struct ManaCrystalBar: View {
    let available: Int
    let total: Int
    var pulse: Bool = false
    private let maxVisible = 10

    private var visibleCount: Int {
        min(total, maxVisible)
    }

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<visibleCount, id: \.self) { i in
                Image(systemName: "diamond.fill")
                    .font(.system(size: 12))
                    .foregroundColor(
                        i < available
                            ? GameTheme.manaBlue
                            : Color.white.opacity(0.15)
                    )
                    .shadow(
                        color: i < available ? GameTheme.manaBlue.opacity(0.6) : .clear,
                        radius: 3
                    )
                    .scaleEffect(pulse && i < available ? 1.2 : 1.0)
                    .animation(
                        pulse ? .easeInOut(duration: 0.2).delay(Double(i) * 0.05) : .default,
                        value: pulse
                    )
            }

            if total > maxVisible {
                Text("+\(total - maxVisible)")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(GameTheme.manaBlue)
            }
        }
    }
}
