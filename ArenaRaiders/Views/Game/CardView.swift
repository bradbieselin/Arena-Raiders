import SwiftUI

struct CardView: View {
    let card: CardReference
    var isSelected: Bool = false
    var isAffordable: Bool = true

    var body: some View {
        VStack(spacing: 4) {
            // Cost top-left
            HStack {
                Text("\(card.resourceCost)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(GameTheme.gold)
                Spacer()
            }

            Spacer()

            // Name centered
            Text(card.name)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Spacer()

            // Type bottom-center
            Text(card.cardType.displayName)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(6)
        .frame(width: 70, height: 100)
        .background(GameTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isSelected ? GameTheme.gold : Color.white.opacity(0.2),
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .opacity(isAffordable ? 1.0 : 0.5)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
