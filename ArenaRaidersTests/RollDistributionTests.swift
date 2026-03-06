import XCTest
@testable import ArenaRaiders

final class RollDistributionTests: XCTestCase {

    // MARK: - Deterministic outcome tests

    func testMissReturnsExactly1ResourceAnd0Damage() {
        let engine = GameEngine(dice: FixedDiceProvider(values: [1]))
        for roll in 1...9 {
            let chest = TreasureChest(integrity: 1000, tier: 1)
            let outcome = engine.resolveChestRoll(roll: roll, chest: chest)
            XCTAssertTrue(outcome.result.isMiss, "Roll \(roll) should be a miss")
            XCTAssertEqual(outcome.resources, 1, "Miss should give exactly 1 resource, got \(outcome.resources)")
            XCTAssertEqual(outcome.damage, 0, "Miss should deal 0 damage, got \(outcome.damage)")
        }
    }

    func testHitReturnsExactly3ResourcesAndDamageEqualsRoll() {
        let engine = GameEngine(dice: FixedDiceProvider(values: [10]))
        for roll in 10...19 {
            let chest = TreasureChest(integrity: 1000, tier: 1)
            let outcome = engine.resolveChestRoll(roll: roll, chest: chest)
            XCTAssertTrue(outcome.result.isHit, "Roll \(roll) should be a hit")
            XCTAssertEqual(outcome.resources, 3, "Hit should give exactly 3 resources, got \(outcome.resources)")
            XCTAssertEqual(outcome.damage, roll, "Hit damage should equal roll value \(roll), got \(outcome.damage)")
        }
    }

    func testCritReturnsExactly5ResourcesAnd40Damage() {
        let engine = GameEngine(dice: FixedDiceProvider(values: [20]))
        let chest = TreasureChest(integrity: 1000, tier: 1)
        let outcome = engine.resolveChestRoll(roll: 20, chest: chest)
        XCTAssertTrue(outcome.result.isCrit, "Roll 20 should be a crit")
        XCTAssertEqual(outcome.resources, 5, "Crit should give exactly 5 resources, got \(outcome.resources)")
        XCTAssertEqual(outcome.damage, 40, "Crit should deal 40 damage (20x2), got \(outcome.damage)")
    }

    // MARK: - Distribution test (10,000 rolls)

    func testRollDistributionOver10000Rolls() {
        let engine = GameEngine(dice: RandomDiceProvider())
        let totalRolls = 10_000

        var missCount = 0
        var hitCount = 0
        var critCount = 0
        var totalResources = 0
        var totalDamage = 0

        for _ in 0..<totalRolls {
            let roll = engine.rollD20()
            let chest = TreasureChest(integrity: 1000, tier: 1)
            let outcome = engine.resolveChestRoll(roll: roll, chest: chest)

            totalResources += outcome.resources
            totalDamage += outcome.damage

            if outcome.result.isMiss {
                missCount += 1
                // Verify miss outcomes
                XCTAssertEqual(outcome.resources, 1, "Miss on roll \(roll) gave \(outcome.resources) resources instead of 1")
                XCTAssertEqual(outcome.damage, 0, "Miss on roll \(roll) dealt \(outcome.damage) damage instead of 0")
            } else if outcome.result.isHit {
                hitCount += 1
                // Verify hit outcomes
                XCTAssertEqual(outcome.resources, 3, "Hit on roll \(roll) gave \(outcome.resources) resources instead of 3")
                XCTAssertEqual(outcome.damage, roll, "Hit on roll \(roll) dealt \(outcome.damage) damage instead of \(roll)")
            } else if outcome.result.isCrit {
                critCount += 1
                // Verify crit outcomes
                XCTAssertEqual(outcome.resources, 5, "Crit gave \(outcome.resources) resources instead of 5")
                XCTAssertEqual(outcome.damage, 40, "Crit dealt \(outcome.damage) damage instead of 40")
            }
        }

        let missPct = Double(missCount) / Double(totalRolls) * 100
        let hitPct = Double(hitCount) / Double(totalRolls) * 100
        let critPct = Double(critCount) / Double(totalRolls) * 100
        let avgResources = Double(totalResources) / Double(totalRolls)
        let avgDamage = Double(totalDamage) / Double(totalRolls)

        // Expected averages:
        // Resources: 0.45*1 + 0.50*3 + 0.05*5 = 0.45 + 1.50 + 0.25 = 2.20
        // Damage:    0.45*0 + sum(hit rolls 10..19 each at 5%)*value + 0.05*40
        //          = 0 + 0.05*(10+11+12+13+14+15+16+17+18+19) + 0.05*40
        //          = 0.05*145 + 2.0 = 7.25 + 2.0 = 9.25
        let expectedAvgResources = 2.20
        let expectedAvgDamage = 9.25

        print("===== D20 ROLL DISTRIBUTION (10,000 rolls) =====")
        print("Misses (1-9):   \(missCount) (\(String(format: "%.1f", missPct))%) — expected ~45%")
        print("Hits  (10-19):  \(hitCount) (\(String(format: "%.1f", hitPct))%) — expected ~50%")
        print("Crits (20):     \(critCount) (\(String(format: "%.1f", critPct))%) — expected ~5%")
        print("")
        print("Avg resources/roll: \(String(format: "%.3f", avgResources)) — expected ~\(expectedAvgResources)")
        print("Avg damage/roll:    \(String(format: "%.3f", avgDamage)) — expected ~\(expectedAvgDamage)")
        print("=================================================")

        // Flag anything outside expected ranges (generous tolerance for randomness)
        var flags: [String] = []

        if missPct < 40.0 || missPct > 50.0 {
            flags.append("MISS rate \(String(format: "%.1f", missPct))% outside expected range [40%-50%]")
        }
        if hitPct < 45.0 || hitPct > 55.0 {
            flags.append("HIT rate \(String(format: "%.1f", hitPct))% outside expected range [45%-55%]")
        }
        if critPct < 2.0 || critPct > 8.0 {
            flags.append("CRIT rate \(String(format: "%.1f", critPct))% outside expected range [2%-8%]")
        }
        if abs(avgResources - expectedAvgResources) > 0.15 {
            flags.append("Avg resources \(String(format: "%.3f", avgResources)) deviates from expected \(expectedAvgResources)")
        }
        if abs(avgDamage - expectedAvgDamage) > 1.0 {
            flags.append("Avg damage \(String(format: "%.3f", avgDamage)) deviates from expected \(expectedAvgDamage)")
        }

        if flags.isEmpty {
            print("ALL RESULTS WITHIN EXPECTED RANGES")
        } else {
            for flag in flags {
                print("FLAG: \(flag)")
            }
            XCTFail("Distribution outside expected ranges: \(flags.joined(separator: "; "))")
        }

        // Sanity: all rolls accounted for
        XCTAssertEqual(missCount + hitCount + critCount, totalRolls, "All rolls must be classified")
    }
}
