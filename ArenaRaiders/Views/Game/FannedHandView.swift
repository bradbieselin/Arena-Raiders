import SwiftUI

/// Displays cards fanned along the bottom edge like a real hand of cards.
/// Cards tilt outward from center; selected card lifts up and glows.
struct FannedHandView: View {
    let cards: [CardReference]
    let selectedCardID: UUID?
    let playerResources: Int
    let onTapCard: (CardReference) -> Void

    // Fan geometry
    private let maxFanAngle: Double = 20   // total spread in degrees
    private let liftAmount: CGFloat = -30  // how far selected card lifts
    private let cardOverlap: CGFloat = 55  // horizontal overlap

    // Idle float
    @State private var floatOffset: CGFloat = 0

    var body: some View {
        HStack(spacing: -cardOverlap) {
            ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                let isSelected = selectedCardID == card.id
                let isAffordable = card.resourceCost <= playerResources
                let angle = fanAngle(index: index, total: cards.count)

                CardView(
                    card: card,
                    isSelected: isSelected,
                    isAffordable: isAffordable
                )
                .rotationEffect(.degrees(angle), anchor: .bottom)
                .offset(y: isSelected ? liftAmount : floatOffset)
                .zIndex(isSelected ? 100 : Double(index))
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                .onTapGesture { onTapCard(card) }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                floatOffset = -3
            }
        }
    }

    private func fanAngle(index: Int, total: Int) -> Double {
        guard total > 1 else { return 0 }
        let step = maxFanAngle / Double(total - 1)
        return -maxFanAngle / 2.0 + step * Double(index)
    }
}
