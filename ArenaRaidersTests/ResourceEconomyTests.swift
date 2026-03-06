import XCTest
@testable import ArenaRaiders

final class ResourceEconomyTests: XCTestCase {

    // MARK: - Helpers

    private func makeCard(
        stringId: String = "card_001",
        name: String = "Test Card",
        type: CardType = .gear,
        subtype: CardSubtype? = nil,
        gearSlot: GearSlot? = .weapon,
        cost: Int = 2,
        durability: Int? = 3,
        rarity: Rarity = .common
    ) -> CardReference {
        CardReference(card: Card(
            stringId: stringId,
            name: name,
            cardType: type,
            subtype: subtype,
            gearSlot: type == .gear ? gearSlot : nil,
            resourceCost: cost,
            durability: durability,
            effectDescription: "Test effect",
            rarity: rarity
        ))
    }

    private func makeSession() -> GameSession {
        let champion = Champion(
            stringId: "champ_test",
            name: "Test Champion",
            archetype: .warrior,
            hp: 30,
            avoidance: 12,
            mitigation: 3,
            innatePassive: InnatePassive(name: "Test Passive", effectDescription: "Test desc"),
            tierEffects: []
        )
        return GameSession(phase: .raid, champion: champion)
    }

    // MARK: - Scenario 1: Hit roll with Worn Gloves passive

    func testHitRollWithPassiveGloves() {
        let engine = GameEngine(dice: FixedDiceProvider(values: [14]))
        var session = makeSession()

        // Equip Worn Gloves (card_014) — gives +1 resource/turn
        let gloves = makeCard(
            stringId: "card_014",
            name: "Worn Gloves",
            type: .gear,
            gearSlot: .hands,
            cost: 1,
            durability: 3,
            rarity: .common
        )
        session.activeGear.equipRef(gloves, in: .hands)

        // Start the turn with 0 resources to isolate the economy steps
        session.playerResources = 0

        // Put a card in hand to discard later, and another to play (cost 3)
        let discardCard = makeCard(stringId: "card_test_discard", name: "Discard Me", type: .ability, cost: 1)
        let playCard = makeCard(stringId: "card_test_play", name: "Play Me", type: .ability, cost: 3)
        session.playerHand = [discardCard, playCard]

        // --- Step 1: Roll a Hit (14) ---
        let chest = TreasureChest(integrity: 1000, tier: 1)
        let rollOutcome = engine.resolveChestRoll(roll: 14, chest: chest, session: session)
        session.playerResources += rollOutcome.resources

        // Add passive income from gear
        session.playerResources += engine.computePassiveResourceIncome(session: session)

        print("===== SCENARIO 1: Hit Roll + Passive Gloves =====")
        print("Roll outcome: \(rollOutcome.result), resources from roll: \(rollOutcome.resources)")
        print("Passive income from Worn Gloves: \(engine.computePassiveResourceIncome(session: session))")
        print("Resources after roll + passive: \(session.playerResources)")

        XCTAssertEqual(rollOutcome.resources, 3, "Hit should give 3 resources")
        XCTAssertEqual(session.playerResources, 4,
                       "After roll (3) + passive (1) = 4, got \(session.playerResources)")
        printResult("Resources after roll = 4", session.playerResources == 4)

        // --- Step 2: Discard a card for +1 resource ---
        let discardGain = engine.discardForResource(card: discardCard, session: &session)
        session.playerResources += discardGain

        print("Discard gain: \(discardGain)")
        print("Resources after discard: \(session.playerResources)")

        XCTAssertEqual(discardGain, 1, "Discarding should give +1 resource")
        XCTAssertEqual(session.playerResources, 5,
                       "After discard = 5, got \(session.playerResources)")
        printResult("Resources after discard = 5", session.playerResources == 5)

        // --- Step 3: Play a 3-cost card ---
        engine.playCard(card: playCard, session: &session)

        print("Resources after playing 3-cost card: \(session.playerResources)")

        XCTAssertEqual(session.playerResources, 2,
                       "After playing 3-cost = 2, got \(session.playerResources)")
        printResult("Resources after playing 3-cost = 2", session.playerResources == 2)

        // --- Step 4: End turn — resources reset to 0 ---
        // Seed deck so drawCard doesn't fail
        session.playerDeck = [makeCard(stringId: "card_draw", name: "Draw Card", type: .ability, cost: 1)]
        engine.endTurn(session: &session)

        // endTurn resets to 0, then adds passive (1) + startingResources (3) = 4 for NEXT turn
        // The "unspent resources don't roll over" check: verify the reset happened
        // (final value includes next-turn setup income)
        let expectedNextTurn = 0 + engine.computePassiveResourceIncome(session: session) + GameSession.startingResources
        print("Resources after endTurn (next-turn setup): \(session.playerResources)")
        print("  -> Unspent resources wiped to 0, then +\(GameSession.startingResources) starting + \(engine.computePassiveResourceIncome(session: session)) passive for next turn")

        XCTAssertEqual(session.playerResources, expectedNextTurn,
                       "After endTurn, resources = passive + starting for next turn, got \(session.playerResources)")
        printResult("Unspent resources reset (no carry-over)", session.playerResources == expectedNextTurn)

        print("=================================================\n")
    }

    // MARK: - Scenario 2: Miss roll still grants pity + passive

    func testMissRollStillGrantsPityAndPassive() {
        let engine = GameEngine(dice: FixedDiceProvider(values: [3]))
        var session = makeSession()

        // Equip Worn Gloves (card_014) — gives +1 resource/turn
        let gloves = makeCard(
            stringId: "card_014",
            name: "Worn Gloves",
            type: .gear,
            gearSlot: .hands,
            cost: 1,
            durability: 3,
            rarity: .common
        )
        session.activeGear.equipRef(gloves, in: .hands)

        // Start with 0 resources
        session.playerResources = 0

        // --- Roll a Miss (3) ---
        let chest = TreasureChest(integrity: 1000, tier: 1)
        let rollOutcome = engine.resolveChestRoll(roll: 3, chest: chest, session: session)
        session.playerResources += rollOutcome.resources

        print("===== SCENARIO 2: Miss Roll + Passive Gloves =====")
        print("Roll outcome: \(rollOutcome.result), resources from roll: \(rollOutcome.resources)")

        XCTAssertEqual(rollOutcome.resources, 1, "Miss should give exactly 1 pity resource")
        XCTAssertEqual(rollOutcome.damage, 0, "Miss should deal 0 damage")
        printResult("Miss gives 1 pity resource", rollOutcome.resources == 1)
        printResult("Miss deals 0 damage", rollOutcome.damage == 0)

        // Add passive income
        session.playerResources += engine.computePassiveResourceIncome(session: session)

        print("Passive income from Worn Gloves: \(engine.computePassiveResourceIncome(session: session))")
        print("Total resources (pity + passive): \(session.playerResources)")

        XCTAssertEqual(session.playerResources, 2,
                       "Pity (1) + passive (1) = 2, got \(session.playerResources)")
        printResult("Pity + passive = 2", session.playerResources == 2)

        print("==================================================\n")
    }

    // MARK: - Print helper

    private func printResult(_ label: String, _ passed: Bool) {
        print("  \(passed ? "PASS" : "FAIL"): \(label)")
    }
}
