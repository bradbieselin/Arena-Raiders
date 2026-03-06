import XCTest
@testable import ArenaRaiders

final class DurabilityTests: XCTestCase {

    // MARK: - Helpers

    private func makeGear(
        stringId: String = "card_001",
        name: String = "Test Weapon",
        gearSlot: GearSlot = .weapon,
        cost: Int = 2,
        durability: Int = 3,
        rarity: Rarity = .common
    ) -> CardReference {
        CardReference(card: Card(
            stringId: stringId,
            name: name,
            cardType: .gear,
            gearSlot: gearSlot,
            resourceCost: cost,
            durability: durability,
            effectDescription: "Test",
            rarity: rarity
        ))
    }

    private func makeAbility(
        stringId: String,
        name: String,
        cost: Int = 2,
        subtype: CardSubtype? = .sabotage
    ) -> CardReference {
        CardReference(card: Card(
            stringId: stringId,
            name: name,
            cardType: .ability,
            subtype: subtype,
            resourceCost: cost,
            effectDescription: "Test"
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
            innatePassive: InnatePassive(name: "Test Passive", effectDescription: "Test"),
            tierEffects: []
        )
        return GameSession(phase: .raid, champion: champion)
    }

    // MARK: - 1. Durability loss reduces by amount

    func testDurabilityLossReducesByAmount() {
        let engine = GameEngine()
        var card = makeGear(durability: 3)

        engine.applyDurabilityLoss(card: &card, amount: 1)

        XCTAssertEqual(card.durability, 2, "Durability 3 - 1 = 2, got \(card.durability ?? -1)")
        print("PASS: Gear at durability 3 loses 1 → durability = 2")
    }

    // MARK: - 2. Durability 0 discards gear from slot

    func testDurabilityZeroDiscardsGear() {
        let engine = GameEngine()
        var session = makeSession()

        let weapon = makeGear(stringId: "gear_sword", durability: 1)
        session.activeGear.equipRef(weapon, in: .weapon)
        XCTAssertNotNil(session.activeGear.card(in: .weapon))

        engine.applyGearDurabilityLoss(slot: .weapon, amount: 1, session: &session)

        XCTAssertNil(session.activeGear.card(in: .weapon),
                     "Weapon slot should be empty after durability hits 0")
        XCTAssertTrue(session.playerDiscard.contains(where: { $0.stringId == "gear_sword" }),
                      "Broken gear should be in discard pile")
        print("PASS: Gear at durability 1 → takes 1 loss → removed from slot, moved to discard")
    }

    // MARK: - 3. Nil durability does not crash

    func testNilDurabilityDoesNotCrash() {
        let engine = GameEngine()
        var talent = CardReference(card: Card(
            stringId: "card_talent",
            name: "Test Talent",
            cardType: .talent,
            resourceCost: 1,
            effectDescription: "Test"
        ))

        XCTAssertNil(talent.durability, "Talent should have nil durability")

        // Should be a no-op, not a crash
        engine.applyDurabilityLoss(card: &talent, amount: 1)

        XCTAssertNil(talent.durability, "Talent durability should remain nil")
        print("PASS: Talent with nil durability → applyDurabilityLoss is a safe no-op")
    }

    // MARK: - 4. Backstab (card_039) reduces weapon durability by 1

    func testBackstabReducesWeaponDurabilityBy1() {
        let engine = GameEngine()
        var session = makeSession()

        // Equip a weapon with durability 3
        let weapon = makeGear(stringId: "gear_sword", name: "Test Sword", durability: 3)
        session.activeGear.equipRef(weapon, in: .weapon)

        // Put Backstab in hand and give enough resources to play it
        let backstab = makeAbility(stringId: "card_039", name: "Backstab", cost: 2)
        session.playerHand = [backstab]
        session.playerResources = 10

        engine.playCard(card: backstab, session: &session)

        let weaponAfter = session.activeGear.card(in: .weapon)
        XCTAssertNotNil(weaponAfter, "Weapon should still be equipped (durability > 0)")
        XCTAssertEqual(weaponAfter?.durability, 2,
                       "Backstab should reduce weapon durability by 1: 3 → 2, got \(weaponAfter?.durability ?? -1)")
        print("PASS: Backstab (card_039) reduces weapon durability from 3 → 2")
    }

    // MARK: - 5. Gear Crush (card_046) reduces weapon durability by 2

    func testGearCrushReducesWeaponDurabilityBy2() {
        let engine = GameEngine()
        var session = makeSession()

        // Equip a weapon with durability 3
        let weapon = makeGear(stringId: "gear_sword", name: "Test Sword", durability: 3)
        session.activeGear.equipRef(weapon, in: .weapon)

        // Put Gear Crush in hand and give enough resources to play it
        let gearCrush = makeAbility(stringId: "card_046", name: "Gear Crush", cost: 3)
        session.playerHand = [gearCrush]
        session.playerResources = 10

        engine.playCard(card: gearCrush, session: &session)

        let weaponAfter = session.activeGear.card(in: .weapon)
        XCTAssertNotNil(weaponAfter, "Weapon should still be equipped (durability > 0)")
        XCTAssertEqual(weaponAfter?.durability, 1,
                       "Gear Crush should reduce weapon durability by 2: 3 → 1, got \(weaponAfter?.durability ?? -1)")
        print("PASS: Gear Crush (card_046) reduces weapon durability from 3 → 1")
    }

    // MARK: - 6. Broken gear removes stat bonus immediately

    func testBrokenGearRemovesStatBonus() {
        let engine = GameEngine()
        var session = makeSession()

        // Equip Worn Gloves (card_014) — gives +1 resource/turn
        let gloves = makeGear(
            stringId: "card_014",
            name: "Worn Gloves",
            gearSlot: .hands,
            cost: 1,
            durability: 1,
            rarity: .common
        )
        session.activeGear.equipRef(gloves, in: .hands)

        // Confirm passive income is +1 while gloves are equipped
        let incomeBefore = engine.computePassiveResourceIncome(session: session)
        XCTAssertEqual(incomeBefore, 1, "Worn Gloves should give +1 passive income")

        // Break the gloves (durability 1 → 0)
        engine.applyGearDurabilityLoss(slot: .hands, amount: 1, session: &session)

        // Slot should be empty and passive income should be 0
        XCTAssertNil(session.activeGear.card(in: .hands),
                     "Hands slot should be empty after gloves break")
        let incomeAfter = engine.computePassiveResourceIncome(session: session)
        XCTAssertEqual(incomeAfter, 0,
                       "Passive income should be 0 after gloves break, got \(incomeAfter)")
        print("PASS: Worn Gloves break → hands slot empty → passive income drops from 1 to 0")
    }
}
