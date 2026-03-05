import SwiftUI

struct ShopView: View {
    private let darkNavy = Color(red: 15/255, green: 23/255, blue: 42/255)
    private let gold = Color(red: 255/255, green: 215/255, blue: 0/255)

    var body: some View {
        NavigationStack {
            ZStack {
                darkNavy.ignoresSafeArea()

                VStack(spacing: 20) {
                    Spacer()

                    Image(systemName: "cart.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(gold.opacity(0.5))

                    Text("Shop")
                        .font(.title2.bold())
                        .foregroundColor(.white)

                    Text("Card packs and items coming soon")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Spacer()
                }
            }
            .navigationTitle("Shop")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

#Preview {
    ShopView()
}
