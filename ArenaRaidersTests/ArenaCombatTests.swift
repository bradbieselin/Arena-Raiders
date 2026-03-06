import XCTest
@testable import ArenaRaiders

final class ArenaCombatTests: XCTestCase {

    // MARK: - 1. Miss: roll below Avoidance deals 0

    func testAttackMissDealsZeroDamage() {
        let engine = GameEngine()
        // Roll 9, no weapon bonus, defender AV = 10 → totalAttack 9 < 10 → miss
        let outcome = engine.resolveAttack(
            attackerRoll: 9,
            attackerModifiers: 0,
            defenderAC: 10,
            defenderMG: 3
        )

        XCTAssertFalse(outcome.didHit, "Roll 9 vs AV 10 should miss")
        XCTAssertEqual(outcome.finalDamage, 0, "Miss should deal 0 damage")
        XCTAssertEqual(outcome.rawDamage, 0)
        XCTAssertEqual(outcome.mitigated, 0)
        print("PASS: Roll 9 vs Avoidance 10 → miss, 0 damage")
    }

    // MARK: - 2. Hit: roll meets Avoidance, damage = roll + weapon - MG

    func testAttackHitDealsDamageMinusMitigation() {
        let engine = GameEngine()
        // Roll 10, no weapon bonus, defender AV = 10, MG = 3
        // totalAttack = 10 >= 10 → hit, rawDamage = 10, final = 10 - 3 = 7
        let outcome = engine.resolveAttack(
            attackerRoll: 10,
            attackerModifiers: 0,
            defenderAC: 10,
            defenderMG: 3
        )

        XCTAssertTrue(outcome.didHit, "Roll 10 vs AV 10 should hit (10 >= 10)")
        XCTAssertEqual(outcome.rawDamage, 10)
        XCTAssertEqual(outcome.mitigated, 3)
        XCTAssertEqual(outcome.finalDamage, 7, "Damage = 10 - 3 = 7")
        print("PASS: Roll 10 vs Avoidance 10, MG 3 → hit, damage = 7")
    }

    // MARK: - 3. Crit: roll 20 deals double total damage before mitigation

    func testCritDealsDoubleDamage() {
        let engine = GameEngine()
        // Crit convention (from chest roll pattern): double (roll + mods) before mitigation
        // resolveAttack doesn't handle crit internally — caller doubles the attack total
        let roll = 20
        let weaponBonus = 3
        let critTotal = (roll + weaponBonus) * 2  // 46

        let outcome = engine.resolveAttack(
            attackerRoll: critTotal,
            attackerModifiers: 0,
            defenderAC: 12,
            defenderMG: 2
        )

        XCTAssertTrue(outcome.didHit, "Crit total 46 vs AV 12 should hit")
        XCTAssertEqual(outcome.rawDamage, 46)
        XCTAssertEqual(outcome.mitigated, 2)
        XCTAssertEqual(outcome.finalDamage, 44, "Crit damage = (20+3)*2 - 2 = 44")
        print("PASS: Crit (20+3)*2=46 vs MG 2 → 44 final damage")
    }

    // MARK: - 4. Mitigation cannot reduce damage below 0

    func testMitigationFloorIsZero() {
        let engine = GameEngine()
        // Roll 10 hits AV 10, rawDamage = 10, MG = 50 → should NOT go negative
        let outcome = engine.resolveAttack(
            attackerRoll: 10,
            attackerModifiers: 0,
            defenderAC: 10,
            defenderMG: 50
        )

        XCTAssertTrue(outcome.didHit, "Roll 10 vs AV 10 should hit")
        XCTAssertEqual(outcome.finalDamage, 0, "Mitigation should not reduce below 0")
        XCTAssertGreaterThanOrEqual(outcome.finalDamage, 0, "Damage floor is 0")
        // mitigated is capped at rawDamage (doesn't over-mitigate)
        XCTAssertEqual(outcome.mitigated, 10, "Mitigated should cap at rawDamage, not full MG")
        print("PASS: MG 50 vs rawDamage 10 → mitigated capped at 10, final = 0")
    }

    // MARK: - 5. Champion at 0 HP is defeated

    func testChampionAtZeroHPIsDefeated() {
        let engine = GameEngine()

        XCTAssertTrue(engine.checkChampionDefeated(hp: 0), "0 HP → defeated")
        XCTAssertTrue(engine.checkChampionDefeated(hp: -5), "Negative HP → defeated")
        print("PASS: Champion at 0 HP (and below) is flagged as defeated")
    }

    // MARK: - 6. checkChampionDefeated boundary: true at 0, false at 1

    func testChampionDefeatedBoundary() {
        let engine = GameEngine()

        XCTAssertTrue(engine.checkChampionDefeated(hp: 0), "Exactly 0 HP → defeated")
        XCTAssertFalse(engine.checkChampionDefeated(hp: 1), "1 HP → still alive")
        print("PASS: checkChampionDefeated returns true at 0 HP, false at 1 HP")
    }

    // MARK: - Scenario: Attacker +3 weapon, roll 15, Defender AV 12 MG 2

    func testHitScenarioRoll15() {
        let engine = GameEngine()
        let outcome = engine.resolveAttack(
            attackerRoll: 15,
            attackerModifiers: 3,
            defenderAC: 12,
            defenderMG: 2
        )

        print("\n===== HIT SCENARIO =====")
        print("Attacker: roll=15, weapon bonus=+3, totalAttack=\(outcome.rawDamage)")
        print("Defender: Avoidance=12, Mitigation=2")
        print("Hit check: \(outcome.rawDamage) >= 12 → \(outcome.didHit ? "HIT" : "MISS")")
        print("Damage: \(outcome.rawDamage) - \(outcome.mitigated) MG = \(outcome.finalDamage)")
        print("========================\n")

        XCTAssertTrue(outcome.didHit, "15+3=18 >= 12 → hit")
        XCTAssertEqual(outcome.rawDamage, 18, "Raw = 15 + 3 = 18")
        XCTAssertEqual(outcome.mitigated, 2)
        XCTAssertEqual(outcome.finalDamage, 16, "Final = 18 - 2 = 16")
        print("PASS: Roll 15 + weapon 3 = 18 vs AV 12 → hit, 18 - 2 MG = 16 damage")
    }

    // MARK: - Scenario: Same attacker, crit roll 20

    func testCritScenarioRoll20() {
        let engine = GameEngine()
        let roll = 20
        let weaponBonus = 3
        let defenderMG = 2

        // Crit: double (roll + mods), then subtract MG
        let critTotal = (roll + weaponBonus) * 2  // 46

        let outcome = engine.resolveAttack(
            attackerRoll: critTotal,
            attackerModifiers: 0,
            defenderAC: 12,
            defenderMG: defenderMG
        )

        print("\n===== CRIT SCENARIO =====")
        print("Attacker: roll=20 (CRIT), weapon bonus=+3")
        print("Crit formula: (20 + 3) × 2 = \(critTotal)")
        print("Defender: Avoidance=12, Mitigation=\(defenderMG)")
        print("Hit check: \(critTotal) >= 12 → \(outcome.didHit ? "HIT" : "MISS")")
        print("Damage: \(critTotal) - \(outcome.mitigated) MG = \(outcome.finalDamage)")
        print("=========================\n")

        XCTAssertTrue(outcome.didHit)
        XCTAssertEqual(outcome.rawDamage, 46, "Crit raw = (20+3)*2 = 46")
        XCTAssertEqual(outcome.finalDamage, 44, "Final = 46 - 2 = 44")
        print("PASS: Crit (20+3)×2 = 46 vs MG 2 → 44 damage")
    }
}
