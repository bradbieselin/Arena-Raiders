import XCTest
@testable import ArenaRaiders

final class GameSessionStateTests: XCTestCase {

    // MARK: - Helpers

    private func makeChampion(hp: Int = 30) -> Champion {
        Champion(
            stringId: "champ_test",
            name: "Test Champion",
            archetype: .warrior,
            hp: hp,
            avoidance: 12,
            mitigation: 3,
            innatePassive: InnatePassive(name: "Test Passive", description: "desc"),
            tierEffects: [
                TierEffect(tier: 1, name: "T1", description: "d1"),
                TierEffect(tier: 2, name: "T2", description: "d2"),
            ]
        )
    }

    private func makeCardRef(
        stringId: String = "card_test",
        cardType: CardType = .gear,
        gearSlot: GearSlot? = .weapon,
        durability: Int? = 3
    ) -> CardReference {
        CardReference(card: Card(
            stringId: stringId,
            name: "Test Card",
            cardType: cardType,
            gearSlot: gearSlot,
            resourceCost: 2,
            durability: durability,
            effectDescription: "effect",
            rarity: .common
        ))
    }

    // MARK: - Static Constants

    func testSessionConstants() {
        XCTAssertEqual(GameSession.maxChests, 3)
        XCTAssertEqual(GameSession.startingResources, 3)
        XCTAssertEqual(GameSession.defaultHandSize, 5)
    }

    // MARK: - Computed Properties

    func testChestsRemaining() {
        let session = GameSession()
        XCTAssertEqual(session.chestsRemaining, 3)

        session.chestCount = 1
        XCTAssertEqual(session.chestsRemaining, 2)

        session.chestCount = 3
        XCTAssertEqual(session.chestsRemaining, 0)
    }

    func testIsGameOver() {
        let session = GameSession(champion: makeChampion(hp: 10))
        XCTAssertFalse(session.isGameOver)

        session.playerHP = 0
        XCTAssertTrue(session.isGameOver)

        session.playerHP = 10
        session.endedAt = Date()
        XCTAssertTrue(session.isGameOver)
    }

    func testEffectiveHandSize() {
        let session = GameSession()
        XCTAssertEqual(session.effectiveHandSize, 5)

        session.handSizeBonus = 2
        XCTAssertEqual(session.effectiveHandSize, 7)
    }

    // MARK: - End Turn Integration

    func testEndTurnIncrementsTurnAndResetsResources() {
        let engine = GameEngine()
        let champion = makeChampion()
        let session = GameSession(champion: champion)
        session.playerResources = 5

        engine.endTurn(session: &session)

        XCTAssertEqual(session.currentTurn, 2)
        // Resources reset to 0 then gets startingResources (3)
        XCTAssertEqual(session.playerResources, GameSession.startingResources)
    }

    func testEndTurnProcessesStatusEffects() {
        let engine = GameEngine()
        let session = GameSession(champion: makeChampion(hp: 30))
        session.playerStatusEffects = [
            StatusEffect(type: .poison, turnsRemaining: 2, damagePerTurn: 3)
        ]

        engine.endTurn(session: &session)

        XCTAssertEqual(session.playerHP, 27, "Should take 3 poison damage")
        XCTAssertEqual(session.playerStatusEffects.count, 1)
        XCTAssertEqual(session.playerStatusEffects.first?.turnsRemaining, 1)
    }

    func testEndTurnExpiresStatusEffects() {
        let engine = GameEngine()
        let session = GameSession(champion: makeChampion(hp: 30))
        session.playerStatusEffects = [
            StatusEffect(type: .bleed, turnsRemaining: 1, damagePerTurn: 2)
        ]

        engine.endTurn(session: &session)

        XCTAssertEqual(session.playerHP, 28)
        XCTAssertTrue(session.playerStatusEffects.isEmpty, "Expired effect should be removed")
    }

    // MARK: - Adventure Ticking

