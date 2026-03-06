import SwiftUI

struct RollOverlayView: View {
    let rollValue: Int
    let label: String
    let labelColor: Color

    @State private var scale: CGFloat = 2.5
    @State private var opacity: Double = 0
    @State private var labelOpacity: Double = 0

    var body: some View {
        VStack(spacing: 8) {
            // D20 result — slams in large then bounces to size
            Text("\(rollValue)")
                .font(.system(size: 96, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.8)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .shadow(color: labelColor.opacity(0.8), radius: 24)
                .shadow(color: labelColor.opacity(0.4), radius: 40)
                .shadow(color: .black.opacity(0.5), radius: 4, y: 4)

            // Label (HIT / MISS / CRIT!)
            Text(label)
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundColor(labelColor)
                .shadow(color: labelColor.opacity(0.6), radius: 12)
                .opacity(labelOpacity)
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            // Slam in with overshoot bounce
            withAnimation(.spring(response: 0.25, dampingFraction: 0.5, blendDuration: 0)) {
                scale = 1.0
                opacity = 1.0
            }
            // Label fades in slightly after
            withAnimation(.easeOut(duration: 0.2).delay(0.2)) {
                labelOpacity = 1.0
            }
        }
    }
}
