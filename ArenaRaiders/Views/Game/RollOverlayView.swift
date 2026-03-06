import SwiftUI

struct RollOverlayView: View {
    let rollValue: Int
    let label: String
    let labelColor: Color

    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0

    var body: some View {
        VStack(spacing: 8) {
            Text("\(rollValue)")
                .font(.system(size: 96, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.8)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .shadow(color: labelColor.opacity(0.6), radius: 20)

            Text(label)
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundColor(labelColor)
                .shadow(color: labelColor.opacity(0.5), radius: 10)
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}
