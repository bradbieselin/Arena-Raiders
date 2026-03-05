import Foundation
import SwiftData

// MARK: - Tier Effect

struct TierEffect: Codable, Equatable, Hashable {
    let tier: Int
    let description: String
    let effect: PassiveEffect

    init(tier: Int, description: String, effect: PassiveEffect) {
        precondition(tier >= 1 && tier <= 2, "Tier must be 1 or 2")
        self.tier = tier
        self.description = description
        self.effect = effect
    }
}

// MARK: - Innate Passive

struct InnatePassive: Codable, Equatable, Hashable {
    let description: String
    let effect: PassiveEffect
}

// MARK: - Champion

@Model
final class Champion {
    #Unique<Champion>([\.name])

    var id: UUID
    var name: String
    var hp: Int
    var avoidance: Int
    var mitigation: Int
    var innatePassive: InnatePassive
    var tierEffects: [TierEffect]
    var rarity: Rarity

    init(
        name: String,
        hp: Int,
        avoidance: Int,
        mitigation: Int,
        innatePassive: InnatePassive,
        tierEffects: [TierEffect] = [],
        rarity: Rarity = .common
    ) {
        precondition(tierEffects.count <= 2, "Champion can have at most 2 tier effects")
        self.id = UUID()
        self.name = name
        self.hp = hp
        self.avoidance = avoidance
        self.mitigation = mitigation
        self.innatePassive = innatePassive
        self.tierEffects = tierEffects
        self.rarity = rarity
    }

    func tierEffect(for tier: Int) -> TierEffect? {
        tierEffects.first { $0.tier == tier }
    }
}
