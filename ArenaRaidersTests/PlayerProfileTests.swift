import XCTest
import SwiftData
@testable import ArenaRaiders

final class PlayerProfileTests: XCTestCase {

    // MARK: - Helpers

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

    private func makeCard(stringId: String, name: String = "Card") -> Card {
        Card(
            stringId: stringId,
            name: name,
            cardType: .gear,
            gearSlot: .weapon,
            resourceCost: 2,
            durability: 3,
            effectDescription: "effect"
        )
    }

    // MARK: - Default Values

    func testDefaultProfile() {
        let profile = PlayerProfile()
        XCTAssertEqual(profile.displayName, "Raider")
        XCTAssertEqual(profile.currency, 500)
        XCTAssertEqual(profile.totalWins, 0)
        XCTAssertEqual(profile.totalLosses, 0)
        XCTAssertEqual(profile.totalGames, 0)
        XCTAssertFalse(profile.hasRemovedAds)
        XCTAssertFalse(profile.hasCompletedFirstLaunch)
        XCTAssertTrue(profile.cardCollection.isEmpty)
        XCTAssertTrue(profile.unlockedChampions.isEmpty)
        XCTAssertTrue(profile.savedDecks.isEmpty)
        XCTAssertEqual(profile.uniqueCardsOwned, 0)
        XCTAssertEqual(profile.totalCardsOwned, 0)
    }

    func testCustomProfile() {
        let profile = PlayerProfile(displayName: "TestPlayer", currency: 1000)
        XCTAssertEqual(profile.displayName, "TestPlayer")
        XCTAssertEqual(profile.currency, 1000)
    }

    // MARK: - Win Rate

    func testWinRateZeroGames() {
        let profile = PlayerProfile()
        XCTAssertEqual(profile.winRate, 0)
    }

    func testWinRateCalculation() {
        let profile = PlayerProfile()
        profile.totalWins = 3
        profile.totalLosses = 7
        XCTAssertEqual(profile.winRate, 0.3, accuracy: 0.001)
    }

    // MARK: - Collection Management

    func testAddCardToEmptyCollection() {
        let profile = PlayerProfile()
        let card = makeCard(stringId: "card_001", name: "Sword")

        profile.addCard(card, quantity: 2)

        XCTAssertEqual(profile.uniqueCardsOwned, 1)
        XCTAssertEqual(profile.totalCardsOwned, 2)
        XCTAssertEqual(profile.quantityOwned(of: card), 2)
    }

    func testAddCardStacksQuantity() {
        let profile = PlayerProfile()
        let card = makeCard(stringId: "card_001")

        profile.addCard(card, quantity: 1)
        profile.addCard(card, quantity: 3)

        XCTAssertEqual(profile.uniqueCardsOwned, 1)
        XCTAssertEqual(profile.totalCardsOwned, 4)
        XCTAssertEqual(profile.quantityOwned(of: card), 4)
    }

    func testAddMultipleDifferentCards() {
        let profile = PlayerProfile()
        let card1 = makeCard(stringId: "card_001")
        let card2 = makeCard(stringId: "card_002")

        profile.addCard(card1, quantity: 2)
        profile.addCard(card2, quantity: 3)

        XCTAssertEqual(profile.uniqueCardsOwned, 2)
        XCTAssertEqual(profile.totalCardsOwned, 5)
    }

    func testRemoveCardDecreasesQuantity() {
        let profile = PlayerProfile()
        let card = makeCard(stringId: "card_001")

        profile.addCard(card, quantity: 3)
        profile.removeCard(card, quantity: 1)

        XCTAssertEqual(profile.quantityOwned(of: card), 2)
        XCTAssertEqual(profile.uniqueCardsOwned, 1)
    }

    func testRemoveCardRemovesEntryAtZero() {
        let profile = PlayerProfile()
        let card = makeCard(stringId: "card_001")

        profile.addCard(card, quantity: 2)
        profile.removeCard(card, quantity: 2)

        XCTAssertEqual(profile.quantityOwned(of: card), 0)
        XCTAssertEqual(profile.uniqueCardsOwned, 0)
    }

    func testRemoveCardRemovesEntryBelowZero() {
        let profile = PlayerProfile()
        let card = makeCard(stringId: "card_001")

        profile.addCard(card, quantity: 1)
        profile.removeCard(card, quantity: 5) // more than owned

        XCTAssertEqual(profile.uniqueCardsOwned, 0)
    }

    func testRemoveNonexistentCardIsNoOp() {
        let profile = PlayerProfile()
        let card = makeCard(stringId: "card_999")

        profile.removeCard(card) // should not crash
        XCTAssertEqual(profile.uniqueCardsOwned, 0)
    }

    func testQuantityOwnedForUnownedCard() {
        let profile = PlayerProfile()
        let card = makeCard(stringId: "card_001")
        XCTAssertEqual(profile.quantityOwned(of: card), 0)
    }

    // MARK: - SwiftData Persistence

    @MainActor
    func testProfilePersistsCardCollection() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext

        let profile = PlayerProfile(displayName: "Saver", currency: 999)
        let card = makeCard(stringId: "card_001", name: "Saved Sword")
        context.insert(card)
        profile.addCard(card, quantity: 2)
        context.insert(profile)
        try context.save()

        let loaded = try context.fetch(FetchDescriptor<PlayerProfile>())
        XCTAssertEqual(loaded.count, 1)
        let p = try XCTUnwrap(loaded.first)
        XCTAssertEqual(p.displayName, "Saver")
        XCTAssertEqual(p.currency, 999)
        XCTAssertEqual(p.uniqueCardsOwned, 1)
        XCTAssertEqual(p.totalCardsOwned, 2)
    }

    @MainActor
    func testProfilePersistsRelationships() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext

        let profile = PlayerProfile()
        let champion = Champion(
            stringId: "champ_001",
            name: "Vex",
            archetype: .warrior,
            hp: 35,
            avoidance: 10,
            mitigation: 3,
            innatePassive: InnatePassive(name: "Unyielding", effectDescription: "desc")
        )
        context.insert(champion)
        profile.unlockedChampions.append(champion)

        let deck = Deck(name: "Test Deck", champion: champion, cards: [])
        context.insert(deck)
        profile.savedDecks.append(deck)

        context.insert(profile)
        try context.save()

        let loaded = try context.fetch(FetchDescriptor<PlayerProfile>())
        let p = try XCTUnwrap(loaded.first)
        XCTAssertEqual(p.unlockedChampions.count, 1)
        XCTAssertEqual(p.savedDecks.count, 1)
        XCTAssertEqual(p.savedDecks.first?.name, "Test Deck")
    }
}
