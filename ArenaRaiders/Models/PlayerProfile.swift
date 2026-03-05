import Foundation
import SwiftData

// MARK: - Owned Card Entry (tracks quantity of each card owned)

struct OwnedCardEntry: Codable, Equatable, Hashable, Identifiable {
    let cardId: UUID
    let cardStringId: String
    let cardName: String
    var quantity: Int

    var id: UUID { cardId }

    init(card: Card, quantity: Int = 1) {
        self.cardId = card.id
        self.cardStringId = card.stringId
        self.cardName = card.name
        self.quantity = quantity
    }
}

// MARK: - Player Profile

@Model
final class PlayerProfile {
    var id: UUID
    var displayName: String
    var totalWins: Int
    var totalLosses: Int
    var currency: Int
    var hasRemovedAds: Bool
    var createdAt: Date
    var hasCompletedFirstLaunch: Bool

    // Card collection stored as Codable array with quantities
    var cardCollection: [OwnedCardEntry]

    @Relationship(deleteRule: .cascade)
    var unlockedChampions: [Champion]

    @Relationship(deleteRule: .cascade)
    var savedDecks: [Deck]

    init(
        displayName: String = "Raider",
        currency: Int = 500
    ) {
        self.id = UUID()
        self.displayName = displayName
        self.totalWins = 0
        self.totalLosses = 0
        self.currency = currency
        self.hasRemovedAds = false
        self.createdAt = Date()
        self.hasCompletedFirstLaunch = false
        self.cardCollection = []
        self.unlockedChampions = []
        self.savedDecks = []
    }

    // MARK: - Computed Properties

    var totalGames: Int {
        totalWins + totalLosses
    }

    var winRate: Double {
        guard totalGames > 0 else { return 0 }
        return Double(totalWins) / Double(totalGames)
    }

    // MARK: - Collection Management

    func addCard(_ card: Card, quantity: Int = 1) {
        if let index = cardCollection.firstIndex(where: { $0.cardStringId == card.stringId }) {
            cardCollection[index].quantity += quantity
        } else {
            cardCollection.append(OwnedCardEntry(card: card, quantity: quantity))
        }
    }

    func removeCard(_ card: Card, quantity: Int = 1) {
        guard let index = cardCollection.firstIndex(where: { $0.cardStringId == card.stringId }) else { return }
        cardCollection[index].quantity -= quantity
        if cardCollection[index].quantity <= 0 {
            cardCollection.remove(at: index)
        }
    }

    func quantityOwned(of card: Card) -> Int {
        cardCollection.first(where: { $0.cardStringId == card.stringId })?.quantity ?? 0
    }

    var uniqueCardsOwned: Int {
        cardCollection.count
    }

    var totalCardsOwned: Int {
        cardCollection.reduce(0) { $0 + $1.quantity }
    }
}
