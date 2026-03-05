import XCTest
import SwiftData
@testable import ArenaRaiders

final class ModelValidationTests: XCTestCase {

    // MARK: - Helper

    private func makeChampion(
        stringId: String = "test_champion",
        name: String = "Test Champion",
        archetype: Archetype = .warrior,
        hp: Int = 30,
        avoidance: Int = 12,
        mitigation: Int = 2,
        innatePassive: InnatePassive = InnatePassive(name: "Test Passive", effectDescription: "A test passive"),
        tierEffects: [TierEffect] = [
            TierEffect(tier: 1, name: "Tier1", effectDescription: "First tier"),
            TierEffect(tier: 2, name: "Tier2", effectDescription: "Second tier")
        ],
        rarity: Rarity = .rare,
        flavorText: String = "A mighty warrior."
    ) -> Champion {
        Champion(
            stringId: stringId,
            name: name,
            archetype: archetype,
            hp: hp,
            avoidance: avoidance,
            mitigation: mitigation,
            innatePassive: innatePassive,
            tierEffects: tierEffects,
            rarity: rarity,
            flavorText: flavorText
        )
    }

    private func makeCard(
        stringId: String = "test_card",
        name: String = "Test Card",
        cardType: CardType = .gear,
        subtype: CardSubtype? = nil,
        gearSlot: GearSlot? = .weapon,
        resourceCost: Int = 2,
        durability: Int? = 3,
        effectDescription: String = "+1 Attack",
        rarity: Rarity = .common,
        isInstant: Bool = false,
        isTwoHanded: Bool = false,
        turnsToComplete: Int? = nil,
        flavorText: String = "A sharp blade."
    ) -> Card {
        Card(
            stringId: stringId,
            name: name,
            cardType: cardType,
            subtype: subtype,
            gearSlot: gearSlot,
            resourceCost: resourceCost,
            durability: durability,
            effectDescription: effectDescription,
            rarity: rarity,
            isInstant: isInstant,
            isTwoHanded: isTwoHanded,
            turnsToComplete: turnsToComplete,
            flavorText: flavorText
        )
    }

    private func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([
            PlayerProfile.self,
            Champion.self,
            Card.self,
            Deck.self,
            TreasureChest.self,
            GameSession.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    // MARK: - Champion Tests

    func testChampionCreatedWithAllRequiredFields() {
        let innate = InnatePassive(name: "Iron Will", effectDescription: "Reduces damage by 1")
        let tiers = [
            TierEffect(tier: 1, name: "Shield Bash", effectDescription: "+2 mitigation"),
            TierEffect(tier: 2, name: "Fortify", effectDescription: "+4 mitigation")
        ]
        let champion = Champion(
            stringId: "vex_ironclad",
            name: "Vex the Ironclad",
            archetype: .warrior,
            hp: 35,
            avoidance: 10,
            mitigation: 3,
            innatePassive: innate,
            tierEffects: tiers,
            rarity: .epic,
            flavorText: "Unyielding defender."
        )

        XCTAssertEqual(champion.stringId, "vex_ironclad")
        XCTAssertEqual(champion.name, "Vex the Ironclad")
        XCTAssertEqual(champion.archetype, .warrior)
        XCTAssertEqual(champion.hp, 35)
        XCTAssertEqual(champion.avoidance, 10)
        XCTAssertEqual(champion.mitigation, 3)
        XCTAssertEqual(champion.innatePassive.name, "Iron Will")
        XCTAssertEqual(champion.innatePassive.effectDescription, "Reduces damage by 1")
        XCTAssertEqual(champion.tierEffects.count, 2)
        XCTAssertEqual(champion.tierEffect(for: 1)?.name, "Shield Bash")
        XCTAssertEqual(champion.tierEffect(for: 2)?.name, "Fortify")
        XCTAssertNil(champion.tierEffect(for: 3))
        XCTAssertEqual(champion.rarity, .epic)
        XCTAssertEqual(champion.flavorText, "Unyielding defender.")
        XCTAssertNotNil(champion.id)
    }

    // MARK: - Card Type Tests

    func testGearCardCreation() {
        let card = makeCard(
            stringId: "iron_sword",
            name: "Iron Sword",
            cardType: .gear,
            gearSlot: .weapon,
            durability: 4,
            effectDescription: "+2 Attack"
        )
        XCTAssertTrue(card.isGear)
        XCTAssertFalse(card.isTalent)
        XCTAssertFalse(card.isAbility)
        XCTAssertFalse(card.isAdventure)
        XCTAssertEqual(card.gearSlot, .weapon)
        XCTAssertEqual(card.durability, 4)
        XCTAssertEqual(card.cardType, .gear)
    }

    func testTalentCardCreation() {
        let card = makeCard(
            stringId: "quick_reflexes",
            name: "Quick Reflexes",
            cardType: .talent,
            gearSlot: nil,
            durability: nil,
            effectDescription: "+1 Avoidance"
        )
        XCTAssertTrue(card.isTalent)
        XCTAssertFalse(card.isGear)
        XCTAssertNil(card.gearSlot)
        XCTAssertNil(card.durability)
        XCTAssertEqual(card.cardType, .talent)
    }

    func testAbilityCardCreation() {
        let card = makeCard(
            stringId: "fireball",
            name: "Fireball",
            cardType: .ability,
            gearSlot: nil,
            durability: nil,
            effectDescription: "Deal 5 damage",
            isInstant: true
        )
        XCTAssertTrue(card.isAbility)
        XCTAssertFalse(card.isGear)
        XCTAssertTrue(card.isInstant)
        XCTAssertEqual(card.cardType, .ability)
    }

    func testAdventureCardCreation() {
        let card = makeCard(
            stringId: "dungeon_crawl",
            name: "Dungeon Crawl",
            cardType: .adventure,
            gearSlot: nil,
            durability: nil,
            effectDescription: "Gain 3 resources after 2 turns",
            turnsToComplete: 2
        )
        XCTAssertTrue(card.isAdventure)
        XCTAssertFalse(card.isGear)
        XCTAssertEqual(card.turnsToComplete, 2)
        XCTAssertEqual(card.cardType, .adventure)
    }

    // MARK: - Gear Slot Save/Load

    func testGearCardWithSlotSavesAndLoadsCorrectly() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)

        let card = Card(
            stringId: "helm_of_valor",
            name: "Helm of Valor",
            cardType: .gear,
            gearSlot: .head,
            resourceCost: 3,
            durability: 5,
            effectDescription: "+1 Mitigation",
            rarity: .rare,
            flavorText: "Protects the mind."
        )

        context.insert(card)
        try context.save()

        let descriptor = FetchDescriptor<Card>(
            predicate: #Predicate { $0.stringId == "helm_of_valor" }
        )
        let loaded = try context.fetch(descriptor)

        XCTAssertEqual(loaded.count, 1)
        let loadedCard = try XCTUnwrap(loaded.first)
        XCTAssertEqual(loadedCard.name, "Helm of Valor")
        XCTAssertEqual(loadedCard.cardType, .gear)
        XCTAssertEqual(loadedCard.gearSlot, .head)
        XCTAssertEqual(loadedCard.durability, 5)
        XCTAssertEqual(loadedCard.resourceCost, 3)
        XCTAssertEqual(loadedCard.rarity, .rare)
        XCTAssertEqual(loadedCard.flavorText, "Protects the mind.")
    }