    func testTickAdventuresDecrementsAndCompletes() {
        let engine = GameEngine()
        let session = GameSession(champion: makeChampion())
        let adventureCard = makeCardRef(
            stringId: "card_057", // Field Medicine
            cardType: .adventure,
            gearSlot: nil,
            durability: nil
        )
        // Manually set turnsToComplete on the card reference
        var adventure = ActiveAdventure(card: adventureCard)
        adventure.turnsRemaining = 1
        session.activeAdventures = [adventure]
        session.playerHP = 20
        session.playerMaxHP = 30

        engine.tickAdventures(session: &session)

        XCTAssertTrue(session.activeAdventures.isEmpty, "Completed adventure should be removed")
        XCTAssertEqual(session.playerHP, 30, "Field Medicine heals 10 HP")
    }

    func testTickAdventuresLootRunGivesResourcePerTurn() {
        let engine = GameEngine()
        let session = GameSession(champion: makeChampion())
        let lootCard = makeCardRef(
            stringId: "card_053", // Loot Run
            cardType: .adventure,
            gearSlot: nil,
            durability: nil
        )
        var adventure = ActiveAdventure(card: lootCard)
        adventure.turnsRemaining = 2
        session.activeAdventures = [adventure]
        session.playerResources = 0

        engine.tickAdventures(session: &session)

        XCTAssertEqual(session.playerResources, 1, "Loot Run gives +1 resource per turn")
        XCTAssertEqual(session.activeAdventures.count, 1, "Should not be complete yet")
        XCTAssertEqual(session.activeAdventures.first?.turnsRemaining, 1)
    }

    // MARK: - Goldweave Mitts Carry-Over

    func testGoldweaveMittsCarryOver() {
        let engine = GameEngine()
        let session = GameSession(champion: makeChampion())
        session.playerResources = 5

        let mitts = makeCardRef(stringId: "card_017", gearSlot: .hands)
        session.activeGear.equipRef(mitts, in: .hands)

        engine.endTurn(session: &session)

        // Carries over min(3, 5) = 3, then passive income from mitts (+3), then startingResources (+3) = 9
        let mittsPassiveIncome = 3 // card_017 = handsResource3CarryOver → resourcePerTurn = 3
        XCTAssertEqual(session.playerResources, 3 + mittsPassiveIncome + GameSession.startingResources)
        XCTAssertTrue(session.goldweaveMittsUsed, "Should mark carry-over as used")
    }

    func testGoldweaveMittsOnlyUsedOnce() {
        let engine = GameEngine()
        let session = GameSession(champion: makeChampion())

        let mitts = makeCardRef(stringId: "card_017", gearSlot: .hands)
        session.activeGear.equipRef(mitts, in: .hands)

        // First turn: carry over
        session.playerResources = 5
        engine.endTurn(session: &session)
        XCTAssertTrue(session.goldweaveMittsUsed)

        // Second turn: no carry over (already used)
        session.playerResources = 5
        engine.endTurn(session: &session)
        // Resources should reset to 0 + passive income (3 from mitts) + startingResources (3)
        XCTAssertEqual(session.playerResources, 3 + GameSession.startingResources)
    }

    // MARK: - Crown of Clarity Extra Draw

    func testCrownOfClarityDrawsExtraCard() {
        let engine = GameEngine()
        let session = GameSession(champion: makeChampion())
        session.playerDeck = (0..<10).map { i in
            makeCardRef(stringId: "d\(i)", cardType: .talent, gearSlot: nil, durability: nil)
        }
        session.playerHand = []

        let crown = makeCardRef(stringId: "card_008", gearSlot: .head)
        session.activeGear.equipRef(crown, in: .head)

        engine.endTurn(session: &session)

        // Normal draw (1) + Crown bonus draw (1) = 2
        XCTAssertEqual(session.playerHand.count, 2)
        XCTAssertEqual(session.playerDeck.count, 8)
    }

    // MARK: - Setup Game

    func testSetupGameDrawsOpeningHandAndSetsChest() {
        let engine = GameEngine()
        let session = GameSession(champion: makeChampion())
        session.playerDeck = (0..<40).map { i in
            makeCardRef(stringId: "c\(i)", cardType: .talent, gearSlot: nil, durability: nil)
        }

        engine.setupGame(session: &session)

        XCTAssertEqual(session.playerHand.count, 5)
        XCTAssertEqual(session.playerDeck.count, 35)
        XCTAssertEqual(session.currentChestIntegrity, 20)
        XCTAssertEqual(session.currentChestTier, 1)
    }

