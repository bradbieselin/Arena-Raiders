import Foundation
import SwiftData

// MARK: - Active Gear (Codable wrapper for gear slot mapping)

struct ActiveGearMap: Codable, Equatable {
    private var slots: [String: Data]

    init() {
        self.slots = [:]
    }

    mutating func equip(_ card: Card, in slot: GearSlot) {
        if let encoded = try? JSONEncoder().encode(CardReference(card: card)) {
            slots[slot.rawValue] = encoded
        }
    }

    mutating func unequip(_ slot: GearSlot) {
        slots.removeValue(forKey: slot.rawValue)
    }

    func card(in slot: GearSlot) -> CardReference? {
        guard let data = slots[slot.rawValue] else { return nil }
        return try? JSONDecoder().decode(CardReference.self, from: data)
    }

    var equippedSlots: [GearSlot] {
        slots.keys.compactMap { GearSlot(rawValue: $0) }
    }

    var isEmpty: Bool {
        slots.isEmpty
    }
}

// MARK: - Card Reference (lightweight Codable card snapshot for game state)

struct CardReference: Codable, Equatable, Hashable, Identifiable {
    let id: UUID
    let name: String
    let cardType: CardType
    let gearSlot: GearSlot?
    let resourceCost: Int
    let durability: Int?
    let effectDescription: String
    let rarity: Rarity
    let isInstant: Bool

    init(card: Card) {
        self.id = card.id
        self.name = card.name
        self.cardType = card.cardType
        self.gearSlot = card.gearSlot
        self.resourceCost = card.resourceCost
        self.durability = card.durability
        self.effectDescription = card.effectDescription
        self.rarity = card.rarity
        self.isInstant = card.isInstant
    }
}

// MARK: - Champion Reference (lightweight Codable champion snapshot)

struct ChampionReference: Codable, Equatable {
    let id: UUID
    let name: String
    let hp: Int
    let avoidance: Int
    let mitigation: Int
    let innatePassive: InnatePassive
    let tierEffects: [TierEffect]
    let rarity: Rarity

    init(champion: Champion) {
        self.id = champion.id
        self.name = champion.name
        self.hp = champion.hp
        self.avoidance = champion.avoidance
        self.mitigation = champion.mitigation
        self.innatePassive = champion.innatePassive
        self.tierEffects = champion.tierEffects
        self.rarity = champion.rarity
    }
}

// MARK: - Game Session

@Model
final class GameSession {
    var id: UUID
    var phase: GamePhase

    // Player champion snapshot
    var playerChampion: ChampionReference?

    // Card zones (stored as Codable snapshots to avoid SwiftData relationship complexity)
    var playerHand: [CardReference]
    var playerDeck: [CardReference]

    // Resources & HP
    var playerResources: Int
    var playerHP: Int

    // Treasure chests
    var chestCount: Int
    var currentChestIntegrity: Int
    var currentChestTier: Int

    // Equipment state
    var activeGear: ActiveGearMap
    var activeTalents: [CardReference]

    // Metadata
    var startedAt: Date
    var endedAt: Date?
    var didPlayerWin: Bool?

    static let maxChests = 3
    static let startingResources = 3

    init(
        phase: GamePhase = .raid,
        champion: Champion? = nil,
        deck: Deck? = nil
    ) {
        self.id = UUID()
        self.phase = phase
        self.playerChampion = champion.map { ChampionReference(champion: $0) }
        self.playerHand = []
        self.playerDeck = deck?.cards.map { CardReference(card: $0) } ?? []
        self.playerResources = GameSession.startingResources
        self.playerHP = champion?.hp ?? 30
        self.chestCount = 0
        self.currentChestIntegrity = 0
        self.currentChestTier = 1
        self.activeGear = ActiveGearMap()
        self.activeTalents = []
        self.startedAt = Date()
    }

    var chestsRemaining: Int {
        GameSession.maxChests - chestCount
    }

    var isGameOver: Bool {
        playerHP <= 0 || endedAt != nil
    }
}
