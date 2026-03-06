import SwiftUI

/// Circular champion portrait with HP bar beneath, like MTGA.
struct ChampionPortraitView: View {
    let name: String
    let currentHP: Int
    let maxHP: Int
    let accentColor: Color
    let label: String // "YOU" or "AI"

    var body: some View {
        VStack(spacing: 6) {
            // Circular avatar frame
            ZStack {
                // Outer ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.4)],
                            startPoint: .top, endPoint: .bottom
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 62, height: 62)

                // Inner fill
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [GameTheme.surfaceDark, GameTheme.deepNavy],
                            center: .center,
                            startRadius: 0,
                            endRadius: 30
                        )
                    )
                    .frame(width: 56, height: 56)

                // Portrait icon
                Image(systemName: "person.fill")
                    .font(.system(size: 24))
                    .foregroundColor(accentColor)
            }
            .shadow(color: accentColor.opacity(0.3), radius: 6)

            // Name
            Text(name)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)

            // HP bar with number
            VStack(spacing: 2) {
                HPBarView(current: currentHP, max: maxHP, height: 10)
                    .frame(width: 70)
                Text("\(currentHP) HP")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundColor(hpTextColor)
            }
        }
    }

    private var hpTextColor: Color {
        let fraction = maxHP > 0 ? Double(currentHP) / Double(maxHP) : 0
        if fraction > 0.5 { return GameTheme.hpGreen }
        if fraction > 0.25 { return .orange }
        return GameTheme.hpRed
    }
}
