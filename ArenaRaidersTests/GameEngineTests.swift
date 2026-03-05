import XCTest
@testable import ArenaRaiders

final class GameEngineTests: XCTestCase {

    // MARK: - Helpers

    private func makeCard(
        name: String = "Test Card",
        type: CardType = .gear,
        gearSlot: GearSlot? = .weapon,
        cost: Int = 2,
        durability: Int? = 3,
        rarity: Rarity = .common,
        isInstant: Bool = false
    ) -> CardReference {
        CardReference(card: Card(
            name: name,
            cardType: type,
            gearSlot: type == .gear ? gearSlot : nil,
            resourceCost: cost,
            durability: durability,
            effectDescription: "Test effect",
            rarity: rarity,
            isInstant: isInstant
        ))
    }

    private func makeChampionRef() -> ChampionReference {
        ChampionReference(champion: Champion(
            name: "Test Champion",
            hp: 30,
            avoidance: 12,
            mitigation: 3,
            innatePassive: InnatePassive(description: "Test passive", effect: .regeneration),
            tierEffects: [
                TierEffect(tier: 1, description: "Tier 1 bonus", effect: .shield),
                TierEffect(tier: 2, description: "Tier 2 bonus", effect: .damageBoost)
            ]
        ))
    }

    private func makeSession(deckSize: Int = 10) -> GameSession {
        let champion = Champion(
            name: "Test Champion",
            hp: 30,
            avoidance: 12,
            mitigation: 3,
            innatePassive: InnatePassive(description: "Test passive", effect: .regeneration),
            tierEffects: []
        )
        let session = GameSession(phase: .raid, champion: champion)
        // Populate deck with test cards
        var deck: [CardReference] = []
        for i in 0..<deckSize {
            let types: [CardType] = [.gear, .talent, .ability, .adventure]
            let cardType = types[i % types.count]
            let card = Card(
                name: "Card \(i)",
                cardType: cardType,
                gearSlot: cardType == .gear ? .weapon : nil,
                resourceCost: (i % 3) + 1,
                durability: cardType == .talent ? nil : 3,
                effectDescription: "Effect \(i)",
                rarity: .common
            )
            deck.append(CardReference(card: card))
        }
        session.playerDeck = deck
        return session
    }

    // MARK: - D20 Roll Distribution Tests

    func testRollD20ReturnsValuesInRange() {
        let engine = GameEngine()
        for _ in 0..<1000 {
            let roll = engine.rollD20()
            XCTAssertGreaterThanOrEqual(roll, 1)
            XCTAssertLessThanOrEqual(roll, 20)
        }
    }

    func testRollD20Distribution() {
        // Verify all values 1-20 appear at least once in 10000 rolls
        let engine = GameEngine()
        var seen = Set<Int>()
        for _ in 0..<10000 {
            seen.insert(engine.rollD20())
        }
        for value in 1...20 {
            XCTAssertTrue(seen.contains(value), "Value \(value) never rolled in 10000 attempts")
        }
    }

    func testRollD20Fairness() {
        // Chi-squared-style check: each value should appear roughly 5% of the time
        let engine = GameEngine()
        var counts = [Int: Int]()
        let totalRolls = 100_000
        for _ in 0..<totalRolls {
            let roll = engine.rollD20()
            counts[roll, default: 0] += 1
        }
        let expected = Double(totalRolls) / 20.0
        for value in 1...20 {
            let count = Double(counts[value] ?? 0)
            // Allow 20% deviation from expected
            XCTAssertGreaterThan(count, expected * 0.8, "Value \(value) appeared too rarely")
            XCTAssertLessThan(count, expected * 1.2, "Value \(value) appeared too often")
        }
    }

    func testFixedDiceProvider() {
        let dice = FixedDiceProvider(values: [5, 15, 20])
        let engine = GameEngine(dice: dice)
        XCTAssertEqual(engine.rollD20(), 5)
        XCTAssertEqual(engine.rollD20(), 15)
        XCTAssertEqual(engine.rollD20(), 20)
        // Wraps around
        XCTAssertEqual(engine.rollD20(), 5)
    }

    // MARK: - Roll Classification Tests

    func testClassifyRollMiss() {
        let engine = GameEngine()
        for roll in 1...9 {
            let result = engine.classifyRoll(roll)
            XCTAssertTrue(result.isMiss, "Roll \(roll) should be a miss")
        }
    }