    // MARK: - Talent with nil durability

    func testTalentCardWithNilDurabilityDoesNotCrash() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)

        let talent = Card(
            stringId: "stealth_mastery",
            name: "Stealth Mastery",
            cardType: .talent,
            gearSlot: nil,
            resourceCost: 1,
            durability: nil,
            effectDescription: "+2 Avoidance",
            rarity: .common
        )

        XCTAssertNil(talent.durability)
        XCTAssertNil(talent.gearSlot)

        context.insert(talent)
        try context.save()

        let descriptor = FetchDescriptor<Card>(
            predicate: #Predicate { $0.stringId == "stealth_mastery" }
        )
        let loaded = try context.fetch(descriptor)
        XCTAssertEqual(loaded.count, 1)
        XCTAssertNil(loaded.first?.durability)
    }

    // MARK: - Deck Validation

    func testDeckRequiresExactly40Cards() {
        let cards39 = (0..<39).map { i in
            makeCard(stringId: "card_\(i)", name: "Card \(i)")
        }
        let deck39 = Deck(name: "Incomplete", champion: makeChampion(), cards: cards39)
        XCTAssertFalse(deck39.isComplete)
        XCTAssertEqual(deck39.cardCount, 39)
        XCTAssertEqual(deck39.cardsNeeded, 1)

        let cards40 = (0..<40).map { i in
            makeCard(stringId: "card_\(i)", name: "Card \(i)")
        }
        let deck40 = Deck(name: "Complete", champion: makeChampion(), cards: cards40)
        XCTAssertTrue(deck40.isComplete)
        XCTAssertEqual(deck40.cardCount, 40)
        XCTAssertEqual(deck40.cardsNeeded, 0)

        let cards41 = (0..<41).map { i in
            makeCard(stringId: "card_\(i)", name: "Card \(i)")
        }
        let deck41 = Deck(name: "Overfull", champion: makeChampion(), cards: cards41)
        XCTAssertFalse(deck41.isComplete, "A deck with 41 cards should not be marked complete")
        XCTAssertEqual(deck41.cardCount, 41)
        XCTAssertEqual(deck41.cardsNeeded, 0) // max(0, 40 - 41) = 0
    }

    func testDeckWithoutChampionIsNotComplete() {
        let cards40 = (0..<40).map { i in
            makeCard(stringId: "card_\(i)", name: "Card \(i)")
        }
        let deck = Deck(name: "No Champion", champion: nil, cards: cards40)
        XCTAssertFalse(deck.isComplete, "A deck without a champion should not be complete")
    }

    // MARK: - PlayerProfile SwiftData Persistence

    @MainActor
    func testPlayerProfileSavesAndLoadsWithIdenticalValues() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext

        let profile = PlayerProfile(displayName: "TestRaider", currency: 1000)
        profile.totalWins = 7
        profile.totalLosses = 3
        profile.hasRemovedAds = true
        profile.hasCompletedFirstLaunch = true

        // Add a card to collection
        let card = Card(
            stringId: "test_sword",
            name: "Test Sword",
            cardType: .gear,
            gearSlot: .weapon,
            resourceCost: 2,
            durability: 3,
            effectDescription: "+1 Attack"
        )
        context.insert(card)
        profile.addCard(card, quantity: 3)

        // Add a champion
        let champion = makeChampion()
        context.insert(champion)
        profile.unlockedChampions.append(champion)

        context.insert(profile)
        try context.save()

        let descriptor = FetchDescriptor<PlayerProfile>()
        let loaded = try context.fetch(descriptor)

        XCTAssertEqual(loaded.count, 1)
        let p = try XCTUnwrap(loaded.first)
        XCTAssertEqual(p.displayName, "TestRaider")
        XCTAssertEqual(p.currency, 1000)
        XCTAssertEqual(p.totalWins, 7)
        XCTAssertEqual(p.totalLosses, 3)
        XCTAssertEqual(p.totalGames, 10)
        XCTAssertTrue(p.hasRemovedAds)
        XCTAssertTrue(p.hasCompletedFirstLaunch)
        XCTAssertEqual(p.uniqueCardsOwned, 1)
        XCTAssertEqual(p.totalCardsOwned, 3)
        XCTAssertEqual(p.quantityOwned(of: card), 3)
        XCTAssertEqual(p.unlockedChampions.count, 1)
        XCTAssertEqual(p.unlockedChampions.first?.stringId, "test_champion")
    }

    // MARK: - GameSession Default Initialization

    func testGameSessionDefaultInitialization() {
        let champion = makeChampion(hp: 35)
        let cards = (0..<5).map { i in
            makeCard(stringId: "deck_card_\(i)", name: "Deck Card \(i)")
        }
        let deck = Deck(name: "Test Deck", champion: champion, cards: cards)
        let session = GameSession(champion: champion, deck: deck)

        // Phase defaults to raid
        XCTAssertEqual(session.phase, .raid)

        // Champion reference
        XCTAssertNotNil(session.playerChampion)
        XCTAssertEqual(session.playerChampion?.name, champion.name)
        XCTAssertEqual(session.playerChampion?.hp, 35)

        // HP matches champion
        XCTAssertEqual(session.playerHP, 35)
        XCTAssertEqual(session.playerMaxHP, 35)

        // Deck converted to CardReferences
        XCTAssertEqual(session.playerDeck.count, 5)

        // Hand and discard empty
        XCTAssertTrue(session.playerHand.isEmpty)
        XCTAssertTrue(session.playerDiscard.isEmpty)

        // Starting resources
        XCTAssertEqual(session.playerResources, GameSession.startingResources)

        // Chest state
        XCTAssertEqual(session.chestCount, 0)
        XCTAssertEqual(session.currentChestTier, 1)

        // Equipment empty
        XCTAssertTrue(session.activeGear.isEmpty)
        XCTAssertTrue(session.activeTalents.isEmpty)
        XCTAssertTrue(session.activeAdventures.isEmpty)

        // Status effects empty
        XCTAssertTrue(session.playerStatusEffects.isEmpty)
        XCTAssertTrue(session.opponentStatusEffects.isEmpty)

        // Tracking flags all false
        XCTAssertFalse(session.firstBloodUsed)
        XCTAssertFalse(session.perfectDodgeUsed)
        XCTAssertFalse(session.goldweaveMittsUsed)
        XCTAssertFalse(session.ironWillTriggered)

        // Turn tracking
        XCTAssertEqual(session.currentTurn, 1)
        XCTAssertEqual(session.consecutiveHits, 0)
        XCTAssertEqual(session.handSizeBonus, 0)
        XCTAssertEqual(session.effectiveHandSize, GameSession.defaultHandSize)

        // Game not over
        XCTAssertFalse(session.isGameOver)
        XCTAssertNil(session.endedAt)
        XCTAssertNil(session.didPlayerWin)
    }

    func testGameSessionWithNoChampionDefaults() {
        let session = GameSession()

        XCTAssertNil(session.playerChampion)
        XCTAssertEqual(session.playerHP, 30, "Default HP when no champion is 30")
        XCTAssertEqual(session.playerMaxHP, 30)
        XCTAssertTrue(session.playerDeck.isEmpty)
        XCTAssertEqual(session.phase, .raid)
    }
}
