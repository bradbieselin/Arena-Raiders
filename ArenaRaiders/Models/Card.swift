import Foundation
import SwiftData

@Model
final class Card {
    #Unique<Card>([\.name])

    var id: UUID
    var name: String
    var cardType: CardType
    var gearSlot: GearSlot?
    var resourceCost: Int
    var durability: Int?
    var effectDescription: String
    var rarity: Rarity
    var isInstant: Bool

    init(
        name: String,
        cardType: CardType,
        gearSlot: GearSlot? = nil,
        resourceCost: Int = 1,
        durability: Int? = nil,
        effectDescription: String = "",
        rarity: Rarity = .common,
        isInstant: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.cardType = cardType
        self.gearSlot = gearSlot
        self.resourceCost = resourceCost
        self.durability = durability
        self.effectDescription = effectDescription
        self.rarity = rarity
        self.isInstant = isInstant

        // Validate gear cards must have a slot
        if cardType == .gear {
            precondition(gearSlot != nil, "Gear cards must specify a gearSlot")
        }

        // Talents don't have durability
        if cardType == .talent {
            self.durability = nil
        }
    }

    var isGear: Bool { cardType == .gear }
    var isTalent: Bool { cardType == .talent }
    var isAbility: Bool { cardType == .ability }
    var isAdventure: Bool { cardType == .adventure }
}