    func testClassifyRollHit() {
        let engine = GameEngine()
        for roll in 10...19 {
            let result = engine.classifyRoll(roll)
            XCTAssertTrue(result.isHit, "Roll \(roll) should be a hit")
        }
    }

    func testClassifyRollCrit() {
        let engine = GameEngine()
        let result = engine.classifyRoll(20)
        XCTAssertTrue(result.isCrit)
    }

    // MARK: - Chest Roll Resource Tests

    func testChestRollMissGives1Resource() {
        let engine = GameEngine(dice: FixedDiceProvider(values: [5]))
        let chest = TreasureChest(integrity: 50, tier: 1)
        let outcome = engine.resolveChestRoll(roll: 5, chest: chest)

        XCTAssertEqual(outcome.resources, 1)
        XCTAssertEqual(outcome.damage, 0)
        XCTAssertEqual(chest.integrity, 50) // No damage on miss
    }

    func testChestRollHitGives3Resources() {
        let engine = GameEngine()
        let chest = TreasureChest(integrity: 50, tier: 1)
        let outcome = engine.resolveChestRoll(roll: 15, chest: chest)

        XCTAssertEqual(outcome.resources, 3)
        XCTAssertEqual(outcome.damage, 15)
        XCTAssertEqual(chest.integrity, 35)
    }

    func testChestRollCritGives5Resources() {
        let engine = GameEngine()
        let chest = TreasureChest(integrity: 50, tier: 1)
        let outcome = engine.resolveChestRoll(roll: 20, chest: chest)

        XCTAssertEqual(outcome.resources, 5)
        XCTAssertEqual(outcome.damage, 40) // 20 * 2
        XCTAssertEqual(chest.integrity, 10)
    }

    func testChestRollDamageClampedToIntegrity() {
        let engine = GameEngine()
        let chest = TreasureChest(integrity: 5, tier: 1)
        let outcome = engine.resolveChestRoll(roll: 15, chest: chest)

        XCTAssertEqual(outcome.damage, 5) // Clamped to remaining integrity
        XCTAssertEqual(chest.integrity, 0)
        XCTAssertTrue(chest.isDestroyed)
    }

    // MARK: - Passive Income Tests

    func testPassiveIncomeFromGear() {
        let engine = GameEngine()
        let gear = [
            makeCard(name: "Helm", gearSlot: .head),
            makeCard(name: "Sword", gearSlot: .weapon),
            makeCard(name: "Boots", gearSlot: .feet),
        ]
        let income = engine.applyPassiveIncome(gear: gear)
        XCTAssertEqual(income, 3) // 1 per gear
    }

    func testPassiveIncomeIgnoresNonGear() {
        let engine = GameEngine()
        let mixed = [
            makeCard(name: "Sword", type: .gear, gearSlot: .weapon),
            makeCard(name: "Fireball", type: .ability, gearSlot: nil, durability: nil),
        ]
        let income = engine.applyPassiveIncome(gear: mixed)
        XCTAssertEqual(income, 1) // Only the gear card counts
    }

    func testPassiveIncomeEmptyGear() {
        let engine = GameEngine()
        let income = engine.applyPassiveIncome(gear: [])
        XCTAssertEqual(income, 0)
    }

    // MARK: - Discard for Resource Tests

    func testDiscardForResourceReturns1() {
        let engine = GameEngine()
        var session = makeSession()
        let card = makeCard(name: "Discard Me")
        session.playerHand = [card]

        let resources = engine.discardForResource(card: card, session: &session)
        XCTAssertEqual(resources, 1)
        XCTAssertTrue(session.playerHand.isEmpty)
    }

    // MARK: - Play Card Tests

    func testPlayGearCardEquipsToSlot() {
        let engine = GameEngine()
        var session = makeSession()
        session.playerResources = 5

        let weapon = makeCard(name: "Epic Sword", type: .gear, gearSlot: .weapon, cost: 2)
        session.playerHand = [weapon]

        engine.playCard(card: weapon, session: &session)

        XCTAssertEqual(session.playerResources, 3)
        XCTAssertTrue(session.playerHand.isEmpty)
        XCTAssertNotNil(session.activeGear.card(in: .weapon))
        XCTAssertEqual(session.activeGear.card(in: .weapon)?.name, "Epic Sword")
    }

    func testPlayTalentCardAddedToActiveTalents() {
        let engine = GameEngine()
        var session = makeSession()
        session.playerResources = 5

        let talent = makeCard(name: "Battle Focus", type: .talent, gearSlot: nil, cost: 1, durability: nil)
        session.playerHand = [talent]

        engine.playCard(card: talent, session: &session)

        XCTAssertEqual(session.activeTalents.count, 1)
        XCTAssertEqual(session.activeTalents.first?.name, "Battle Focus")
    }

