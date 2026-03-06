import XCTest
@testable import ArenaRaiders

final class PhaseProgressionTests: XCTestCase {

    // MARK: - Helpers

    private func makeChampion() -> Champion {
        Champion(
            stringId: "champ_test",
            name: "Test Champion",
            archetype: .warrior,
            hp: 30,
            avoidance: 12,
            mitigation: 3,
            innatePassive: InnatePassive(name: "Test Passive", effectDescription: "Test"),
            tierEffects: [
                TierEffect(tier: 1, name: "Power Surge", effectDescription: "+2 Attack after Chest 1"),
                TierEffect(tier: 2, name: "Iron Will", effectDescription: "+3 MG after Chest 2")
            ]
        )
    }

    private func makeSession() -> GameSession {
        GameSession(phase: .raid, champion: makeChampion())
    }

    // MARK: - 1. Chest registers as defeated at 0 HP

    func testChestDestroyedAtZeroIntegrity() {
        let engine = GameEngine()
        let chest = TreasureChest(integrity: 30, tier: 1)

        XCTAssertFalse(chest.isDestroyed, "Chest should be alive at full integrity")
        XCTAssertFalse(engine.checkChestDefeated(chest: chest))

        _ = chest.takeDamage(29)
        XCTAssertFalse(chest.isDestroyed, "Chest at 1 HP should still be alive")

        _ = chest.takeDamage(1)
        XCTAssertTrue(chest.isDestroyed, "Chest at 0 HP should be destroyed")
        XCTAssertTrue(engine.checkChestDefeated(chest: chest))

        print("PASS: Battered Chest (30 HP) is destroyed when integrity reaches 0")
    }

    // MARK: - 2. Killing blow is the roll that brings integrity to 0

    func testKillingBlowIdentifiedByChestRoll() {
        let engine = GameEngine(dice: FixedDiceProvider(values: [14]))
        let chest = TreasureChest(integrity: 5, tier: 1)

        // Roll a Hit (14) against a chest with only 5 HP left
        let outcome = engine.resolveChestRoll(roll: 14, chest: chest)

        // takeDamage caps at remaining integrity
        XCTAssertEqual(outcome.damage, 5, "Damage should be capped at remaining integrity (5)")
        XCTAssertTrue(chest.isDestroyed, "Chest should be destroyed after killing blow")
        XCTAssertTrue(outcome.result.isHit, "The killing blow was a Hit roll")

        print("PASS: Killing blow correctly identified — roll dealt \(outcome.damage) damage, chest destroyed")
    }

    // MARK: - 3. After chest kill, advanceChest progresses or transitions

    func testAdvanceChestOffersNextChestOrArena() {
        let engine = GameEngine()
        var session = makeSession()

        // After chest 1 kill — should advance to tier 2 (not arena yet)
        session.chestCount = 0
        engine.advanceChest(session: &session)
        XCTAssertEqual(session.phase, .raid, "Still in raid after chest 1")
        XCTAssertEqual(session.chestCount, 1)
        XCTAssertEqual(session.currentChestTier, 2)
        XCTAssertEqual(session.chestsRemaining, 2)
        print("PASS: After chest 1 kill → raid continues, tier 2 chest spawned, \(session.chestsRemaining) remaining")

        // After chest 2 kill — should advance to tier 3 (not arena yet)
        engine.advanceChest(session: &session)
        XCTAssertEqual(session.phase, .raid, "Still in raid after chest 2")
        XCTAssertEqual(session.chestCount, 2)
        XCTAssertEqual(session.currentChestTier, 3)
        XCTAssertEqual(session.chestsRemaining, 1)
        print("PASS: After chest 2 kill → raid continues, tier 3 chest spawned, \(session.chestsRemaining) remaining")

        // After chest 3 kill — must transition to arena
        engine.advanceChest(session: &session)
        XCTAssertEqual(session.phase, .arena, "Must be in arena after chest 3")
        XCTAssertEqual(session.chestCount, 3)
        XCTAssertEqual(session.chestsRemaining, 0)
        print("PASS: After chest 3 kill → arena phase begins, 0 chests remaining")
    }

    // MARK: - 4. After 3 chests destroyed, arena begins

    func testThreeChestsTriggerArena() {
        let engine = GameEngine()
        var session = makeSession()

        for i in 1...3 {
            engine.advanceChest(session: &session)
            print("  Chest \(i) cleared → chestCount=\(session.chestCount), phase=\(session.phase)")
        }

        XCTAssertEqual(session.phase, .arena, "Arena must begin after 3 chests")
        XCTAssertEqual(session.chestCount, 3)
        print("PASS: 3 chests destroyed → arena phase begins regardless")
    }

    // MARK: - 5. chestCount is tracked and no 4th chest spawns

