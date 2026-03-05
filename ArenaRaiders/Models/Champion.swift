import Foundation
import SwiftData

// MARK: - Tier Effect

struct TierEffect: Codable, Equatable, Hashable {
    let tier: Int
    let name: String
    let effectDescription: String

    enum CodingKeys: String, CodingKey {
        case tier, name
        case effectDescription = "description"
    }

    init(tier: Int, name: String, effectDescription: String) {
        self.tier = tier
        self.name = name
        self.effectDescription = effectDescription
    }
}

// MARK: - Innate Passive

struct InnatePassive: Codable, Equatable, Hashable {
    let name: String
    let effectDescription: String

    enum CodingKeys: String, CodingKey {
        case name
        case effectDescription = "description"
    }
}

// MARK: - Champion

@Model
final class Champion {
    var id: UUID
    var stringId: String
    var name: String
    var archetype: Archetype
    var hp: Int
    var avoidance: Int
    var mitigation: Int
    var innatePassive: InnatePassive
    var tierEffects: [TierEffect]
    var rarity: Rarity
    var flavorText: String

    init(
        stringId: String,
        name: String,
        archetype: Archetype,
        hp: Int,
        avoidance: Int,
        mitigation: Int,
        innatePassive: InnatePassive,
        tierEffects: [TierEffect] = [],
        rarity: Rarity = .common,
        flavorText: String = ""
    ) {
        self.id = UUID()
        self.stringId = stringId
        self.name = name
        self.archetype = archetype
        self.hp = hp
        self.avoidance = avoidance
        self.mitigation = mitigation
        self.innatePassive = innatePassive
        self.tierEffects = tierEffects
        self.rarity = rarity
        self.flavorText = flavorText
    }

    func tierEffect(for tier: Int) -> TierEffect? {
        tierEffects.first { $0.tier == tier }
    }
}