    func testPlayCardFailsIfNotEnoughResources() {
        let engine = GameEngine()
        var session = makeSession()
        session.playerResources = 1

        let expensiveCard = makeCard(name: "Expensive", cost: 5)
        session.playerHand = [expensiveCard]

        engine.playCard(card: expensiveCard, session: &session)

        XCTAssertEqual(session.playerResources, 1) // Unchanged
        XCTAssertEqual(session.playerHand.count, 1) // Still in hand
    }

    func testPlayCardFailsIfNotInHand() {
        let engine = GameEngine()
        var session = makeSession()
        session.playerResources = 10

        let ghost = makeCard(name: "Ghost Card")
        session.playerHand = [] // Empty hand

        engine.playCard(card: ghost, session: &session)
        XCTAssertEqual(session.playerResources, 10) // Unchanged
    }

    // MARK: - Chest Defeated Tests

    func testCheckChestDefeated() {
        let engine = GameEngine()
        let alive = TreasureChest(integrity: 10, tier: 1)
        XCTAssertFalse(engine.checkChestDefeated(chest: alive))

        let dead = TreasureChest(integrity: 5, tier: 1)
        _ = dead.takeDamage(5)
        XCTAssertTrue(engine.checkChestDefeated(chest: dead))
    }

    // MARK: - Tier Effect Award Tests

    func testAwardTierEffect() {
        let engine = GameEngine()
        var champ = makeChampionRef()

        let tier1 = engine.awardTierEffect(tier: 1, champion: &champ)
        XCTAssertNotNil(tier1)
        XCTAssertEqual(tier1?.effect, .shield)

        let tier2 = engine.awardTierEffect(tier: 2, champion: &champ)
        XCTAssertNotNil(tier2)
        XCTAssertEqual(tier2?.effect, .damageBoost)
    }

    func testAwardTierEffectInvalidTier() {
        let engine = GameEngine()
        var champ = makeChampionRef()

        let invalid = engine.awardTierEffect(tier: 3, champion: &champ)
        XCTAssertNil(invalid)
    }

    // MARK: - Arena Phase: Attack Resolution Tests

    func testAttackHitWithMitigation() {
        let engine = GameEngine()
        let outcome = engine.resolveAttack(
            attackerRoll: 15,
            attackerModifiers: 3,
            defenderAC: 12,
            defenderMG: 5
        )

        XCTAssertTrue(outcome.didHit)
        XCTAssertEqual(outcome.rawDamage, 18) // 15 + 3
        XCTAssertEqual(outcome.mitigated, 5)
        XCTAssertEqual(outcome.finalDamage, 13) // 18 - 5
    }

    func testAttackMiss() {
        let engine = GameEngine()
        let outcome = engine.resolveAttack(
            attackerRoll: 5,
            attackerModifiers: 2,
            defenderAC: 12,
            defenderMG: 3
        )

        XCTAssertFalse(outcome.didHit)
        XCTAssertEqual(outcome.finalDamage, 0)
    }

    func testAttackExactlyMeetsAC() {
        let engine = GameEngine()
        let outcome = engine.resolveAttack(
            attackerRoll: 10,
            attackerModifiers: 2,
            defenderAC: 12,
            defenderMG: 3
        )

        XCTAssertTrue(outcome.didHit) // Equal to AC counts as hit
        XCTAssertEqual(outcome.finalDamage, 9) // 12 - 3
    }

    func testAttackMitigationCannotExceedDamage() {
        let engine = GameEngine()
        let outcome = engine.resolveAttack(
            attackerRoll: 10,
            attackerModifiers: 0,
            defenderAC: 8,
            defenderMG: 50
        )

        XCTAssertTrue(outcome.didHit)
        XCTAssertEqual(outcome.mitigated, 10) // Clamped to rawDamage
        XCTAssertEqual(outcome.finalDamage, 0) // Fully mitigated
    }

    // MARK: - Durability Tests

    func testApplyDurabilityLoss() {
        let engine = GameEngine()
        var card = makeCard(name: "Fragile Sword", durability: 3)

        engine.applyDurabilityLoss(card: &card, amount: 1)
        XCTAssertEqual(card.durability, 2)

        engine.applyDurabilityLoss(card: &card, amount: 5) // Overkill
        XCTAssertEqual(card.durability, 0)
    }

