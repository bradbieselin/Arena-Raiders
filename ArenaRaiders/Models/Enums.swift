import Foundation

// MARK: - Rarity

enum Rarity: String, Codable, CaseIterable, Comparable {
    case common = "Common"
    case rare = "Rare"
    case epic = "Epic"
    case legendary = "Legendary"

    private var sortOrder: Int {
        switch self {
        case .common: return 0
        case .rare: return 1
        case .epic: return 2
        case .legendary: return 3
        }
    }

    static func < (lhs: Rarity, rhs: Rarity) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }

    var displayName: String { rawValue }

    /// Pack pull weight (percentage)
    var pullWeight: Double {
        switch self {
        case .common: return 0.60
        case .rare: return 0.25
        case .epic: return 0.12
        case .legendary: return 0.03
        }
    }
}

// MARK: - Card Type

enum CardType: String, Codable, CaseIterable {
    case gear = "Gear"
    case talent = "Talent"
    case ability = "Ability"
    case adventure = "Adventure"

    var displayName: String { rawValue }
}

// MARK: - Card Subtype

enum CardSubtype: String, Codable, CaseIterable {
    case sabotage = "Sabotage"

    var displayName: String { rawValue }
}

// MARK: - Gear Slot

enum GearSlot: String, Codable, CaseIterable {
    case head = "Head"
    case chest = "Chest"
    case hands = "Hands"
    case feet = "Feet"
    case weapon = "Weapon"

    var displayName: String { rawValue }
}

// MARK: - Champion Archetype

enum Archetype: String, Codable, CaseIterable {
    case warrior = "Warrior"
    case rogue = "Rogue"
    case mage = "Mage"
    case paladin = "Paladin"
    case berserker = "Berserker"
    case shadow = "Shadow"

    var displayName: String { rawValue }
}

// MARK: - Game Phase

enum GamePhase: String, Codable, CaseIterable {
    case raid = "Raid"
    case arena = "Arena"

    var displayName: String { rawValue }
}

// MARK: - Deck Building Rules

enum DeckRules {
    static let deckSize = 40
    static let maxCopiesPerCard = 2
    static let requiredChampion = true
}