    func testNoFourthChestSpawns() {
        let engine = GameEngine()
        var session = makeSession()

        // Advance through all 3 chests
        for _ in 1...3 {
            engine.advanceChest(session: &session)
        }
        XCTAssertEqual(session.chestCount, 3)
        XCTAssertEqual(session.phase, .arena)

        // Attempt a 4th advance — phase stays arena, count stays 3
        let tierBefore = session.currentChestTier
        let integrityBefore = session.currentChestIntegrity
        engine.advanceChest(session: &session)
        XCTAssertEqual(session.chestCount, 4, "chestCount increments but phase guard prevents new chest")
        XCTAssertEqual(session.phase, .arena, "Phase must remain .arena")
        // Verify no new chest was configured (tier and integrity unchanged)
        XCTAssertEqual(session.currentChestTier, tierBefore,
                       "No new chest tier should be set after arena transition")
        XCTAssertEqual(session.currentChestIntegrity, integrityBefore,
                       "No new chest integrity should be set after arena transition")
        print("PASS: 4th advanceChest → phase stays .arena, no new chest configured")
    }

    // MARK: - 6. Arena phase sets session.phase to .arena

    func testArenaPhaseIsSetCorrectly() {
        let engine = GameEngine()
        var session = makeSession()
        XCTAssertEqual(session.phase, .raid, "Session starts in raid phase")

        session.chestCount = 2 // About to clear 3rd chest
        engine.advanceChest(session: &session)

        XCTAssertEqual(session.phase, .arena, "Phase should be .arena")
        XCTAssertEqual(session.phase.displayName, "Arena")
        print("PASS: GameSession.phase set to .arena after 3rd chest cleared")
    }

    // MARK: - 7. Tier effects available after chest kills

    func testTierEffectsAvailableAfterChestKills() {
        let engine = GameEngine()
        let champion = makeChampion()
        var champRef = ChampionReference(champion: champion)

        // Before any chests — tier effects exist but haven't been "awarded"
        XCTAssertEqual(champRef.tierEffects.count, 2, "Champion should have 2 tier effects defined")

        // Tier 1 available after chest 1
        let tier1 = engine.awardTierEffect(tier: 1, champion: &champRef)
        XCTAssertNotNil(tier1, "Tier 1 effect should be available")
        XCTAssertEqual(tier1?.name, "Power Surge")
        XCTAssertEqual(tier1?.tier, 1)
        print("PASS: Tier 1 effect '\(tier1!.name)' available after chest 1 kill")

        // Tier 2 available after chest 2
        let tier2 = engine.awardTierEffect(tier: 2, champion: &champRef)
        XCTAssertNotNil(tier2, "Tier 2 effect should be available")
        XCTAssertEqual(tier2?.name, "Iron Will")
        XCTAssertEqual(tier2?.tier, 2)
        print("PASS: Tier 2 effect '\(tier2!.name)' available after chest 2 kill")

        // No tier 3 effect exists
        let tier3 = engine.awardTierEffect(tier: 3, champion: &champRef)
        XCTAssertNil(tier3, "Tier 3 effect should not exist (capped at 2)")
        print("PASS: No tier 3 effect — awardTierEffect returns nil for tier > 2")
    }

    // MARK: - Full Raid Phase simulation

    func testFullRaidPhasePlayByPlay() {
        // Simulate a complete raid with fixed Hit rolls (14) against a Battered Chest (30 HP)
        let engine = GameEngine(dice: FixedDiceProvider(values: [14]))
        var session = makeSession()
        session.playerResources = 0

        let chest = TreasureChest(integrity: 30, tier: 1)
        var turnNumber = 0

        print("\n===== FULL RAID SIMULATION: Battered Chest (30 HP) =====")
        print("Champion: \(session.playerChampion?.name ?? "Unknown") | Phase: \(session.phase.displayName)")
        print("Roll sequence: fixed at 14 (Hit)\n")

        while !chest.isDestroyed {
            turnNumber += 1
            let roll = engine.rollD20()
            let outcome = engine.resolveChestRoll(roll: roll, chest: chest, session: session)
            session.playerResources += outcome.resources

            print("Turn \(turnNumber): Rolled \(roll) → \(outcome.result.isHit ? "HIT" : "MISS") | "
                + "Damage: \(outcome.damage) | Chest HP: \(chest.integrity)/30 | "
                + "Resources gained: \(outcome.resources) | Total resources: \(session.playerResources)")

            if chest.isDestroyed {
                print("  >>> CHEST DESTROYED on turn \(turnNumber)!")

                // Award tier effect
                let tierToAward = session.chestCount + 1
                if var champ = session.playerChampion {
                    if let effect = engine.awardTierEffect(tier: tierToAward, champion: &champ) {
                        print("  >>> Tier \(tierToAward) effect unlocked: \(effect.name)")
                    }
                }

                engine.advanceChest(session: &session)
                print("  >>> Phase: \(session.phase.displayName) | Chests cleared: \(session.chestCount)/\(GameSession.maxChests)")
            }
        }

        print("\n--- Summary ---")
        print("Turns to destroy chest: \(turnNumber)")
        print("Total resources earned: \(session.playerResources)")
        print("Phase after chest 1: \(session.phase.displayName)")
        print("Chests remaining: \(session.chestsRemaining)")
        print("=================================================\n")

        XCTAssertTrue(chest.isDestroyed)
        XCTAssertEqual(session.chestCount, 1, "One chest should be cleared")
        XCTAssertEqual(session.phase, .raid, "Still in raid after first chest")
        XCTAssertGreaterThan(turnNumber, 0)

        print("PASS: Full raid simulation completed in \(turnNumber) turns")
    }
}