    // MARK: - Advance Chest

    func testAdvanceChestProgressesTiers() {
        let engine = GameEngine()
        let session = GameSession(champion: makeChampion())
        session.chestCount = 0

        engine.advanceChest(session: &session)
        XCTAssertEqual(session.chestCount, 1)
        XCTAssertEqual(session.currentChestTier, 2)
        XCTAssertEqual(session.currentChestIntegrity, 35)

        engine.advanceChest(session: &session)
        XCTAssertEqual(session.chestCount, 2)
        XCTAssertEqual(session.currentChestTier, 3)
        XCTAssertEqual(session.currentChestIntegrity, 50)
    }

    func testAdvanceChestToArenaPhase() {
        let engine = GameEngine()
        let session = GameSession(champion: makeChampion())
        session.chestCount = 2

        engine.advanceChest(session: &session)
        XCTAssertEqual(session.chestCount, 3)
        XCTAssertEqual(session.phase, .arena)
    }

    // MARK: - Play Card Effects

    func testPlayBandageHeals4HP() {
        let engine = GameEngine()
        let session = GameSession(champion: makeChampion(hp: 30))
        session.playerHP = 20
        session.playerResources = 10

        let bandage = CardReference(card: Card(
            stringId: "card_036",
            name: "Bandage",
            cardType: .ability,
            resourceCost: 2,
            effectDescription: "Heal 4 HP"
        ))
        session.playerHand = [bandage]

        engine.playCard(card: bandage, session: &session)

        XCTAssertEqual(session.playerHP, 24)
        XCTAssertTrue(session.playerHand.isEmpty)
        XCTAssertEqual(session.playerDiscard.count, 1)
    }

    func testPlayBattleCryGivesResourcesAndDraws() {
        let engine = GameEngine()
        let session = GameSession(champion: makeChampion())
        session.playerResources = 10
        session.playerDeck = [
            makeCardRef(stringId: "d1", cardType: .talent, gearSlot: nil, durability: nil)
        ]
        session.playerHand = []

        let battleCry = CardReference(card: Card(
            stringId: "card_044",
            name: "Battle Cry",
            cardType: .ability,
            resourceCost: 3,
            effectDescription: "+3 Resources, draw 1"
        ))
        session.playerHand = [battleCry]

        engine.playCard(card: battleCry, session: &session)

        // 10 - 3 (cost) + 3 (effect) = 10
        XCTAssertEqual(session.playerResources, 10)
        // Drew 1 card
        XCTAssertEqual(session.playerHand.count, 1)
        XCTAssertEqual(session.playerHand.first?.stringId, "d1")
    }

    func testPlayTalentToughnessIncreaseMaxHP() {
        let engine = GameEngine()
        let session = GameSession(champion: makeChampion(hp: 30))
        session.playerResources = 10

        let toughness = CardReference(card: Card(
            stringId: "card_022",
            name: "Toughness",
            cardType: .talent,
            resourceCost: 2,
            effectDescription: "+3 Max HP"
        ))
        session.playerHand = [toughness]

        engine.playCard(card: toughness, session: &session)

        XCTAssertEqual(session.playerMaxHP, 33)
        XCTAssertEqual(session.playerHP, 33)
        XCTAssertEqual(session.activeTalents.count, 1)
    }

    func testPlayTalentQuickHandsIncreasesHandSize() {
        let engine = GameEngine()
        let session = GameSession(champion: makeChampion())
        session.playerResources = 10

        let quickHands = CardReference(card: Card(
            stringId: "card_023",
            name: "Quick Hands",
            cardType: .talent,
            resourceCost: 1,
            effectDescription: "+1 hand size"
        ))
        session.playerHand = [quickHands]

        engine.playCard(card: quickHands, session: &session)

        XCTAssertEqual(session.handSizeBonus, 1)
        XCTAssertEqual(session.effectiveHandSize, 6)
    }
}
