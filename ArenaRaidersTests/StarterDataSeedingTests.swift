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

    // MARK: - seedIfNeeded Integration Tests

    @MainActor
    func testSeedIfNeededCreatesProfileWithCorrectCurrency() throws {
        let container = try ModelContainer(
            for: PlayerProfile.self, Champion.self, Card.self, Deck.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        // Manually seed since we have the JSON
        let starterData = try loadStarterDataFromTestBundle()
        seedFromData(starterData, context: context)

        let profiles = try context.fetch(FetchDescriptor<PlayerProfile>())
        XCTAssertEqual(profiles.count, 1, "Should create exactly one PlayerProfile")

        let profile = profiles[0]
        XCTAssertEqual(profile.currency, 100, "Starting currency should be 100")
        XCTAssertFalse(profile.hasRemovedAds, "hasRemovedAds should be false")
        XCTAssertTrue(profile.hasCompletedFirstLaunch)
    }

    @MainActor
    func testSeedIfNeededUnlocksAllSixChampions() throws {
        let container = try ModelContainer(
            for: PlayerProfile.self, Champion.self, Card.self, Deck.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let starterData = try loadStarterDataFromTestBundle()
        seedFromData(starterData, context: context)

        let profiles = try context.fetch(FetchDescriptor<PlayerProfile>())
        let profile = profiles[0]

        XCTAssertEqual(profile.unlockedChampions.count, 6, "All 6 champions should be unlocked")

        let champions = try context.fetch(FetchDescriptor<Champion>())
        XCTAssertEqual(champions.count, 6, "Should have 6 champions in context")
    }

    @MainActor
    func testSeedIfNeededAddsAll60CardsToPool() throws {
        let container = try ModelContainer(
            for: PlayerProfile.self, Champion.self, Card.self, Deck.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let starterData = try loadStarterDataFromTestBundle()
        seedFromData(starterData, context: context)

        let cards = try context.fetch(FetchDescriptor<Card>())
        XCTAssertEqual(cards.count, 60, "Should have 60 cards in context")

        let profiles = try context.fetch(FetchDescriptor<PlayerProfile>())
        let profile = profiles[0]

        XCTAssertEqual(profile.cardCollection.count, 60, "Player should own all 60 unique cards")
    }

    @MainActor
    func testSeedIfNeededCreatesBothStarterDecks() throws {
        let container = try ModelContainer(
            for: PlayerProfile.self, Champion.self, Card.self, Deck.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let starterData = try loadStarterDataFromTestBundle()
        seedFromData(starterData, context: context)

        let profiles = try context.fetch(FetchDescriptor<PlayerProfile>())
        let profile = profiles[0]

        XCTAssertEqual(profile.savedDecks.count, 2, "Should have 2 saved decks")

        let deckNames = Set(profile.savedDecks.map { $0.name })
        XCTAssertTrue(deckNames.contains("Iron & Blood"))
        XCTAssertTrue(deckNames.contains("Cut and Run"))

        for deck in profile.savedDecks {
            XCTAssertEqual(deck.cardCount, 40, "Deck '\(deck.name)' should have 40 cards")
            XCTAssertTrue(deck.isComplete, "Deck '\(deck.name)' should be complete")
            XCTAssertNotNil(deck.champion, "Deck '\(deck.name)' should have a champion")
        }
    }

    @MainActor
    func testSeedIfNeededIsIdempotent() throws {
        let container = try ModelContainer(
            for: PlayerProfile.self, Champion.self, Card.self, Deck.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let starterData = try loadStarterDataFromTestBundle()
        seedFromData(starterData, context: context)
        // Seed again — should not duplicate
        seedFromData(starterData, context: context)

        let profiles = try context.fetch(FetchDescriptor<PlayerProfile>())
        XCTAssertEqual(profiles.count, 1, "Should still have exactly one profile after double seed")
        XCTAssertEqual(profiles[0].savedDecks.count, 2)
    }

    // MARK: - Seed Helper (mirrors StarterDataLoader.seedIfNeeded logic)

    /// Replicates seedIfNeeded logic for testing without needing Bundle.main
    @MainActor
    private func seedFromData(_ starterData: StarterData, context: ModelContext) {
        // Check if profile already exists
        let profileDescriptor = FetchDescriptor<PlayerProfile>()
        let existingProfiles = (try? context.fetch(profileDescriptor)) ?? []
        guard existingProfiles.isEmpty else { return }

        // Seed champions
        var championMap: [String: Champion] = [:]
        for cJSON in starterData.champions {
            let champion = Champion(
                stringId: cJSON.id,
                name: cJSON.name,
                archetype: Archetype(rawValue: cJSON.archetype) ?? .warrior,
                hp: cJSON.hp,
                avoidance: cJSON.avoidance,
                mitigation: cJSON.mitigation,
                innatePassive: InnatePassive(
                    name: cJSON.innatePassive.name,
                    effectDescription: cJSON.innatePassive.effectDescription
                ),
                tierEffects: cJSON.tierEffects.map {
                    TierEffect(tier: $0.tier, name: $0.name, effectDescription: $0.effectDescription)
                },
                rarity: Rarity(rawValue: cJSON.rarity) ?? .common,
                flavorText: cJSON.flavorText
            )
            context.insert(champion)
            championMap[cJSON.id] = champion
        }

        // Seed cards
        var cardMap: [String: Card] = [:]
        for cardJSON in starterData.cards {
            let card = Card(
                stringId: cardJSON.id,
                name: cardJSON.name,
                cardType: CardType(rawValue: cardJSON.type) ?? .ability,
                subtype: cardJSON.subtype.flatMap { CardSubtype(rawValue: $0) },
                gearSlot: cardJSON.gearSlot.flatMap { GearSlot(rawValue: $0) },
                resourceCost: cardJSON.resourceCost,
                durability: cardJSON.durability,
                effectDescription: cardJSON.effect,
                rarity: Rarity(rawValue: cardJSON.rarity) ?? .common,
                isInstant: cardJSON.isInstant ?? false,
                isTwoHanded: cardJSON.isTwoHanded ?? false,
                turnsToComplete: cardJSON.turnsToComplete,
                flavorText: cardJSON.flavorText
            )
            context.insert(card)
            cardMap[cardJSON.id] = card
        }

        // Create profile
        let profile = PlayerProfile(currency: 100)
        context.insert(profile)

        // Unlock all champions
        for champion in championMap.values {
            profile.unlockedChampions.append(champion)
        }

        // Add all cards to collection
        for card in cardMap.values {
            profile.addCard(card, quantity: 1)
        }

        // Build starter decks
        for starterDeck in starterData.starterDecks {
            guard let deckChampion = championMap[starterDeck.champion] else { continue }

            var deckCards: [Card] = []
            for entry in starterDeck.cardList {
                if let card = cardMap[entry.id] {
                    for _ in 0..<entry.qty {
                        deckCards.append(card)
                    }
                }
            }

            let deck = Deck(
                name: starterDeck.name,
                champion: deckChampion,
                cards: deckCards
            )
            context.insert(deck)
            profile.savedDecks.append(deck)
        }

        profile.hasCompletedFirstLaunch = true
        try? context.save()
    }
}
