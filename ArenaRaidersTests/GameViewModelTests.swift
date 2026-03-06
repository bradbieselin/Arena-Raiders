import XCTest
@testable import ArenaRaiders

final class GameViewModelTests: XCTestCase {

    // MARK: - Helpers

    private func makeCard(
        stringId: String = "test_card",
        name: String = "Test Card",
        type: CardType = .ability,
        gearSlot: GearSlot? = nil,
        cost: Int = 1,
        durability: Int? = nil
    ) -> CardReference {
        CardReference(card: Card(
            stringId: stringId,
            name: name,
            cardType: type,
            gearSlot: type == .gear ? gearSlot : nil,
            resourceCost: cost,
            durability: durability,
            effectDescription: "Test"
        ))
    }

    private func makeChampion() -> Champion {
        Champion(
            stringId: "champ_test",
            name: "Test Champ",
            archetype: .warrior,
            hp: 30,
            avoidance: 12,
            mitigation: 3,
            innatePassive: InnatePassive(name: "None", effectDescription: "None")
        )
    }

    /// Creates a GameViewModel with a FixedDiceProvider for deterministic testing.
    private func makeVM(
        rolls: [Int],
        deckCards: [CardReference]? = nil
    ) -> GameViewModel {
        let champion = makeChampion()
        let deck = deckCards ?? (0..<20).map { i in
            makeCard(stringId: "deck_\(i)", name: "Deck Card \(i)", cost: 1)
        }
        let session = GameSession(champion: champion, deckCards: deck)
        let engine = GameEngine(dice: FixedDiceProvider(values: rolls))
        return GameViewModel(session: session, engine: engine)
    }

    // MARK: - Test 1: Init with valid GameSession

    func testInitCreatesValidSession() {
        let vm = makeVM(rolls: [10])

        // Session exists and is in raid phase
        XCTAssertEqual(vm.phase, .raid)

        // Champion is set
        XCTAssertEqual(vm.championName, "Test Champ")

        // setupGame draws 5 cards from the 20-card deck
        XCTAssertEqual(vm.hand.count, 5)
        XCTAssertEqual(vm.deckCount, 15) // 20 - 5

        // Chest was spawned (tier 1, integrity 20)
        XCTAssertFalse(vm.chestDestroyed)
        XCTAssertEqual(vm.chestHP, 20)
        XCTAssertEqual(vm.chestMaxIntegrity, 20)

        // Starting resources
        XCTAssertEqual(vm.playerResources, GameSession.startingResources)

        // HP matches champion
        XCTAssertEqual(vm.playerHP, 30)
        XCTAssertEqual(vm.playerMaxHP, 30)
    }

    // MARK: - Test 2: rollForChest() – Miss (roll 5)

    func testRollForChestMiss() {
        let vm = makeVM(rolls: [5])
        let resourcesBefore = vm.playerResources

        vm.rollForChest()

        // Roll animation state is set
        XCTAssertEqual(vm.rollResult, 5)
        XCTAssertEqual(vm.rollLabel, "MISS")
        XCTAssertTrue(vm.showRoll)

        // Miss gives 1 resource, chest not damaged
        XCTAssertEqual(vm.playerResources, resourcesBefore + 1)
        XCTAssertEqual(vm.chestHP, 20) // unchanged
    }

    // MARK: - Test 2b: rollForChest() – Hit (roll 12)

    func testRollForChestHit() {
        let vm = makeVM(rolls: [12])
        let resourcesBefore = vm.playerResources

        vm.rollForChest()

        XCTAssertEqual(vm.rollResult, 12)
        XCTAssertEqual(vm.rollLabel, "HIT")
        XCTAssertTrue(vm.showRoll)

        // Hit gives 3 resources
        XCTAssertEqual(vm.playerResources, resourcesBefore + 3)

        // Chest takes damage (roll value 12 + 0 attack mods = 12 damage)
        XCTAssertEqual(vm.chestHP, 20 - 12)
    }

    // MARK: - Test 2c: rollForChest() – Crit (roll 20)

    func testRollForChestCrit() {
        let vm = makeVM(rolls: [20])
        let resourcesBefore = vm.playerResources

        vm.rollForChest()

        XCTAssertEqual(vm.rollResult, 20)
        XCTAssertEqual(vm.rollLabel, "CRIT!")
        XCTAssertTrue(vm.showRoll)

        // Crit gives 5 resources
        XCTAssertEqual(vm.playerResources, resourcesBefore + 5)

        // Crit deals (20+0)*2 = 40 damage, destroying chest 1 (20 HP).
        // advanceChest increments chestCount to 1, spawnChest creates tier-2 chest (35 HP).
        XCTAssertEqual(vm.session.chestCount, 1)
        XCTAssertEqual(vm.chestHP, 35) // new tier-2 chest
        XCTAssertEqual(vm.chestMaxIntegrity, 35)
    }

    // MARK: - Test 3: endTurn() clears and refills resources

