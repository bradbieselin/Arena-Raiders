import Foundation
import SwiftData

@Model
final class Deck {
    var id: UUID
    var name: String
    var cards: [Card]
    var owner: PlayerProfile?
    var createdAt: Date

    static let maxCards = 30

    init(name: String = "New Deck", cards: [Card] = []) {
        self.id = UUID()
        self.name = name
        self.cards = cards
        self.createdAt = Date()
    }

    var isComplete: Bool {
        cards.count == Deck.maxCards
    }

    var cardCount: Int {
        cards.count
    }
}
