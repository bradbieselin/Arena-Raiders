import Foundation
import SwiftData

@Model
final class Deck {
    var id: UUID
    var name: String
    var champion: Champion?
    var cards: [Card]

    static let requiredCardCount = DeckRules.deckSize

    init(name: String = "New Deck", champion: Champion? = nil, cards: [Card] = []) {
        self.id = UUID()
        self.name = name
        self.champion = champion
        self.cards = cards
    }

    var isComplete: Bool {
        champion != nil && cards.count == Deck.requiredCardCount
    }

    var cardCount: Int {
        cards.count
    }

    var cardsNeeded: Int {
        max(0, Deck.requiredCardCount - cards.count)
    }
}
