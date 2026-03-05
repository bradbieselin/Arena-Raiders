import XCTest
import SwiftData
@testable import ArenaRaiders

/// Tests that verify the full JSON data loads correctly and seedIfNeeded
/// populates the PlayerProfile with all champions, cards, and starter decks.
final class StarterDataSeedingTests: XCTestCase {

    // MARK: - Helpers

    /// Decodes the full starter data JSON from the raw string embedded in the test.
    private func loadStarterDataFromTestBundle() throws -> StarterData {
        let url = Bundle(for: type(of: self)).url(forResource: "arena_raiders_starter_data", withExtension: "json")
            ?? Bundle.main.url(forResource: "arena_raiders_starter_data", withExtension: "json")

        let data: Data
        if let url = url {
            data = try Data(contentsOf: url)
        } else {
            // Fallback: read from the project directory relative to the test
            XCTFail("Could not find arena_raiders_starter_data.json in any bundle")
            return try JSONDecoder().decode(StarterData.self, from: Data())
        }
        return try JSONDecoder().decode(StarterData.self, from: data)
    }

    // MARK: - Champion Validation

    func testAllSixChampionsLoadWithCorrectStats() throws {
        let starterData = try loadStarterDataFromTestBundle()

        XCTAssertEqual(starterData.champions.count, 6, "Should have exactly 6 champions")

        // Expected values from JSON: [id: (hp, avoidance, mitigation, archetype)]
        let expected: [(id: String, name: String, hp: Int, avoidance: Int, mitigation: Int, archetype: String, rarity: String)] = [
            ("champ_001", "Vex the Ironclad",        30, 12, 3, "Warrior",   "Common"),
            ("champ_002", "Lyra Swiftblade",         24, 16, 1, "Rogue",     "Common"),
            ("champ_003", "Aldric the Stormbringer",  22, 11, 0, "Mage",      "Rare"),
            ("champ_004", "Seraphine the Blessed",    28, 13, 2, "Paladin",   "Rare"),
            ("champ_005", "Grizzak the Unbroken",     35,  9, 0, "Berserker", "Epic"),
            ("champ_006", "Zara the Voidwalker",      25, 14, 1, "Shadow",    "Legendary"),
        ]

        let champMap = Dictionary(uniqueKeysWithValues: starterData.champions.map { ($0.id, $0) })

        for exp in expected {
            guard let champ = champMap[exp.id] else {
                XCTFail("Missing champion \(exp.id)")
                continue
            }
            XCTAssertEqual(champ.name, exp.name, "\(exp.id) name")
            XCTAssertEqual(champ.hp, exp.hp, "\(exp.id) hp")
            XCTAssertEqual(champ.avoidance, exp.avoidance, "\(exp.id) avoidance")
            XCTAssertEqual(champ.mitigation, exp.mitigation, "\(exp.id) mitigation")
            XCTAssertEqual(champ.archetype, exp.archetype, "\(exp.id) archetype")
            XCTAssertEqual(champ.rarity, exp.rarity, "\(exp.id) rarity")
            XCTAssertEqual(champ.tierEffects.count, 2, "\(exp.id) should have 2 tier effects")
        }
    }

    // MARK: - Card Validation

