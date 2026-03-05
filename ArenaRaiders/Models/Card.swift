import Foundation
import SwiftData

@Model
final class Card {
    var id: UUID
    var stringId: String
    var name: String
    var cardType: CardType
    var subtype: CardSubtype?
    var gearSlot: GearSlot?
    var resourceCost: Int
    var durability: Int?
    var effectDescription: String
    var rarity: Rarity
    var isInstant: Bool
    var isTwoHanded: Bool
    var turnsToComplete: Int?
    var flavorText: String

    init(
        stringId: String,
        name: String,
        cardType: CardType,
        subtype: CardSubtype? = nil,
        gearSlot: GearSlot? = nil,
        resourceCost: Int = 1,
        durability: Int? = nil,
        effectDescription: String = "",
        rarity: Rarity = .common,
        isInstant: Bool = false,
        isTwoHanded: Bool = false,
        turnsToComplete: Int? = nil,
        flavorText: String = ""
    ) {
        self.id = UUID()
        self.stringId = stringId
        self.name = name
        self.cardType = cardType
        self.subtype = subtype
        self.gearSlot = gearSlot
        self.resourceCost = resourceCost
        self.durability = durability
        self.effectDescription = effectDescription
        self.rarity = rarity
        self.isInstant = isInstant
        self.isTwoHanded = isTwoHanded
        self.turnsToComplete = turnsToComplete
        self.flavorText = flavorText
    }

    var isGear: Bool { cardType == .gear }
    var isTalent: Bool { cardType == .talent }
    var isAbility: Bool { cardType == .ability }
    var isAdventure: Bool { cardType == .adventure }
    var isSabotage: Bool { subtype == .sabotage }
}
