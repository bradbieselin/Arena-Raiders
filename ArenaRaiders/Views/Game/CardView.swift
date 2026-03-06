import SwiftUI

struct CardView: View {
    let card: CardReference
    var isSelected: Bool = false
    var isAffordable: Bool = true

    var body: some View {
        VStack(spacing: 4) {
            // Cost badge
            HStack {
                HStack(spacing: 2) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                        .foregroundColor(GameTheme.gold)
                    Text("\(card.resourceCost)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(GameTheme.gold)
                }
                Spacer()
                if let dur = card.durability {
                    HStack(spacing: 2) {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.white.opacity(0.7))
                        Text("\(dur)")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }

            // Card type icon
            cardIcon
                .font(.system(size: 22))
                .foregroundColor(.white.opacity(0.9))
                .frame(height: 28)

            // Name
            Text(card.name)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(height: 26)

            // Type label
            Text(card.cardType.displayName)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(8)
        .frame(width: 90, height: 120)
        .background(GameTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    isSelected ? GameTheme.gold : GameTheme.rarityColor(card.rarity),
                    lineWidth: isSelected ? 2.5 : 1.5
                )
        )
        .opacity(isAffordable ? 1.0 : 0.5)
        .scaleEffect(isSelected ? 1.08 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    @ViewBuilder
    private var cardIcon: some View {
        switch card.cardType {
        case .gear:
            if let slot = card.gearSlot {
                Image(systemName: gearIcon(slot))
            } else {
                Image(systemName: "wrench.fill")
            }
        case .talent:
            Image(systemName: "star.fill")
        case .ability:
            Image(systemName: "bolt.fill")
        case .adventure:
            Image(systemName: "map.fill")
        }
    }

    private func gearIcon(_ slot: GearSlot) -> String {
        switch slot {
        case .head: return "crown.fill"
        case .chest: return "tshirt.fill"
        case .hands: return "hand.raised.fill"
        case .feet: return "shoe.fill"
        case .weapon: return "swift"
        }
    }
}
