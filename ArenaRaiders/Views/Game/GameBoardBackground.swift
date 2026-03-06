import SwiftUI

/// Rich textured game board background — dark stone edges, felt center.
struct GameBoardBackground: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Base: deep dark gradient
                LinearGradient(
                    colors: [
                        GameTheme.deepNavy,
                        Color(red: 12/255, green: 18/255, blue: 35/255),
                        GameTheme.deepNavy
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Stone border effect (darker edges)
                RadialGradient(
                    colors: [
                        Color.clear,
                        GameTheme.stoneDark.opacity(0.4),
                        GameTheme.stoneDark.opacity(0.8)
                    ],
                    center: .center,
                    startRadius: geo.size.width * 0.2,
                    endRadius: geo.size.width * 0.7
                )

                // Felt center play area (subtle green tint)
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                GameTheme.feltGreen.opacity(0.15),
                                GameTheme.feltDark.opacity(0.08),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: geo.size.width * 0.4
                        )
                    )
                    .frame(width: geo.size.width * 0.7, height: geo.size.height * 0.6)

                // Subtle noise texture using overlapping shapes
                ForEach(0..<6, id: \.self) { i in
                    Circle()
                        .fill(Color.white.opacity(0.008))
                        .frame(
                            width: CGFloat(80 + i * 40),
                            height: CGFloat(80 + i * 40)
                        )
                        .offset(
                            x: CGFloat([-60, 100, -30, 70, -90, 50][i]),
                            y: CGFloat([40, -60, 80, -20, -50, 30][i])
                        )
                }

                // Gold trim line across center (dividing player zones)
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                GameTheme.gold.opacity(0.08),
                                GameTheme.gold.opacity(0.12),
                                GameTheme.gold.opacity(0.08),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                    .offset(y: -10)
            }
        }
        .ignoresSafeArea()
    }
}
