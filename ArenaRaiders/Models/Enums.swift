import Foundation

// MARK: - Rarity

enum Rarity: String, Codable, CaseIterable, Comparable {
    case common
    case rare
    case epic
    case legendary

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

    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Card Type

enum CardType: String, Codable, CaseIterable {
    case gear
    case talent
    case ability
    case adventure

    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Gear Slot

enum GearSlot: String, Codable, CaseIterable {
    case head
    case chest
    case hands
    case feet
    case weapon

    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Passive Effect

enum PassiveEffect: String, Codable, CaseIterable {
    case lifeSteal
    case thorns
    case regeneration
    case shield
    case haste
    case fortify
    case evasion
    case resourceGain
    case damageBoost
    case drawExtra

    var displayName: String {
        switch self {
        case .lifeSteal: return "Life Steal"
        case .thorns: return "Thorns"
        case .regeneration: return "Regeneration"
        case .shield: return "Shield"
        case .haste: return "Haste"
        case .fortify: return "Fortify"
        case .evasion: return "Evasion"
        case .resourceGain: return "Resource Gain"
        case .damageBoost: return "Damage Boost"
        case .drawExtra: return "Draw Extra"
        }
    }
}

// MARK: - Game Phase

enum GamePhase: String, Codable, CaseIterable {
    case raid
    case arena

    var displayName: String {
        rawValue.capitalized
    }
}