    func testEndTurnResetsResources() {
        // Roll 5 (miss) to give +1 resource so we start with non-zero
        let vm = makeVM(rolls: [5])
        vm.rollForChest()
        XCTAssertEqual(vm.playerResources, GameSession.startingResources + 1) // 3 + 1 = 4

        // Hand is at 5 (full opening hand). endTurn enforces hand size limit
        // by discarding excess, then draws 1 card — net result is still 5.
        vm.endTurn()

        // Resources reset to 0, then +3 starting resources added
        XCTAssertEqual(vm.playerResources, GameSession.startingResources)

        // Turn incremented
        XCTAssertEqual(vm.session.currentTurn, 2)

        // Hand was at limit (5), enforceHandSize keeps it at 5, then draws 1 → 6.
        // But enforceHandSize runs BEFORE draw, so: 5 → 5 (no excess) → draw → 6.
        // Wait — that means hand can exceed limit mid-turn. The limit is only
        // enforced at start of endTurn, then draw happens after, which is correct:
        // the player must discard excess on their NEXT endTurn.
        XCTAssertEqual(vm.hand.count, 6)
    }

    // MARK: - Test 4: playSelectedCard() removes card from hand

    func testPlayCardRemovesFromHand() {
        let vm = makeVM(rolls: [10])

        // Hand has 5 cards after init, resources = 3
        XCTAssertEqual(vm.hand.count, 5)

        // Pick first card (cost 1 ability)
        let card = vm.hand[0]
        XCTAssertTrue(card.resourceCost <= vm.playerResources)

        let resourcesBefore = vm.playerResources
        vm.playSelectedCard(card)

        // Card removed from hand
        XCTAssertEqual(vm.hand.count, 4)
        XCTAssertFalse(vm.hand.contains(where: { $0.id == card.id }))

        // Resources deducted
        XCTAssertEqual(vm.playerResources, resourcesBefore - card.resourceCost)

        // Ability cards go to discard
        XCTAssertTrue(vm.session.playerDiscard.contains(where: { $0.id == card.id }))
    }

    // MARK: - Test 4b: playSelectedCard() rejects if too expensive

    func testPlayCardRejectsIfTooExpensive() {
        // Build deck with expensive cards (cost 10)
        let expensiveCards = (0..<20).map { i in
            makeCard(stringId: "exp_\(i)", name: "Expensive \(i)", cost: 10)
        }
        let vm = makeVM(rolls: [10], deckCards: expensiveCards)

        let card = vm.hand[0]
        XCTAssertTrue(card.resourceCost > vm.playerResources)

        vm.playSelectedCard(card)

        // Card should still be in hand — not played
        XCTAssertEqual(vm.hand.count, 5)
        XCTAssertTrue(vm.hand.contains(where: { $0.id == card.id }))
    }

    // MARK: - Test 5: phase is .raid on game start

    func testPhaseIsRaidOnStart() {
        let vm = makeVM(rolls: [10])
        XCTAssertEqual(vm.phase, .raid)
        XCTAssertEqual(vm.session.phase, .raid)
    }

    // MARK: - Test 6: phase transitions to .arena after 3 chests defeated

    func testPhaseTransitionsToArenaAfterThreeChests() {
        // Each crit (roll 20) deals (20+0)*2 = 40 damage, destroying any chest.
        // Chest 1 = 20 HP, chest 2 = 35 HP, chest 3 = 50 HP.
        // Need 1 crit per chest 1, 1 per chest 2 (40 > 35), 2 for chest 3 (40 + 40 > 50).
        // Total rolls needed: init uses rolls for setupGame shuffle (none consumed by FixedDiceProvider),
        // then 1 + 1 + 2 = 4 crits.
        let vm = makeVM(rolls: [20, 20, 20, 20])

        // Phase starts as raid
        XCTAssertEqual(vm.phase, .raid)

        // Destroy chest 1 (tier 1, 20 HP) — 1 crit = 40 damage
        vm.rollForChest()
        XCTAssertEqual(vm.session.chestCount, 1)
        XCTAssertEqual(vm.phase, .raid) // Still raiding

        // Destroy chest 2 (tier 2, 35 HP) — 1 crit = 40 damage
        vm.rollForChest()
        XCTAssertEqual(vm.session.chestCount, 2)
        XCTAssertEqual(vm.phase, .raid) // Still raiding

        // Chest 3 (tier 3, 50 HP) — first crit = 40 damage, not destroyed yet
        vm.rollForChest()
        XCTAssertEqual(vm.phase, .raid)
        XCTAssertEqual(vm.chestHP, 10) // 50 - 40

        // Second crit on chest 3 — destroys it, transitions to arena
        vm.rollForChest()
        XCTAssertEqual(vm.session.chestCount, 3)
        XCTAssertEqual(vm.phase, .arena)

        // AI opponent is now set up
        XCTAssertNotNil(vm.aiState)
        XCTAssertTrue(vm.aiHP > 0)
    }
}
