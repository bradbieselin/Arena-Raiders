import XCTest
@testable import ArenaRaiders

final class ActiveGearMapTests: XCTestCase {

    // MARK: - Helpers

    private func makeCardRef(
        stringId: String = "card_test",
        name: String = "Test Gear",
        gearSlot: GearSlot = .weapon,
        durability: Int = 3
    ) -> CardReference {
        CardReference(card: Card(
            stringId: stringId,
            name: name,
            cardType: .gear,
            gearSlot: gearSlot,
            resourceCost: 2,
            durability: durability,
            effectDescription: "Test effect",
            rarity: .common
        ))
    }

    // MARK: - Empty State

    func testEmptyGearMap() {
        let map = ActiveGearMap()
        XCTAssertTrue(map.isEmpty)
        XCTAssertEqual(map.equippedCount, 0)
        XCTAssertTrue(map.equippedSlots.isEmpty)
        XCTAssertTrue(map.allEquippedCards.isEmpty)
        XCTAssertNil(map.card(in: .weapon))
        XCTAssertNil(map.card(in: .head))
        XCTAssertNil(map.card(in: .chest))
        XCTAssertNil(map.card(in: .hands))
        XCTAssertNil(map.card(in: .feet))
    }

    // MARK: - Equip / Unequip

    func testEquipAndRetrieveCard() {
        var map = ActiveGearMap()
        let sword = makeCardRef(stringId: "card_001", name: "Iron Sword", gearSlot: .weapon)

        map.equipRef(sword, in: .weapon)

        XCTAssertFalse(map.isEmpty)
        XCTAssertEqual(map.equippedCount, 1)
        XCTAssertNotNil(map.card(in: .weapon))
        XCTAssertEqual(map.card(in: .weapon)?.stringId, "card_001")
        XCTAssertEqual(map.card(in: .weapon)?.name, "Iron Sword")
    }

    func testEquipMultipleSlots() {
        var map = ActiveGearMap()
        let weapon = makeCardRef(stringId: "w", gearSlot: .weapon)
        let head = makeCardRef(stringId: "h", name: "Helm", gearSlot: .head)
        let chest = makeCardRef(stringId: "c", name: "Vest", gearSlot: .chest)
        let hands = makeCardRef(stringId: "g", name: "Gloves", gearSlot: .hands)
        let feet = makeCardRef(stringId: "f", name: "Boots", gearSlot: .feet)

        map.equipRef(weapon, in: .weapon)
        map.equipRef(head, in: .head)
        map.equipRef(chest, in: .chest)
        map.equipRef(hands, in: .hands)
        map.equipRef(feet, in: .feet)

        XCTAssertEqual(map.equippedCount, 5)
        XCTAssertNotNil(map.card(in: .weapon))
        XCTAssertNotNil(map.card(in: .head))
        XCTAssertNotNil(map.card(in: .chest))
        XCTAssertNotNil(map.card(in: .hands))
        XCTAssertNotNil(map.card(in: .feet))
    }

    func testEquipReplacesSameSlot() {
        var map = ActiveGearMap()
        let sword1 = makeCardRef(stringId: "sword1", name: "Iron Sword")
        let sword2 = makeCardRef(stringId: "sword2", name: "Steel Sword")

        map.equipRef(sword1, in: .weapon)
        XCTAssertEqual(map.card(in: .weapon)?.name, "Iron Sword")

        map.equipRef(sword2, in: .weapon)
        XCTAssertEqual(map.card(in: .weapon)?.name, "Steel Sword")
        XCTAssertEqual(map.equippedCount, 1, "Replacing should not increase count")
    }

    func testUnequipSlot() {
        var map = ActiveGearMap()
        let weapon = makeCardRef(stringId: "w")
        map.equipRef(weapon, in: .weapon)
        XCTAssertEqual(map.equippedCount, 1)

        map.unequip(.weapon)
        XCTAssertNil(map.card(in: .weapon))
        XCTAssertTrue(map.isEmpty)
        XCTAssertEqual(map.equippedCount, 0)
    }

    func testUnequipEmptySlotIsNoOp() {
        var map = ActiveGearMap()
        map.unequip(.weapon) // should not crash
        XCTAssertTrue(map.isEmpty)
    }

    // MARK: - Equipped Slots / All Equipped Cards

    func testEquippedSlotsReturnsCorrectSlots() {
        var map = ActiveGearMap()
        map.equipRef(makeCardRef(gearSlot: .weapon), in: .weapon)
        map.equipRef(makeCardRef(gearSlot: .head), in: .head)

        let slots = Set(map.equippedSlots)
        XCTAssertEqual(slots.count, 2)
        XCTAssertTrue(slots.contains(.weapon))
        XCTAssertTrue(slots.contains(.head))
    }

    func testAllEquippedCardsReturnsCards() {
        var map = ActiveGearMap()
        map.equipRef(makeCardRef(stringId: "a", gearSlot: .weapon), in: .weapon)
        map.equipRef(makeCardRef(stringId: "b", gearSlot: .chest), in: .chest)

        let cards = map.allEquippedCards
        XCTAssertEqual(cards.count, 2)
        let ids = Set(cards.map { $0.stringId })
        XCTAssertTrue(ids.contains("a"))
        XCTAssertTrue(ids.contains("b"))
    }

    // MARK: - Equip via Card (@Model)

    func testEquipViaCardModel() {
        var map = ActiveGearMap()
        let card = Card(
            stringId: "card_006",
            name: "Leather Cap",
            cardType: .gear,
            gearSlot: .head,
            resourceCost: 1,
            durability: 3,
            effectDescription: "+1 AV"
        )

        map.equip(card, in: .head)

        let equipped = map.card(in: .head)
        XCTAssertNotNil(equipped)
        XCTAssertEqual(equipped?.stringId, "card_006")
        XCTAssertEqual(equipped?.name, "Leather Cap")
    }

    // MARK: - Codable

    func testActiveGearMapIsCodable() throws {
        var map = ActiveGearMap()
        map.equipRef(makeCardRef(stringId: "w", gearSlot: .weapon), in: .weapon)
        map.equipRef(makeCardRef(stringId: "h", gearSlot: .head), in: .head)

        let data = try JSONEncoder().encode(map)
        let decoded = try JSONDecoder().decode(ActiveGearMap.self, from: data)

        XCTAssertEqual(decoded.equippedCount, 2)
        XCTAssertEqual(decoded.card(in: .weapon)?.stringId, "w")
        XCTAssertEqual(decoded.card(in: .head)?.stringId, "h")
    }

    func testEmptyGearMapCodable() throws {
        let map = ActiveGearMap()
        let data = try JSONEncoder().encode(map)
        let decoded = try JSONDecoder().decode(ActiveGearMap.self, from: data)
        XCTAssertTrue(decoded.isEmpty)
    }
}
