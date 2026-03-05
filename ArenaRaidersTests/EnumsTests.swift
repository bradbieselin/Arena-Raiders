import XCTest
@testable import ArenaRaiders

final class EnumsTests: XCTestCase {

    // MARK: - Rarity

    func testRarityRawValues() {
        XCTAssertEqual(Rarity.common.rawValue, "Common")
        XCTAssertEqual(Rarity.rare.rawValue, "Rare")
        XCTAssertEqual(Rarity.epic.rawValue, "Epic")
        XCTAssertEqual(Rarity.legendary.rawValue, "Legendary")
    }

    func testRarityComparable() {
        XCTAssertTrue(Rarity.common < Rarity.rare)
        XCTAssertTrue(Rarity.rare < Rarity.epic)
        XCTAssertTrue(Rarity.epic < Rarity.legendary)
        XCTAssertFalse(Rarity.legendary < Rarity.common)
    }

    func testRarityCaseIterable() {
        XCTAssertEqual(Rarity.allCases.count, 4)
        XCTAssertEqual(Rarity.allCases, [.common, .rare, .epic, .legendary])
    }

    func testRarityDisplayName() {
        XCTAssertEqual(Rarity.common.displayName, "Common")
        XCTAssertEqual(Rarity.legendary.displayName, "Legendary")
    }

    func testRarityPullWeights() {
        XCTAssertEqual(Rarity.common.pullWeight, 0.60)
        XCTAssertEqual(Rarity.rare.pullWeight, 0.25)
        XCTAssertEqual(Rarity.epic.pullWeight, 0.12)
        XCTAssertEqual(Rarity.legendary.pullWeight, 0.03)
    }

    func testRarityPullWeightsSumToOne() {
        let total = Rarity.allCases.reduce(0.0) { $0 + $1.pullWeight }
        XCTAssertEqual(total, 1.0, accuracy: 0.001)
    }

    func testRarityCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for rarity in Rarity.allCases {
            let data = try encoder.encode(rarity)
            let decoded = try decoder.decode(Rarity.self, from: data)
            XCTAssertEqual(decoded, rarity)
        }
    }

    // MARK: - CardType

    func testCardTypeRawValues() {
        XCTAssertEqual(CardType.gear.rawValue, "Gear")
        XCTAssertEqual(CardType.talent.rawValue, "Talent")
        XCTAssertEqual(CardType.ability.rawValue, "Ability")
        XCTAssertEqual(CardType.adventure.rawValue, "Adventure")
    }

    func testCardTypeCaseIterable() {
        XCTAssertEqual(CardType.allCases.count, 4)
    }

    func testCardTypeCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for ct in CardType.allCases {
            let data = try encoder.encode(ct)
            let decoded = try decoder.decode(CardType.self, from: data)
            XCTAssertEqual(decoded, ct)
        }
    }

    // MARK: - CardSubtype

    func testCardSubtypeRawValue() {
        XCTAssertEqual(CardSubtype.sabotage.rawValue, "Sabotage")
    }

    // MARK: - GearSlot

    func testGearSlotRawValues() {
        XCTAssertEqual(GearSlot.head.rawValue, "Head")
        XCTAssertEqual(GearSlot.chest.rawValue, "Chest")
        XCTAssertEqual(GearSlot.hands.rawValue, "Hands")
        XCTAssertEqual(GearSlot.feet.rawValue, "Feet")
        XCTAssertEqual(GearSlot.weapon.rawValue, "Weapon")
    }

    func testGearSlotCaseIterable() {
        XCTAssertEqual(GearSlot.allCases.count, 5)
    }

    // MARK: - Archetype

    func testArchetypeRawValues() {
        XCTAssertEqual(Archetype.warrior.rawValue, "Warrior")
        XCTAssertEqual(Archetype.rogue.rawValue, "Rogue")
        XCTAssertEqual(Archetype.mage.rawValue, "Mage")
        XCTAssertEqual(Archetype.paladin.rawValue, "Paladin")
        XCTAssertEqual(Archetype.berserker.rawValue, "Berserker")
        XCTAssertEqual(Archetype.shadow.rawValue, "Shadow")
    }

    func testArchetypeCaseIterable() {
        XCTAssertEqual(Archetype.allCases.count, 6)
    }

    // MARK: - GamePhase

    func testGamePhaseRawValues() {
        XCTAssertEqual(GamePhase.raid.rawValue, "Raid")
        XCTAssertEqual(GamePhase.arena.rawValue, "Arena")
    }

    func testGamePhaseCaseIterable() {
        XCTAssertEqual(GamePhase.allCases.count, 2)
    }

    // MARK: - DeckRules

    func testDeckRulesConstants() {
        XCTAssertEqual(DeckRules.deckSize, 40)
        XCTAssertEqual(DeckRules.maxCopiesPerCard, 2)
        XCTAssertTrue(DeckRules.requiredChampion)
    }
}
