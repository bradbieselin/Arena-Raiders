import SwiftUI

struct GearSlotsView: View {
    let gear: ActiveGearMap
    var compact: Bool = false

    private let slots: [GearSlot] = [.head, .chest, .hands, .feet, .weapon]

    var body: some View {
        HStack(spacing: compact ? 6 : 10) {
            ForEach(slots, id: \.self) { slot in
                gearSlotIcon(slot)
            }
        }
    }

    @ViewBuilder
    private func gearSlotIcon(_ slot: GearSlot) -> some View {
        let equipped = gear.card(in: slot)
        let size: CGFloat = compact ? 28 : 36

        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(equipped != nil ? GameTheme.cardBackground : Color.black.opacity(0.3))
                .frame(width: size, height: size)

            if let card = equipped {
                Image(systemName: iconFor(slot))
                    .font(.system(size: size * 0.4))
                    .foregroundColor(GameTheme.rarityColor(card.rarity))
            } else {
                Image(systemName: iconFor(slot))
                    .font(.system(size: size * 0.35))
                    .foregroundColor(.white.opacity(0.2))
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(
                    equipped.map { GameTheme.rarityColor($0.rarity) } ?? Color.white.opacity(0.1),
                    lineWidth: 1
                )
        )
    }

    private func iconFor(_ slot: GearSlot) -> String {
        switch slot {
        case .head: return "crown.fill"
        case .chest: return "tshirt.fill"
        case .hands: return "hand.raised.fill"
        case .feet: return "shoe.fill"
        case .weapon: return "swift"
        }
    }
}
