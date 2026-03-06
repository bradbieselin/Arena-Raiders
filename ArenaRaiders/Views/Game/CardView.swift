import SwiftUI

struct CardView: View {
    let card: CardReference
    var isSelected: Bool = false
    var isAffordable: Bool = true

    @State private var legendaryPulse: Bool = false

    private var glowColor: Color {
        isSelected ? GameTheme.gold : GameTheme.rarityColor(card.rarity)
    }

    private var glowRadius: CGFloat {
        if isSelected { return 12 }
        return GameTheme.rarityGlowRadius(card.rarity)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top 60%: Card art area with type icon
            ZStack(alignment: .topLeading) {
                // Art background
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [
                                GameTheme.surfaceDark,
                                GameTheme.cardBackground.opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 72)

                // Card type icon centered
                cardIcon
                    .font(.system(size: 28))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white.opacity(0.9), .white.opacity(0.5)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Cost gem (top-left)
                ZStack {
                    Image(systemName: "diamond.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [GameTheme.manaBlue, GameTheme.manaBlue.opacity(0.6)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                    Text("\(card.resourceCost)")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
                .offset(x: 3, y: 3)
            }
            .frame(height: 72)

            // Name banner (middle)
            Text(card.name)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .frame(height: 22)
                .background(Color.black.opacity(0.5))

            // Bottom 30%: Effect text + durability
            VStack(spacing: 2) {
                Text(card.effectDescription)
                    .font(.system(size: 7, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                // Durability pips
                if let dur = card.durability, let maxDur = card.maxDurability, maxDur > 0 {
                    durabilityPips(current: dur, max: maxDur)
                }

                // Type label
                Text(card.cardType.displayName)
                    .font(.system(size: 7, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 3)
            .frame(height: 36)
        }
        .frame(width: 80, height: 130)
        .background(GameTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(glowColor.opacity(isSelected ? 1.0 : 0.6), lineWidth: isSelected ? 2 : 1)
        )
        .shadow(color: glowColor.opacity(isSelected ? 0.8 : 0.3), radius: glowRadius)
        // Legendary pulse
        .shadow(
            color: card.rarity == .legendary ? GameTheme.gold.opacity(legendaryPulse ? 0.5 : 0.1) : .clear,
            radius: legendaryPulse ? 14 : 4
        )
        // Unaffordable overlay
        .overlay(
            Group {
                if !isAffordable {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.5))
                        Image(systemName: "lock.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
        )
        .scaleEffect(isSelected ? 1.08 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .onAppear {
            if card.rarity == .legendary {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    legendaryPulse = true
                }
            }
        }
    }

    private func durabilityPips(current: Int, max: Int) -> some View {
        HStack(spacing: 3) {
            ForEach(0..<max, id: \.self) { i in
                Circle()
                    .fill(i < current ? GameTheme.gold : Color.white.opacity(0.15))
                    .frame(width: 4, height: 4)
            }
        }
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
