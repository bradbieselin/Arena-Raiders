import Foundation
import SwiftData

enum CardRarity: String, Codable, CaseIterable {
    case common
    case rare
    case epic
    case legendary
}

enum CardType: String, Codable, CaseIterable {
    case warrior
    case mage
    case archer
    case spell
    case trap
}

@Model
final class Card {
    var id: UUID
    var name: String
    var cardDescription: String
    var cardType: CardType
    var rarity: CardRarity
    var manaCost: Int
    var attack: Int
    var health: Int
    var imageName: String
    var isUnlocked: Bool

    var owner: PlayerProfile?

    init(
        name: String,
        cardDescription: String = "",
        cardType: CardType = .warrior,
        rarity: CardRarity = .common,
        manaCost: Int = 1,
        attack: Int = 1,
        health: Int = 1,
        imageName: String = "card_placeholder"
    ) {
        self.id = UUID()
        self.name = name
        self.cardDescription = cardDescription
        self.cardType = cardType
        self.rarity = rarity
        self.manaCost = manaCost
        self.attack = attack
        self.health = health
        self.imageName = imageName
        self.isUnlocked = true
    }
}
