import XCTest
@testable import ArenaRaiders

final class CardReferenceTests: XCTestCase {

    // MARK: - Helpers

    private func makeCard(
        stringId: String = "card_test",
        name: String = "Test Card",
        cardType: CardType = .gear,
        subtype: CardSubtype? = nil,
        gearSlot: GearSlot? = .weapon,
        resourceCost: Int = 2,
        durability: Int? = 3,
        isInstant: Bool = false,
        isTwoHanded: Bool = false,
        turnsToComplete: Int? = nil
    ) -> Card {
        Card(
            stringId: stringId,
            name: name,
            cardType: cardType,
            subtype: subtype,
            gearSlot: gearSlot,
            resourceCost: resourceCost,
            durability: durability,
            effectDescription: "Test effect",
            rarity: .common,
            isInstant: isInstant,
            isTwoHanded: isTwoHanded,
            turnsToComplete: turnsToComplete
        )
    }

    // MARK: - CardReference Creation

    func testCardReferenceSnapshotsAllFields() {
        let card = makeCard(
            stringId: "card_001",
            name: "Iron Shortsword",
            cardType: .gear,
            gearSlot: .weapon,
            resourceCost: 2,
            durability: 4,
            isTwoHanded: false
        )
        let ref = CardReference(card: card)

        XCTAssertEqual(ref.id, card.id)
        XCTAssertEqual(ref.stringId, "card_001")
        XCTAssertEqual(ref.name, "Iron Shortsword")
        XCTAssertEqual(ref.cardType, .gear)
        XCTAssertEqual(ref.gearSlot, .weapon)
        XCTAssertEqual(ref.resourceCost, 2)
        XCTAssertEqual(ref.durability, 4)
        XCTAssertEqual(ref.maxDurability, 4)
        XCTAssertFalse(ref.isTwoHanded)
        XCTAssertNil(ref.subtype)
        XCTAssertNil(ref.turnsToComplete)
    }

    func testCardReferenceMaxDurabilityMatchesInitial() {
        let card = makeCard(durability: 5)
        var ref = CardReference(card: card)
        XCTAssertEqual(ref.maxDurability, 5)
        XCTAssertEqual(ref.durability, 5)

        ref.durability = 2
        XCTAssertEqual(ref.durability, 2)
        XCTAssertEqual(ref.maxDurability, 5, "maxDurability should not change")
    }

    func testCardReferenceNilDurability() {
        let talent = makeCard(cardType: .talent, gearSlot: nil, durability: nil)
        let ref = CardReference(card: talent)
        XCTAssertNil(ref.durability)
        XCTAssertNil(ref.maxDurability)
    }

    // MARK: - Computed Properties

    func testCardReferenceTypeComputedProperties() {
        let gear = CardReference(card: makeCard(cardType: .gear))
        XCTAssertTrue(gear.isGear)
        XCTAssertFalse(gear.isTalent)
        XCTAssertFalse(gear.isAbility)
        XCTAssertFalse(gear.isAdventure)

        let talent = CardReference(card: makeCard(cardType: .talent, gearSlot: nil, durability: nil))
        XCTAssertTrue(talent.isTalent)
        XCTAssertFalse(talent.isGear)

        let ability = CardReference(card: makeCard(cardType: .ability, gearSlot: nil, durability: nil))
        XCTAssertTrue(ability.isAbility)

        let adventure = CardReference(card: makeCard(cardType: .adventure, gearSlot: nil, durability: nil, turnsToComplete: 3))
        XCTAssertTrue(adventure.isAdventure)
    }

    func testCardReferenceSabotageFlag() {
        let sabotage = CardReference(card: makeCard(
            cardType: .ability,
            subtype: .sabotage,
            gearSlot: nil,
            durability: nil
        ))
        XCTAssertTrue(sabotage.isSabotage)

        let normal = CardReference(card: makeCard(cardType: .ability, gearSlot: nil, durability: nil))
        XCTAssertFalse(normal.isSabotage)
    }

    // MARK: - Codable Round-Trip

    func testCardReferenceCodable() throws {
        let card = makeCard(
            stringId: "card_042",
            name: "Poison Flask",
            cardType: .ability,
            subtype: .sabotage,
            gearSlot: nil,
            resourceCost: 4,
            durability: nil,
            isInstant: false,
            turnsToComplete: nil
        )
        let ref = CardReference(card: card)

        let data = try JSONEncoder().encode(ref)
        let decoded = try JSONDecoder().decode(CardReference.self, from: data)

        XCTAssertEqual(decoded.id, ref.id)
        XCTAssertEqual(decoded.stringId, ref.stringId)
        XCTAssertEqual(decoded.name, ref.name)
        XCTAssertEqual(decoded.cardType, ref.cardType)
        XCTAssertEqual(decoded.subtype, ref.subtype)
        XCTAssertNil(decoded.gearSlot)
        XCTAssertEqual(decoded.resourceCost, ref.resourceCost)
        XCTAssertNil(decoded.durability)
        XCTAssertEqual(decoded.isInstant, ref.isInstant)
    }

