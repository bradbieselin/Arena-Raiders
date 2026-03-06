import SwiftUI

struct ResourceCounterView: View {
    let amount: Int
    var pulse: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "bitcoinsign.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(GameTheme.gold)
                .scaleEffect(pulse ? 1.3 : 1.0)
                .animation(
                    pulse ? .easeInOut(duration: 0.25).repeatCount(2, autoreverses: true) : .default,
                    value: pulse
                )

            Text("\(amount)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(pulse ? GameTheme.gold : .white)
                .animation(.easeInOut(duration: 0.2), value: pulse)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(GameTheme.surfaceDark.opacity(0.8))
        .clipShape(Capsule())
    }
}
