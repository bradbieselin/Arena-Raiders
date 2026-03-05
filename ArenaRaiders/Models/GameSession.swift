import Foundation

// MARK: - Active Gear (Codable wrapper for gear slot mapping)

struct ActiveGearMap: Codable, Equatable {
    private var slots: [String: Data]

    init() {
        self.slots = [:]
    }

    mutating func equip(_ card: Card, in slot: GearSlot) {
        equipRef(CardReference(card: card), in: slot)
    }

    mutating func equipRef(_ ref: CardReference, in slot: GearSlot) {
        if let encoded = try? JSONEncoder().encode(ref) {
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

    var allEquippedCards: [CardReference] {
        equippedSlots.compactMap { card(in: $0) }
    }

    var isEmpty: Bool {
        slots.isEmpty
    }

    var equippedCount: Int {
        slots.count
    }
}

// MARK: - Card Reference (lightweight Codable card snapshot for game state)

struct CardReference: Codable, Equatable, Hashable, Identifiable {
    let id: UUID
    let stringId: String
    let name: String
    let cardType: CardType
    let subtype: CardSubtype?
    let gearSlot: GearSlot?
    let resourceCost: Int
    var durability: Int?
    let maxDurability: Int?
    let effectDescription: String
    let rarity: Rarity
    let isInstant: Bool
    let isTwoHanded: Bool
    let turnsToComplete: Int?

    init(card: Card) {
        self.id = card.id
        self.stringId = card.stringId
        self.name = card.name
        self.cardType = card.cardType
        self.subtype = card.subtype
        self.gearSlot = card.gearSlot
        self.resourceCost = card.resourceCost
        self.durability = card.durability
        self.maxDurability = card.durability
        self.effectDescription = card.effectDescription
        self.rarity = card.rarity
        self.isInstant = card.isInstant
        self.isTwoHanded = card.isTwoHanded
        self.turnsToComplete = card.turnsToComplete
    }

    var isGear: Bool { cardType == .gear }
    var isTalent: Bool { cardType == .talent }
    var isAbility: Bool { cardType == .ability }
    var isAdventure: Bool { cardType == .adventure }
    var isSabotage: Bool { subtype == .sabotage }
}

// MARK: - Champion Reference (lightweight Codable champion snapshot)

struct ChampionReference: Codable, Equatable {
    let id: UUID
    let stringId: String
    let name: String
    let archetype: Archetype
    let hp: Int
    let avoidance: Int
    let mitigation: Int
    let innatePassive: InnatePassive
    let tierEffects: [TierEffect]
    let rarity: Rarity

    init(champion: Champion) {
        self.id = champion.id
        self.stringId = champion.stringId
        self.name = champion.name
        self.archetype = champion.archetype
        self.hp = champion.hp
        self.avoidance = champion.avoidance
        self.mitigation = champion.mitigation
        self.innatePassive = champion.innatePassive
        self.tierEffects = champion.tierEffects
        self.rarity = champion.rarity
    }
}

// MARK: - Active Adventure (tracks in-progress adventure cards)

struct ActiveAdventure: Codable, Equatable {
    let card: CardReference
    var turnsRemaining: Int
    var hitsDuringAdventure: Int

    init(card: CardReference) {
        self.card = card
        self.turnsRemaining = card.turnsToComplete ?? 0
        self.hitsDuringAdventure = 0
    }

    var isComplete: Bool { turnsRemaining <= 0 }
}

// MARK: - Status Effect (poison, bleed, etc.)

struct StatusEffect: Codable, Equatable {
    let type: StatusEffectType
    var turnsRemaining: Int
    let damagePerTurn: Int

    var isExpired: Bool { turnsRemaining <= 0 }
}

enum StatusEffectType: String, Codable {
    case poison
    case bleed
    case mitigationReduction
    case disadvantage
}

// MARK: - Game Session

final class GameSession {
    var id: UUID
    var phase: GamePhase

    // Player champion snapshot
    var playerChampion: ChampionReference?

    // Card zones
    var playerHand: [CardReference]
    var playerDeck: [CardReference]
    var playerDiscard: [CardReference]

    // Resources & HP
    var playerResources: Int
    var playerHP: Int
    var playerMaxHP: Int

    // Treasure chests
    var chestCount: Int
    var currentChestIntegrity: Int
    var currentChestTier: Int

    // Equipment state
    var activeGear: ActiveGearMap
    var activeTalents: [CardReference]
    var activeAdventures: [ActiveAdventure]

    // Status effects on player and opponent
    var playerStatusEffects: [StatusEffect]
    var opponentStatusEffects: [StatusEffect]

    // Tracking flags for once-per-game effects
    var firstBloodUsed: Bool
    var perfectDodgeUsed: Bool
    var goldweaveMittsUsed: Bool
    var ironWillTriggered: Bool

    // Turn tracking
    var currentTurn: Int
    var consecutiveHits: Int
    var handSizeBonus: Int

    // Metadata
    var startedAt: Date
    var endedAt: Date?
    var didPlayerWin: Bool?

    static let maxChests = 3
    static let startingResources = 3
    static let defaultHandSize = 5

    init(
        phase: GamePhase = .raid,
        champion: Champion? = nil,
        deckCards: [CardReference] = []
    ) {
        self.id = UUID()
        self.phase = phase
        self.playerChampion = champion.map { ChampionReference(champion: $0) }
        self.playerHand = []
        self.playerDeck = deckCards
        self.playerDiscard = []
        self.playerResources = GameSession.startingResources
        self.playerHP = champion?.hp ?? 30
        self.playerMaxHP = champion?.hp ?? 30
        self.chestCount = 0
        self.currentChestIntegrity = 0
        self.currentChestTier = 1
        self.activeGear = ActiveGearMap()
        self.activeTalents = []
        self.activeAdventures = []
        self.playerStatusEffects = []
        self.opponentStatusEffects = []
        self.firstBloodUsed = false
        self.perfectDodgeUsed = false
        self.goldweaveMittsUsed = false
        self.ironWillTriggered = false
        self.currentTurn = 1
        self.consecutiveHits = 0
        self.handSizeBonus = 0
        self.startedAt = Date()
    }

    var chestsRemaining: Int {
        GameSession.maxChests - chestCount
    }

    var isGameOver: Bool {
        playerHP <= 0 || endedAt != nil
    }

    var effectiveHandSize: Int {
        GameSession.defaultHandSize + handSizeBonus
    }
}
