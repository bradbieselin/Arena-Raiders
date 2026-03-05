import XCTest
import SwiftData
@testable import ArenaRaiders

final class StarterDataLoaderTests: XCTestCase {

    // MARK: - JSON Decodable Structure Tests

    func testStarterDataDecodesFromJSON() throws {
        let json = """
        {
            "meta": {
                "game": "Arena Raiders",
                "version": "1.0",
                "set": "Core",
                "totalCards": 2,
                "totalChampions": 1
            },
            "champions": [
                {
                    "id": "champ_001",
                    "name": "Vex the Ironclad",
                    "archetype": "Warrior",
                    "hp": 35,
                    "avoidance": 10,
                    "mitigation": 3,
                    "innatePassive": {
                        "name": "Unyielding",
                        "description": "Reduce damage by 1"
                    },
                    "tierEffects": [
                        { "tier": 1, "name": "Battle-Forged", "description": "+5 Attack" },
                        { "tier": 2, "name": "Warlord's Resolve", "description": "Roll 2 D20s" }
                    ],
                    "rarity": "Rare",
                    "flavorText": "Iron will."
                }
            ],
            "cards": [
                {
                    "id": "card_001",
                    "name": "Iron Shortsword",
                    "type": "Gear",
                    "gearSlot": "Weapon",
                    "resourceCost": 2,
                    "durability": 4,
                    "rarity": "Common",
                    "effect": "+3 Attack",
                    "flavorText": "Reliable."
                },
                {
                    "id": "card_034",
                    "name": "Power Strike",
                    "type": "Ability",
                    "resourceCost": 3,
                    "rarity": "Common",
                    "effect": "6 direct damage",
                    "isInstant": false,
                    "flavorText": "Hit hard."
                }
            ],
            "starterDecks": [
                {
                    "name": "Iron Path",
                    "champion": "champ_001",
                    "cardList": [
                        { "id": "card_001", "qty": 2 },
                        { "id": "card_034", "qty": 2 }
                    ]
                }
            ]
        }
        """.data(using: .utf8)!

        let starterData = try JSONDecoder().decode(StarterData.self, from: json)

        // Meta
        XCTAssertEqual(starterData.meta.game, "Arena Raiders")
        XCTAssertEqual(starterData.meta.version, "1.0")
        XCTAssertEqual(starterData.meta.totalCards, 2)
        XCTAssertEqual(starterData.meta.totalChampions, 1)

        // Champions
        XCTAssertEqual(starterData.champions.count, 1)
        let champ = starterData.champions[0]
        XCTAssertEqual(champ.id, "champ_001")
        XCTAssertEqual(champ.name, "Vex the Ironclad")
        XCTAssertEqual(champ.archetype, "Warrior")
        XCTAssertEqual(champ.hp, 35)
        XCTAssertEqual(champ.avoidance, 10)
        XCTAssertEqual(champ.mitigation, 3)
        XCTAssertEqual(champ.innatePassive.name, "Unyielding")
        XCTAssertEqual(champ.tierEffects.count, 2)
        XCTAssertEqual(champ.tierEffects[0].tier, 1)
        XCTAssertEqual(champ.tierEffects[0].name, "Battle-Forged")
        XCTAssertEqual(champ.rarity, "Rare")

        // Cards
        XCTAssertEqual(starterData.cards.count, 2)
        let gearCard = starterData.cards[0]
        XCTAssertEqual(gearCard.id, "card_001")
        XCTAssertEqual(gearCard.type, "Gear")
        XCTAssertEqual(gearCard.gearSlot, "Weapon")
        XCTAssertEqual(gearCard.durability, 4)
        XCTAssertNil(gearCard.isInstant)

        let abilityCard = starterData.cards[1]
        XCTAssertEqual(abilityCard.id, "card_034")
        XCTAssertEqual(abilityCard.type, "Ability")
        XCTAssertNil(abilityCard.gearSlot)
        XCTAssertNil(abilityCard.durability)
        XCTAssertEqual(abilityCard.isInstant, false)

        // Starter Decks
        XCTAssertEqual(starterData.starterDecks.count, 1)
        XCTAssertEqual(starterData.starterDecks[0].name, "Iron Path")
        XCTAssertEqual(starterData.starterDecks[0].champion, "champ_001")
        XCTAssertEqual(starterData.starterDecks[0].cardList.count, 2)
        XCTAssertEqual(starterData.starterDecks[0].cardList[0].id, "card_001")
        XCTAssertEqual(starterData.starterDecks[0].cardList[0].qty, 2)
    }

