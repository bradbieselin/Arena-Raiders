import XCTest
@testable import ArenaRaiders

final class GameEffectHandlerTests: XCTestCase {

    // MARK: - Card Effect Map Coverage

    func testAllSixtyCardsHaveEffectHandlers() {
        for i in 1...60 {
            let stringId = String(format: "card_%03d", i)
            XCTAssertNotNil(
                GameEffectHandler.forCard(stringId),
                "Missing handler for \(stringId)"
            )
        }
    }

    func testInvalidCardIdReturnsNil() {
        XCTAssertNil(GameEffectHandler.forCard("card_000"))
        XCTAssertNil(GameEffectHandler.forCard("card_061"))
        XCTAssertNil(GameEffectHandler.forCard("bogus"))
        XCTAssertNil(GameEffectHandler.forCard(""))
    }

    // MARK: - Champion Innate Map Coverage

    func testAllSixChampionsHaveInnateHandlers() {
        for i in 1...6 {
            let stringId = String(format: "champ_%03d", i)
            XCTAssertNotNil(
                GameEffectHandler.forChampionInnate(stringId),
                "Missing innate for \(stringId)"
            )
        }
    }

    func testInvalidChampionInnateReturnsNil() {
        XCTAssertNil(GameEffectHandler.forChampionInnate("champ_000"))
        XCTAssertNil(GameEffectHandler.forChampionInnate("champ_007"))
    }

    // MARK: - Champion Tier Map Coverage

    func testAllChampionsHaveTier1And2Handlers() {
        for i in 1...6 {
            let stringId = String(format: "champ_%03d", i)
            XCTAssertNotNil(
                GameEffectHandler.forChampionTier(stringId, tier: 1),
                "Missing T1 for \(stringId)"
            )
            XCTAssertNotNil(
                GameEffectHandler.forChampionTier(stringId, tier: 2),
                "Missing T2 for \(stringId)"
            )
        }
    }

    func testInvalidTierReturnsNil() {
        XCTAssertNil(GameEffectHandler.forChampionTier("champ_001", tier: 0))
        XCTAssertNil(GameEffectHandler.forChampionTier("champ_001", tier: 3))
    }

    // MARK: - Specific Effect Mappings

    func testWeaponEffectMappings() {
        XCTAssertEqual(GameEffectHandler.forCard("card_001"), .weaponAttackBonus3)
        XCTAssertEqual(GameEffectHandler.forCard("card_005"), .weaponAttackBonus8IgnoreMG)
    }

    func testChampionInnateMappings() {
        XCTAssertEqual(GameEffectHandler.forChampionInnate("champ_001"), .innateUnyielding)
        XCTAssertEqual(GameEffectHandler.forChampionInnate("champ_002"), .innateFirstBlood)
        XCTAssertEqual(GameEffectHandler.forChampionInnate("champ_003"), .innateArcaneSurge)
        XCTAssertEqual(GameEffectHandler.forChampionInnate("champ_004"), .innateHolyMending)
        XCTAssertEqual(GameEffectHandler.forChampionInnate("champ_005"), .innateBloodRage)
        XCTAssertEqual(GameEffectHandler.forChampionInnate("champ_006"), .innateVoidSiphon)
    }

    func testTierEffectMappings() {
        XCTAssertEqual(GameEffectHandler.forChampionTier("champ_001", tier: 1), .tier1BattleForged)
        XCTAssertEqual(GameEffectHandler.forChampionTier("champ_001", tier: 2), .tier2WarlordsResolve)
        XCTAssertEqual(GameEffectHandler.forChampionTier("champ_006", tier: 1), .tier1EntropyBlade)
        XCTAssertEqual(GameEffectHandler.forChampionTier("champ_006", tier: 2), .tier2Nullfield)
    }

    // MARK: - Attack Bonus Metadata

    func testWeaponAttackBonuses() {
        XCTAssertEqual(GameEffectHandler.weaponAttackBonus3.attackBonus, 3)
        XCTAssertEqual(GameEffectHandler.weaponAttackBonus4CritBonus.attackBonus, 4)
        XCTAssertEqual(GameEffectHandler.weaponAttackBonus4Poison.attackBonus, 4)
        XCTAssertEqual(GameEffectHandler.weaponAttackBonus5CritMGReduce.attackBonus, 5)
        XCTAssertEqual(GameEffectHandler.weaponAttackBonus8IgnoreMG.attackBonus, 8)
    }

