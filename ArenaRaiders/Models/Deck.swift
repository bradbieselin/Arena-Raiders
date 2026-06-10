import Foundation
import SwiftData

// MARK: - Deck Card Entry (tracks card + quantity in a deck)

struct DeckCardSlot: Codable, Equatable, Hashable, Identifiable {
    let cardStringId: String
    let cardName: String
    var quantity: Int

    var id: String { cardStringId }

    init(card: Card, quantity: Int = 1) {
        self.cardStringId = card.stringId
        self.cardName = card.name
        self.quantity = quantity
    }
}

@Model
final class Deck {
    var id: UUID
    var name: String
    var champion: Champion?
    var cardSlots: [DeckCardSlot]

    static let requiredCardCount = DeckRules.deckSize

    init(name: String = "New Deck", champion: Champion? = nil, cardSlots: [DeckCardSlot] = []) {
        self.id = UUID()
        self.name = name
        self.champion = champion
        self.cardSlots = cardSlots
    }

    /// Total number of cards in the deck (accounting for quantities)
    var cardCount: Int {
        cardSlots.reduce(0) { $0 + $1.quantity }
    }

    var isComplete: Bool {
        champion != nil && cardCount == Deck.requiredCardCount
    }

    var cardsNeeded: Int {
        max(0, Deck.requiredCardCount - cardCount)
    }

    var uniqueCardCount: Int {
        cardSlots.count
    }
}

// MARK: - Materialization (deck slots → playable card snapshots)

extension Deck {
    /// Expands the deck's card slots into playable `CardReference` snapshots
    /// using the full card catalog. Each copy gets a unique identity so the
    /// game can track duplicates independently. Slots referencing unknown
    /// cards are skipped.
    func materializedCards(from catalog: [Card]) -> [CardReference] {
        let cardsById = Dictionary(
            catalog.map { ($0.stringId, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        var references: [CardReference] = []
        for slot in cardSlots {
            guard let card = cardsById[slot.cardStringId] else { continue }
            for _ in 0..<max(0, slot.quantity) {
                references.append(CardReference(card: card, copyId: UUID()))
            }
        }
        return references
    }
}