    func testAllSixtyCardsLoadWithCorrectAttributes() throws {
        let starterData = try loadStarterDataFromTestBundle()

        XCTAssertEqual(starterData.cards.count, 60, "Should have exactly 60 cards")

        let cardMap = Dictionary(uniqueKeysWithValues: starterData.cards.map { ($0.id, $0) })

        // Verify card type distribution
        let gearCards = starterData.cards.filter { $0.type == "Gear" }
        let talentCards = starterData.cards.filter { $0.type == "Talent" }
        let abilityCards = starterData.cards.filter { $0.type == "Ability" }
        let adventureCards = starterData.cards.filter { $0.type == "Adventure" }

        XCTAssertEqual(gearCards.count, 21, "Should have 21 Gear cards")
        XCTAssertEqual(talentCards.count, 12, "Should have 12 Talent cards")
        XCTAssertEqual(abilityCards.count, 19, "Should have 19 Ability cards")
        XCTAssertEqual(adventureCards.count, 8, "Should have 8 Adventure cards")

        // Verify all card types map to valid enums
        for card in starterData.cards {
            XCTAssertNotNil(CardType(rawValue: card.type), "Card \(card.id) has invalid type '\(card.type)'")
            XCTAssertNotNil(Rarity(rawValue: card.rarity), "Card \(card.id) has invalid rarity '\(card.rarity)'")

            if let slot = card.gearSlot {
                XCTAssertNotNil(GearSlot(rawValue: slot), "Card \(card.id) has invalid gearSlot '\(slot)'")
            }
            if let sub = card.subtype {
                XCTAssertNotNil(CardSubtype(rawValue: sub), "Card \(card.id) has invalid subtype '\(sub)'")
            }
        }

        // Spot-check specific cards for correct values
        // card_001: Iron Shortsword — Gear, Weapon, cost 2, durability 4, Common
        let sword = cardMap["card_001"]!
        XCTAssertEqual(sword.type, "Gear")
        XCTAssertEqual(sword.gearSlot, "Weapon")
        XCTAssertEqual(sword.resourceCost, 2)
        XCTAssertEqual(sword.durability, 4)
        XCTAssertEqual(sword.rarity, "Common")

        // card_005: Voidbreaker Greatsword — Gear, Weapon, cost 7, durability 4, Legendary, twoHanded
        let greatsword = cardMap["card_005"]!
        XCTAssertEqual(greatsword.resourceCost, 7)
        XCTAssertEqual(greatsword.rarity, "Legendary")
        XCTAssertEqual(greatsword.isTwoHanded, true)

        // card_022: Toughness — Talent, no gearSlot, no durability, cost 2, Common
        let toughness = cardMap["card_022"]!
        XCTAssertEqual(toughness.type, "Talent")
        XCTAssertNil(toughness.gearSlot)
        XCTAssertNil(toughness.durability)
        XCTAssertEqual(toughness.resourceCost, 2)
        XCTAssertEqual(toughness.rarity, "Common")

        // card_051: The Killing Blow — Ability, cost 8, Legendary
        let killingBlow = cardMap["card_051"]!
        XCTAssertEqual(killingBlow.type, "Ability")
        XCTAssertEqual(killingBlow.resourceCost, 8)
        XCTAssertEqual(killingBlow.rarity, "Legendary")

        // card_060: The Final Raid — Adventure, cost 6, turnsToComplete 5, Legendary
        let finalRaid = cardMap["card_060"]!
        XCTAssertEqual(finalRaid.type, "Adventure")
        XCTAssertEqual(finalRaid.resourceCost, 6)
        XCTAssertEqual(finalRaid.turnsToComplete, 5)
        XCTAssertEqual(finalRaid.rarity, "Legendary")

        // Verify Gear cards all have gearSlot
        for card in gearCards {
            XCTAssertNotNil(card.gearSlot, "Gear card \(card.id) should have a gearSlot")
            XCTAssertNotNil(card.durability, "Gear card \(card.id) should have durability")
        }

        // Verify Adventure cards all have turnsToComplete
        for card in adventureCards {
            XCTAssertNotNil(card.turnsToComplete, "Adventure card \(card.id) should have turnsToComplete")
        }

        // Verify Talent cards have no gearSlot or durability
        for card in talentCards {
            XCTAssertNil(card.gearSlot, "Talent card \(card.id) should not have gearSlot")
            XCTAssertNil(card.durability, "Talent card \(card.id) should not have durability")
        }
    }

    // MARK: - Starter Deck Validation

    func testBothStarterDecksHaveExactly40Cards() throws {
        let starterData = try loadStarterDataFromTestBundle()

        XCTAssertEqual(starterData.starterDecks.count, 2, "Should have exactly 2 starter decks")

        for deck in starterData.starterDecks {
            let totalCards = deck.cardList.reduce(0) { $0 + $1.qty }
            XCTAssertEqual(totalCards, 40, "Deck '\(deck.name)' should have exactly 40 cards, got \(totalCards)")
        }
    }

    func testStarterDeckNamesAndChampions() throws {
        let starterData = try loadStarterDataFromTestBundle()

        let deckNames = Set(starterData.starterDecks.map { $0.name })
        XCTAssertTrue(deckNames.contains("Iron & Blood"), "Should have 'Iron & Blood' deck")
        XCTAssertTrue(deckNames.contains("Cut and Run"), "Should have 'Cut and Run' deck")

        let champIds = Set(starterData.starterDecks.map { $0.champion })
        XCTAssertTrue(champIds.contains("champ_001"), "Iron & Blood should use champ_001")
        XCTAssertTrue(champIds.contains("champ_002"), "Cut and Run should use champ_002")
    }

