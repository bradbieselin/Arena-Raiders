import SwiftUI

/// Rich textured game board background — dark stone edges, felt center.
struct GameBoardBackground: View {
    private struct NoiseCircle {
        let size: CGFloat
        let x: CGFloat
        let y: CGFloat
    }

    private let noiseCircles: [NoiseCircle] = [
        NoiseCircle(size: 80,  x: -60, y: 40),
        NoiseCircle(size: 120, x: 100, y: -60),
        NoiseCircle(size: 160, x: -30, y: 80),
        NoiseCircle(size: 200, x: 70,  y: -20),
        NoiseCircle(size: 240, x: -90, y: -50),
        NoiseCircle(size: 280, x: 50,  y: 30),
    ]

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
                ForEach(0..<noiseCircles.count, id: \.self) { i in
                    let nc = noiseCircles[i]
                    Circle()
                        .fill(Color.white.opacity(0.008))
                        .frame(width: nc.size, height: nc.size)
                        .offset(x: nc.x, y: nc.y)
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