    func testTierAttackBonuses() {
        XCTAssertEqual(GameEffectHandler.tier1BattleForged.attackBonus, 5)
        XCTAssertEqual(GameEffectHandler.tier1ShadowStep.attackBonus, 5)
        XCTAssertEqual(GameEffectHandler.tier1Overcharge.attackBonus, 5)
    }

    func testNonAttackEffectsHaveZeroBonus() {
        XCTAssertEqual(GameEffectHandler.headAvoidance1.attackBonus, 0)
        XCTAssertEqual(GameEffectHandler.chestMG2.attackBonus, 0)
        XCTAssertEqual(GameEffectHandler.talentToughness.attackBonus, 0)
    }

    // MARK: - Avoidance Bonus Metadata

    func testAvoidanceBonuses() {
        XCTAssertEqual(GameEffectHandler.headAvoidance1.avoidanceBonus, 1)
        XCTAssertEqual(GameEffectHandler.headAvoidance2MG1.avoidanceBonus, 2)
        XCTAssertEqual(GameEffectHandler.headAvoidance3MG2OnBreak.avoidanceBonus, 3)
        XCTAssertEqual(GameEffectHandler.feetAvoidance1.avoidanceBonus, 1)
        XCTAssertEqual(GameEffectHandler.feetAvoidance2Reroll.avoidanceBonus, 2)
        XCTAssertEqual(GameEffectHandler.feetAvoidance3SabotageDodge.avoidanceBonus, 3)
        XCTAssertEqual(GameEffectHandler.chestMG4AV1Heal2.avoidanceBonus, 1)
    }

    // MARK: - Mitigation Bonus Metadata

    func testMitigationBonuses() {
        XCTAssertEqual(GameEffectHandler.headAvoidance2MG1.mitigationBonus, 1)
        XCTAssertEqual(GameEffectHandler.headAvoidance3MG2OnBreak.mitigationBonus, 2)
        XCTAssertEqual(GameEffectHandler.chestMG2.mitigationBonus, 2)
        XCTAssertEqual(GameEffectHandler.chestMG3.mitigationBonus, 3)
        XCTAssertEqual(GameEffectHandler.chestMG3AbsorbBigHit.mitigationBonus, 3)
        XCTAssertEqual(GameEffectHandler.chestMG4AV1Heal2.mitigationBonus, 4)
    }

    // MARK: - Resource Per Turn Metadata

    func testResourcePerTurn() {
        XCTAssertEqual(GameEffectHandler.handsResource1.resourcePerTurn, 1)
        XCTAssertEqual(GameEffectHandler.handsResource2.resourcePerTurn, 2)
        XCTAssertEqual(GameEffectHandler.handsResource2CritBonus3.resourcePerTurn, 2)
        XCTAssertEqual(GameEffectHandler.handsResource3CarryOver.resourcePerTurn, 3)
        XCTAssertEqual(GameEffectHandler.weaponAttackBonus3.resourcePerTurn, 0)
    }

    // MARK: - Special Properties

    func testIgnoresMitigation() {
        XCTAssertTrue(GameEffectHandler.weaponAttackBonus8IgnoreMG.ignoresMitigation)
        XCTAssertTrue(GameEffectHandler.tier2ChainLightning.ignoresMitigation)
        XCTAssertFalse(GameEffectHandler.weaponAttackBonus3.ignoresMitigation)
        XCTAssertFalse(GameEffectHandler.chestMG2.ignoresMitigation)
    }

    func testGrantsAdvantage() {
        XCTAssertTrue(GameEffectHandler.tier2WarlordsResolve.grantsAdvantage)
        XCTAssertTrue(GameEffectHandler.tier2Unstoppable.grantsAdvantage)
        XCTAssertFalse(GameEffectHandler.tier1BattleForged.grantsAdvantage)
        XCTAssertFalse(GameEffectHandler.weaponAttackBonus3.grantsAdvantage)
    }

    // MARK: - CaseIterable

    func testTotalCaseCount() {
        // 5 weapons + 4 heads + 4 chests + 4 hands + 4 feet + 12 talents + 19 abilities + 8 adventures
        // + 6 innates + 6 tier1 + 6 tier2 = 78
        XCTAssertEqual(GameEffectHandler.allCases.count, 78)
    }

    // MARK: - Codable

    func testGameEffectHandlerCodable() throws {
        let handler = GameEffectHandler.weaponAttackBonus3
        let data = try JSONEncoder().encode(handler)
        let decoded = try JSONDecoder().decode(GameEffectHandler.self, from: data)
        XCTAssertEqual(decoded, handler)
    }
}