    func testApplyDurabilityLossNilDurability() {
        let engine = GameEngine()
        var card = makeCard(name: "Talent", type: .talent, gearSlot: nil, durability: nil)

        engine.applyDurabilityLoss(card: &card, amount: 1)
        XCTAssertNil(card.durability) // Unchanged
    }

    func testGearDurabilityLossRemovesAtZero() {
        let engine = GameEngine()
        var session = makeSession()
        let weapon = makeCard(name: "Brittle Sword", durability: 1)
        session.activeGear.equipRef(weapon, in: .weapon)

        engine.applyGearDurabilityLoss(slot: .weapon, amount: 1, session: &session)
        XCTAssertNil(session.activeGear.card(in: .weapon)) // Removed at 0
    }

    // MARK: - Champion Defeated Tests

    func testCheckChampionDefeated() {
        let engine = GameEngine()
        XCTAssertTrue(engine.checkChampionDefeated(hp: 0))
        XCTAssertTrue(engine.checkChampionDefeated(hp: -5))
        XCTAssertFalse(engine.checkChampionDefeated(hp: 1))
    }

    // MARK: - Draw Card Tests

    func testDrawCardMovesFromDeckToHand() {
        let engine = GameEngine()
        var deck = [makeCard(name: "Card A"), makeCard(name: "Card B")]
        var hand: [CardReference] = []

        engine.drawCard(deck: &deck, hand: &hand)

        XCTAssertEqual(hand.count, 1)
        XCTAssertEqual(hand.first?.name, "Card A")
        XCTAssertEqual(deck.count, 1)
    }

    func testDrawCardRespectsHandSize() {
        let engine = GameEngine()
        var deck = [makeCard(name: "Card A")]
        var hand = (0..<5).map { makeCard(name: "Hand \($0)") }

        engine.drawCard(deck: &deck, hand: &hand, handSize: 5)

        XCTAssertEqual(hand.count, 5) // No draw, hand is full
        XCTAssertEqual(deck.count, 1) // Card stays in deck
    }

    func testDrawCardFromEmptyDeck() {
        let engine = GameEngine()
        var deck: [CardReference] = []
        var hand: [CardReference] = []

        engine.drawCard(deck: &deck, hand: &hand)

        XCTAssertTrue(hand.isEmpty)
        XCTAssertTrue(deck.isEmpty)
    }

    func testDrawMultipleCards() {
        let engine = GameEngine()
        var deck = (0..<10).map { makeCard(name: "Card \($0)") }
        var hand: [CardReference] = []

        engine.drawCards(count: 3, deck: &deck, hand: &hand)

        XCTAssertEqual(hand.count, 3)
        XCTAssertEqual(deck.count, 7)
    }

    // MARK: - End Turn Tests

    func testEndTurnClearsResourcesAndDraws() {
        let engine = GameEngine()
        var session = makeSession(deckSize: 10)
        session.playerResources = 5
        session.playerHand = [makeCard(name: "Existing")]

        engine.endTurn(session: &session)

        XCTAssertEqual(session.playerResources, 0)
        XCTAssertEqual(session.playerHand.count, 2) // 1 existing + 1 drawn
    }

    // MARK: - Game Setup Tests

    func testSetupGameDrawsOpeningHand() {
        let engine = GameEngine()
        var session = makeSession(deckSize: 40)

        engine.setupGame(session: &session)

        XCTAssertEqual(session.playerHand.count, 5)
        XCTAssertEqual(session.playerDeck.count, 35)
        XCTAssertEqual(session.currentChestTier, 1)
        XCTAssertEqual(session.currentChestIntegrity, 20)
    }

    // MARK: - Chest Advancement Tests

    func testAdvanceChestIncrementsTier() {
        let engine = GameEngine()
        var session = makeSession()
        session.chestCount = 0

        engine.advanceChest(session: &session)

        XCTAssertEqual(session.chestCount, 1)
        XCTAssertEqual(session.currentChestTier, 2)
        XCTAssertEqual(session.currentChestIntegrity, 35)
    }

    func testAdvanceChestToArenaPhase() {
        let engine = GameEngine()
        var session = makeSession()
        session.chestCount = 2 // Already at 2, next advance = 3 = maxChests

        engine.advanceChest(session: &session)

        XCTAssertEqual(session.chestCount, 3)
        XCTAssertEqual(session.phase, .arena)
    }
}