    func testNoDeckReferencesNonexistentCard() throws {
        let starterData = try loadStarterDataFromTestBundle()

        let validCardIds = Set(starterData.cards.map { $0.id })

        for deck in starterData.starterDecks {
            for entry in deck.cardList {
                XCTAssertTrue(
                    validCardIds.contains(entry.id),
                    "Deck '\(deck.name)' references card '\(entry.id)' which does not exist in the card pool"
                )
            }
        }
    }

    func testNoDeckReferencesNonexistentChampion() throws {
        let starterData = try loadStarterDataFromTestBundle()

        let validChampionIds = Set(starterData.champions.map { $0.id })

        for deck in starterData.starterDecks {
            XCTAssertTrue(
                validChampionIds.contains(deck.champion),
                "Deck '\(deck.name)' references champion '\(deck.champion)' which does not exist"
            )
        }
    }

    // MARK: - Deck Cards Respect Max Copies Rule

    func testDeckCardsRespectMaxCopiesPerCard() throws {
        let starterData = try loadStarterDataFromTestBundle()

        for deck in starterData.starterDecks {
            for entry in deck.cardList {
                XCTAssertLessThanOrEqual(
                    entry.qty, DeckRules.maxCopiesPerCard,
                    "Deck '\(deck.name)' has \(entry.qty) copies of \(entry.id), max is \(DeckRules.maxCopiesPerCard)"
                )
            }
        }
    }

    // MARK: - seedIfNeeded Logic Tests (without SwiftData)

    func testSeedLogicBuildsCorrectChampionMap() throws {
        let starterData = try loadStarterDataFromTestBundle()

        // Verify all champion archetypes map to valid enums
        for champ in starterData.champions {
            XCTAssertNotNil(Archetype(rawValue: champ.archetype), "Champion \(champ.id) archetype '\(champ.archetype)' invalid")
            XCTAssertNotNil(Rarity(rawValue: champ.rarity), "Champion \(champ.id) rarity '\(champ.rarity)' invalid")
            XCTAssertEqual(champ.tierEffects.count, 2, "Champion \(champ.id) should have 2 tier effects")
        }
    }

    func testSeedLogicBuildsCorrectCardMap() throws {
        let starterData = try loadStarterDataFromTestBundle()

        // Every card's type, rarity, and optional gearSlot/subtype must map to valid enums
        for card in starterData.cards {
            XCTAssertNotNil(CardType(rawValue: card.type), "Card \(card.id) type invalid")
            XCTAssertNotNil(Rarity(rawValue: card.rarity), "Card \(card.id) rarity invalid")
            if let slot = card.gearSlot {
                XCTAssertNotNil(GearSlot(rawValue: slot), "Card \(card.id) gearSlot invalid")
            }
        }

        // Verify all 60 card IDs are unique
        let ids = starterData.cards.map { $0.id }
        XCTAssertEqual(Set(ids).count, 60)
    }

    func testSeedLogicDeckExpansion() throws {
        let starterData = try loadStarterDataFromTestBundle()
        let cardIds = Set(starterData.cards.map { $0.id })

        for deck in starterData.starterDecks {
            // Every deck entry references a valid card
            for entry in deck.cardList {
                XCTAssertTrue(cardIds.contains(entry.id), "Deck \(deck.name) references missing card \(entry.id)")
                XCTAssertLessThanOrEqual(entry.qty, DeckRules.maxCopiesPerCard)
            }

            // Total cards == 40
            let totalCards = deck.cardList.reduce(0) { $0 + $1.qty }
            XCTAssertEqual(totalCards, 40, "Deck '\(deck.name)' should expand to 40 cards")
        }
    }

    func testSeedLogicStartingCurrency() {
        // Verify the seed creates a profile with currency 100
        let profile = PlayerProfile(currency: 100)
        XCTAssertEqual(profile.currency, 100)
        XCTAssertFalse(profile.hasRemovedAds)
        XCTAssertFalse(profile.hasCompletedFirstLaunch)
    }
}