    // MARK: - Equatable / Hashable

    func testCardReferenceEquality() {
        let card = makeCard(stringId: "same")
        let ref1 = CardReference(card: card)
        let ref2 = CardReference(card: card)
        XCTAssertEqual(ref1, ref2, "Same card should produce equal references")
    }

    func testCardReferenceHashable() {
        let card1 = makeCard(stringId: "a")
        let card2 = makeCard(stringId: "b")
        let ref1 = CardReference(card: card1)
        let ref2 = CardReference(card: card2)
        let set: Set<CardReference> = [ref1, ref2]
        XCTAssertEqual(set.count, 2)
    }

    // MARK: - ChampionReference

    func testChampionReferenceSnapshotsFields() {
        let champion = Champion(
            stringId: "champ_001",
            name: "Vex",
            archetype: .warrior,
            hp: 35,
            avoidance: 10,
            mitigation: 3,
            innatePassive: InnatePassive(name: "Unyielding", description: "Reduce damage by 1"),
            tierEffects: [
                TierEffect(tier: 1, name: "Battle-Forged", description: "+5 Attack"),
                TierEffect(tier: 2, name: "Warlord's Resolve", description: "Roll 2 D20s")
            ],
            rarity: .rare
        )
        let ref = ChampionReference(champion: champion)

        XCTAssertEqual(ref.id, champion.id)
        XCTAssertEqual(ref.stringId, "champ_001")
        XCTAssertEqual(ref.name, "Vex")
        XCTAssertEqual(ref.archetype, .warrior)
        XCTAssertEqual(ref.hp, 35)
        XCTAssertEqual(ref.avoidance, 10)
        XCTAssertEqual(ref.mitigation, 3)
        XCTAssertEqual(ref.innatePassive.name, "Unyielding")
        XCTAssertEqual(ref.tierEffects.count, 2)
        XCTAssertEqual(ref.rarity, .rare)
    }

    func testChampionReferenceCodable() throws {
        let champion = Champion(
            stringId: "champ_003",
            name: "Aldric",
            archetype: .mage,
            hp: 25,
            avoidance: 14,
            mitigation: 1,
            innatePassive: InnatePassive(name: "Arcane Surge", description: "Crit +1 res"),
            tierEffects: []
        )
        let ref = ChampionReference(champion: champion)

        let data = try JSONEncoder().encode(ref)
        let decoded = try JSONDecoder().decode(ChampionReference.self, from: data)

        XCTAssertEqual(decoded.stringId, "champ_003")
        XCTAssertEqual(decoded.name, "Aldric")
        XCTAssertEqual(decoded.archetype, .mage)
        XCTAssertEqual(decoded.hp, 25)
    }

    // MARK: - ActiveAdventure

    func testActiveAdventureInitialization() {
        let card = makeCard(
            stringId: "card_053",
            cardType: .adventure,
            gearSlot: nil,
            durability: nil,
            turnsToComplete: 3
        )
        let ref = CardReference(card: card)
        let adventure = ActiveAdventure(card: ref)

        XCTAssertEqual(adventure.turnsRemaining, 3)
        XCTAssertEqual(adventure.hitsDuringAdventure, 0)
        XCTAssertFalse(adventure.isComplete)
    }

    func testActiveAdventureCompletion() {
        let card = makeCard(
            stringId: "card_054",
            cardType: .adventure,
            gearSlot: nil,
            durability: nil,
            turnsToComplete: 1
        )
        let ref = CardReference(card: card)
        var adventure = ActiveAdventure(card: ref)
        XCTAssertEqual(adventure.turnsRemaining, 1)
        XCTAssertFalse(adventure.isComplete)

        adventure.turnsRemaining -= 1
        XCTAssertTrue(adventure.isComplete)
    }

    // MARK: - StatusEffect

    func testStatusEffectExpiration() {
        var effect = StatusEffect(type: .poison, turnsRemaining: 2, damagePerTurn: 3)
        XCTAssertFalse(effect.isExpired)

        effect.turnsRemaining = 0
        XCTAssertTrue(effect.isExpired)
    }

    func testStatusEffectTypes() {
        let poison = StatusEffect(type: .poison, turnsRemaining: 1, damagePerTurn: 3)
        let bleed = StatusEffect(type: .bleed, turnsRemaining: 1, damagePerTurn: 2)
        let mgReduce = StatusEffect(type: .mitigationReduction, turnsRemaining: 1, damagePerTurn: 0)
        let disadvantage = StatusEffect(type: .disadvantage, turnsRemaining: 1, damagePerTurn: 0)

        XCTAssertEqual(poison.type, .poison)
        XCTAssertEqual(bleed.type, .bleed)
        XCTAssertEqual(mgReduce.type, .mitigationReduction)
        XCTAssertEqual(disadvantage.type, .disadvantage)
    }
}
