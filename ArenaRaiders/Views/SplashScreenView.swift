import SwiftUI

struct SplashScreenView: View {
    @Environment(AppState.self) private var appState
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var titleOffset: CGFloat = 30

    private let darkNavy = Color(red: 15/255, green: 23/255, blue: 42/255)
    private let gold = Color(red: 255/255, green: 215/255, blue: 0/255)

    var body: some View {
        ZStack {
            ArtBackground(imageName: GameAssets.menuBackground, darken: 0.35)

            VStack(spacing: 32) {
                // Placeholder logo
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [gold.opacity(0.3), .clear]),
                                center: .center,
                                startRadius: 20,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)

                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [gold, gold.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                // Title
                VStack(spacing: 8) {
                    Text("ARENA")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [gold, Color(red: 218/255, green: 165/255, blue: 32/255)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("RAIDERS")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [gold, Color(red: 218/255, green: 165/255, blue: 32/255)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                .offset(y: titleOffset)
                .opacity(logoOpacity)

                // Tagline
                Text("Enter the Arena")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(gold.opacity(0.6))
                    .opacity(logoOpacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                logoScale = 1.0
                logoOpacity = 1.0
                titleOffset = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                appState.navigateTo(.main)
            }
        }
    }
}

#Preview {
    SplashScreenView()
        .environment(AppState())
}
