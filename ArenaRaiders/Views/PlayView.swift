import SwiftUI

struct PlayView: View {
    @Environment(AppState.self) private var appState

    private let darkNavy = Color(red: 15/255, green: 23/255, blue: 42/255)
    private let gold = Color(red: 255/255, green: 215/255, blue: 0/255)

    var body: some View {
        NavigationStack {
            ZStack {
                darkNavy.ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()

                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 60))
                        .foregroundStyle(gold)

                    Text("Ready for Battle?")
                        .font(.title2.bold())
                        .foregroundColor(.white)

                    Button {
                        appState.startNewGame()
                    } label: {
                        Text("FIND MATCH")
                            .font(.headline)
                            .foregroundColor(darkNavy)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(gold)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 40)

                    Button {
                        // Practice mode - coming soon
                    } label: {
                        Text("PRACTICE")
                            .font(.headline)
                            .foregroundColor(gold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(gold.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(gold.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 40)

                    Spacer()
                }
            }
            .navigationTitle("Play")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

#Preview {
    PlayView()
        .environment(AppState())
}
