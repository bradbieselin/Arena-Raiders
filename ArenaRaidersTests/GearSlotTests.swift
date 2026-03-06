import XCTest
@testable import ArenaRaiders

final class GearSlotTests: XCTestCase {

    // MARK: - Helpers

    private func makeCard(
        stringId: String = "card_001",
        name: String = "Test Gear",
        gearSlot: GearSlot = .weapon,
        cost: Int = 2,
        durability: Int? = 3,
        rarity: Rarity = .common,
        isTwoHanded: Bool = false
    ) -> CardReference {
        CardReference(card: Card(
            stringId: stringId,
            name: name,
            cardType: .gear,
            gearSlot: gearSlot,
            resourceCost: cost,
            durability: durability,
            effectDescription: "Test",
            rarity: rarity,
            isTwoHanded: isTwoHanded
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

    // MARK: - 1. Equip one card in each slot

    func testEquipOneCardPerSlot() {
        var gear = ActiveGearMap()

        let head  = makeCard(stringId: "gear_head",  name: "Helmet",  gearSlot: .head)
        let chest = makeCard(stringId: "gear_chest", name: "Armor",   gearSlot: .chest)
        let hands = makeCard(stringId: "gear_hands", name: "Gloves",  gearSlot: .hands)
        let feet  = makeCard(stringId: "gear_feet",  name: "Boots",   gearSlot: .feet)
        let wpn   = makeCard(stringId: "gear_wpn",   name: "Sword",   gearSlot: .weapon)

        gear.equipRef(head,  in: .head)
        gear.equipRef(chest, in: .chest)
        gear.equipRef(hands, in: .hands)
        gear.equipRef(feet,  in: .feet)
        gear.equipRef(wpn,   in: .weapon)

        XCTAssertEqual(gear.equippedCount, 5, "Should have 5 items equipped")
        XCTAssertEqual(gear.card(in: .head)?.stringId,   "gear_head")
        XCTAssertEqual(gear.card(in: .chest)?.stringId,  "gear_chest")
        XCTAssertEqual(gear.card(in: .hands)?.stringId,  "gear_hands")
        XCTAssertEqual(gear.card(in: .feet)?.stringId,   "gear_feet")
        XCTAssertEqual(gear.card(in: .weapon)?.stringId, "gear_wpn")

        print("PASS: Champion can equip one card in each of 5 slots (Head, Chest, Hands, Feet, Weapon)")
    }

    // MARK: - 2. Equipping a second helmet replaces the first

    func testEquipSecondHelmetReplacesFirst() {
        var gear = ActiveGearMap()

        let helmet1 = makeCard(stringId: "helm_001", name: "Iron Helm",  gearSlot: .head)
        let helmet2 = makeCard(stringId: "helm_002", name: "Steel Helm", gearSlot: .head)

        gear.equipRef(helmet1, in: .head)
        XCTAssertEqual(gear.card(in: .head)?.stringId, "helm_001")

        gear.equipRef(helmet2, in: .head)
        XCTAssertEqual(gear.equippedCount, 1, "Should still be 1 item — replaced, not stacked")
        XCTAssertEqual(gear.card(in: .head)?.stringId, "helm_002",
                       "Second helmet should replace the first")

        // Behavior: ActiveGearMap.equipRef silently REPLACES existing gear in the same slot.
        // It does NOT reject the second equip — the old item is overwritten.
        print("PASS: Equipping a second helmet REPLACES the first (slot count stays 1)")
    }

    // MARK: - 3. Two-handed weapon property exists but no off-hand slot to block

    func testTwoHandedWeaponProperty() {
        // The game has 5 gear slots: Head, Chest, Hands, Feet, Weapon.
        // There is NO off-hand slot, so "blocks equipping off-hand" is N/A.
        // Confirm the isTwoHanded property is stored correctly.
        let greatsword = makeCard(
            stringId: "card_005",
            name: "Greatsword",
            gearSlot: .weapon,
            isTwoHanded: true
        )
        let dagger = makeCard(
            stringId: "card_dagger",
            name: "Dagger",
            gearSlot: .weapon,
            isTwoHanded: false
        )

        XCTAssertTrue(greatsword.isTwoHanded, "Greatsword should be two-handed")
        XCTAssertFalse(dagger.isTwoHanded, "Dagger should not be two-handed")

        // Confirm all GearSlot cases — no off-hand exists
        let allSlots = GearSlot.allCases
        XCTAssertEqual(allSlots.count, 5)
        XCTAssertFalse(allSlots.map(\.rawValue).contains("OffHand"),
                       "No off-hand slot exists — two-handed blocking is not applicable")

        print("PASS: isTwoHanded property stored correctly. No off-hand slot exists in current design (5 slots: \(allSlots.map(\.rawValue).joined(separator: ", ")))")
    }

    // MARK: - 4. Durability hitting 0 frees the slot

    func testDurabilityZeroFreesSlot() {
        let engine = GameEngine()
        var session = makeSession()

        let helmet = makeCard(stringId: "gear_helm", name: "Fragile Helm", gearSlot: .head, durability: 2)
        session.activeGear.equipRef(helmet, in: .head)

        XCTAssertNotNil(session.activeGear.card(in: .head), "Helmet should be equipped")

        // Apply 1 durability loss — should survive
        engine.applyGearDurabilityLoss(slot: .head, amount: 1, session: &session)
        XCTAssertNotNil(session.activeGear.card(in: .head), "Helmet should survive with 1 durability left")
        XCTAssertEqual(session.activeGear.card(in: .head)?.durability, 1)

        // Apply 1 more — durability hits 0, slot should be freed
        engine.applyGearDurabilityLoss(slot: .head, amount: 1, session: &session)
        XCTAssertNil(session.activeGear.card(in: .head), "Slot should be empty after durability hits 0")
        XCTAssertTrue(session.playerDiscard.contains(where: { $0.stringId == "gear_helm" }),
                      "Broken gear should be moved to discard pile")

        print("PASS: Gear with durability 0 is unequipped and moved to discard")
    }

    // MARK: - 5. No gear equipped = 0 passive resource income

    func testNoGearZeroPassiveIncome() {
        let engine = GameEngine()
        let session = makeSession()

        XCTAssertTrue(session.activeGear.isEmpty, "Fresh session should have no gear")
        let income = engine.computePassiveResourceIncome(session: session)
        XCTAssertEqual(income, 0, "No gear should mean 0 passive resource income, got \(income)")

        print("PASS: No gear equipped → 0 passive resource income")
    }

    // MARK: - 6. Worn Gloves (card_014) gives +1 resource income

    func testWornGlovesGivePlusOneIncome() {
        let engine = GameEngine()
        var session = makeSession()

        let gloves = makeCard(
            stringId: "card_014",
            name: "Worn Gloves",
            gearSlot: .hands,
            cost: 1,
            durability: 3,
            rarity: .common
        )
        session.activeGear.equipRef(gloves, in: .hands)

        let income = engine.computePassiveResourceIncome(session: session)
        XCTAssertEqual(income, 1, "Worn Gloves (card_014) should give +1 resource/turn, got \(income)")

        print("PASS: Worn Gloves (card_014) equipped → +1 passive resource income")
    }
}
