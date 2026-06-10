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

// MARK: - Match Record (one entry per completed game)

struct MatchRecord: Codable, Equatable, Hashable, Identifiable {
    let id: UUID
    let date: Date
    let didWin: Bool
    let championName: String
    let opponentName: String
    let turnsPlayed: Int
    let chestsBroken: Int
    let goldEarned: Int

    init(
        didWin: Bool,
        championName: String,
        opponentName: String,
        turnsPlayed: Int,
        chestsBroken: Int,
        goldEarned: Int,
        date: Date = Date()
    ) {
        self.id = UUID()
        self.date = date
        self.didWin = didWin
        self.championName = championName
        self.opponentName = opponentName
        self.turnsPlayed = turnsPlayed
        self.chestsBroken = chestsBroken
        self.goldEarned = goldEarned
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

    // Meta progression
    var currentWinStreak: Int = 0
    var bestWinStreak: Int = 0
    var packsOpened: Int = 0
    var lastDailyBonusClaim: Date?

    // Recent match results (newest first, capped by SaveSystem)
    var matchHistory: [MatchRecord] = []

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
        self.currentWinStreak = 0
        self.bestWinStreak = 0
        self.packsOpened = 0
        self.lastDailyBonusClaim = nil
        self.matchHistory = []
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
