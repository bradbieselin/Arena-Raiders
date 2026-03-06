import SwiftUI

struct HPBarView: View {
    let current: Int
    let max: Int
    var height: CGFloat = 14
    var showCracks: Bool = false

    private var fraction: CGFloat {
        guard max > 0 else { return 0 }
        return CGFloat(current) / CGFloat(max)
    }

    private var barColor: Color {
        if fraction > 0.5 { return GameTheme.hpGreen }
        if fraction > 0.25 { return .orange }
        return GameTheme.hpRed
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color.black.opacity(0.4))

                // Fill
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(barColor)
                    .frame(width: Swift.max(0, geo.size.width * fraction))
                    .animation(.easeInOut(duration: 0.3), value: current)

                // Crack overlay for chests
                if showCracks && fraction < 1.0 {
                    crackOverlay(width: geo.size.width)
                }

                // HP text
                Text("\(current)/\(max)")
                    .font(.system(size: height * 0.7, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: height)
    }

    @ViewBuilder
    private func crackOverlay(width: CGFloat) -> some View {
        ZStack {
            if fraction < 0.7 {
                crack(at: width * 0.65)
            }
            if fraction < 0.4 {
                crack(at: width * 0.35)
            }
            if fraction < 0.15 {
                crack(at: width * 0.15)
            }
        }
        .opacity(0.6)
    }

    private func crack(at x: CGFloat) -> some View {
        Path { path in
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x - 3, y: height * 0.4))
            path.addLine(to: CGPoint(x: x + 2, y: height * 0.6))
            path.addLine(to: CGPoint(x: x - 1, y: height))
        }
        .stroke(Color.black.opacity(0.8), lineWidth: 1.5)
    }
}