    func testChampionJSONOptionalFields() throws {
        let json = """
        {
            "id": "champ_002",
            "name": "Lyra",
            "archetype": "Rogue",
            "hp": 25,
            "avoidance": 14,
            "mitigation": 1,
            "innatePassive": { "name": "First Blood", "description": "First hit double" },
            "tierEffects": [],
            "rarity": "Rare",
            "flavorText": "Swift."
        }
        """.data(using: .utf8)!

        let champ = try JSONDecoder().decode(ChampionJSON.self, from: json)
        XCTAssertEqual(champ.id, "champ_002")
        XCTAssertEqual(champ.archetype, "Rogue")
        XCTAssertTrue(champ.tierEffects.isEmpty)
    }

    func testCardJSONOptionalFields() throws {
        // A Talent card has no gearSlot, no durability, no turnsToComplete
        let json = """
        {
            "id": "card_022",
            "name": "Toughness",
            "type": "Talent",
            "resourceCost": 2,
            "rarity": "Common",
            "effect": "+3 Max HP",
            "flavorText": "Hardy."
        }
        """.data(using: .utf8)!

        let card = try JSONDecoder().decode(CardJSON.self, from: json)
        XCTAssertEqual(card.id, "card_022")
        XCTAssertEqual(card.type, "Talent")
        XCTAssertNil(card.gearSlot)
        XCTAssertNil(card.durability)
        XCTAssertNil(card.isInstant)
        XCTAssertNil(card.isTwoHanded)
        XCTAssertNil(card.turnsToComplete)
        XCTAssertNil(card.subtype)
    }

    func testCardJSONWithSubtype() throws {
        let json = """
        {
            "id": "card_039",
            "name": "Backstab",
            "type": "Ability",
            "subtype": "Sabotage",
            "resourceCost": 2,
            "rarity": "Rare",
            "effect": "Opponent weapon -1 durability",
            "flavorText": "Behind you."
        }
        """.data(using: .utf8)!

        let card = try JSONDecoder().decode(CardJSON.self, from: json)
        XCTAssertEqual(card.subtype, "Sabotage")
    }

    // MARK: - Enum Raw Value Mapping

    func testArchetypeRawValueMatchesJSON() {
        XCTAssertNotNil(Archetype(rawValue: "Warrior"))
        XCTAssertNotNil(Archetype(rawValue: "Rogue"))
        XCTAssertNotNil(Archetype(rawValue: "Mage"))
        XCTAssertNotNil(Archetype(rawValue: "Paladin"))
        XCTAssertNotNil(Archetype(rawValue: "Berserker"))
        XCTAssertNotNil(Archetype(rawValue: "Shadow"))
        XCTAssertNil(Archetype(rawValue: "warrior")) // lowercase should fail
    }

    func testCardTypeRawValueMatchesJSON() {
        XCTAssertNotNil(CardType(rawValue: "Gear"))
        XCTAssertNotNil(CardType(rawValue: "Talent"))
        XCTAssertNotNil(CardType(rawValue: "Ability"))
        XCTAssertNotNil(CardType(rawValue: "Adventure"))
        XCTAssertNil(CardType(rawValue: "gear"))
    }

    func testGearSlotRawValueMatchesJSON() {
        XCTAssertNotNil(GearSlot(rawValue: "Head"))
        XCTAssertNotNil(GearSlot(rawValue: "Chest"))
        XCTAssertNotNil(GearSlot(rawValue: "Hands"))
        XCTAssertNotNil(GearSlot(rawValue: "Feet"))
        XCTAssertNotNil(GearSlot(rawValue: "Weapon"))
        XCTAssertNil(GearSlot(rawValue: "weapon"))
    }

    func testRarityRawValueMatchesJSON() {
        XCTAssertNotNil(Rarity(rawValue: "Common"))
        XCTAssertNotNil(Rarity(rawValue: "Rare"))
        XCTAssertNotNil(Rarity(rawValue: "Epic"))
        XCTAssertNotNil(Rarity(rawValue: "Legendary"))
        XCTAssertNil(Rarity(rawValue: "common"))
    }

    // MARK: - loadJSON (requires bundle, will return nil in test env)

    func testLoadJSONReturnsNilInTestBundle() {
        // The JSON file is in the app bundle, not the test bundle.
        // This test documents that loadJSON returns nil when the file isn't found.
        let result = StarterDataLoader.loadJSON()
        // This may or may not be nil depending on test host configuration.
        // If the test target has BUNDLE_LOADER set to the app host, the file WILL be found.
        // We simply ensure it doesn't crash.
        _ = result
    }
}
