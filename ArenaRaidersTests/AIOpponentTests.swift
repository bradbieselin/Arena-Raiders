import XCTest
@testable import ArenaRaiders

final class AIOpponentTests: XCTestCase {

    // MARK: - Helpers

    private func makeCard(
        name: String = "Test Card",
        type: CardType = .gear,
        gearSlot: GearSlot? = .weapon,
        cost: Int = 2,
        durability: Int? = 3
    ) -> CardReference {
        CardReference(card: Card(
            name: name,
            cardType: type,
            gearSlot: type == .gear ? gearSlot : nil,
            resourceCost: cost,
            durability: durability,
            effectDescription: "Test effect",
            rarity: .common,
            isInstant: false
        ))
    }

    private func makeAIState(
        resources: Int = 5,
        hp: Int = 30,
        hand: [CardReference] = []
    ) -> AIState {
        let champion = ChampionReference(champion: Champion(
            name: "AI Champion",
            hp: 30,
            avoidance: 12,
            mitigation: 3,
            innatePassive: InnatePassive(description: "AI passive", effect: .thorns),
            tierEffects: []
        ))

        return AIState(
            champion: champion,
            hand: hand,
            deck: [],
            resources: resources,
            hp: hp,
            activeGear: ActiveGearMap(),
            activeTalents: []
        )
    }

    // MARK: - Decision Tests

    func testAIEndsTurnWhenNoPlayableCards() {
        let engine = GameEngine()
        let ai = AIOpponent(engine: engine)
        let state = makeAIState(resources: 1, hand: [
            makeCard(name: "Expensive", cost: 5)
        ])

        let action = ai.decideAction(state: state)
        XCTAssertEqual(action, .endTurn)
    }

    func testAIEndsTurnWithEmptyHand() {
        let engine = GameEngine()
        let ai = AIOpponent(engine: engine)
        let state = makeAIState(resources: 10, hand: [])

        let action = ai.decideAction(state: state)
        XCTAssertEqual(action, .endTurn)
    }

    func testAIPrioritizesWeaponWhenEmpty() {
        let engine = GameEngine()
        let ai = AIOpponent(engine: engine)

        let weapon = makeCard(name: "Sword", type: .gear, gearSlot: .weapon, cost: 2)
        let helmet = makeCard(name: "Helmet", type: .gear, gearSlot: .head, cost: 3)
        let ability = makeCard(name: "Fireball", type: .ability, gearSlot: nil, cost: 4)

        let state = makeAIState(resources: 10, hand: [helmet, ability, weapon])

        let action = ai.decideAction(state: state)
        XCTAssertEqual(action, .playCard(weapon))
    }

    func testAISkipsWeaponPriorityIfAlreadyEquipped() {
        let engine = GameEngine()
        let ai = AIOpponent(engine: engine)

        let existingWeapon = makeCard(name: "Old Sword", type: .gear, gearSlot: .weapon, cost: 1)
        let expensiveAbility = makeCard(name: "Meteor", type: .ability, gearSlot: nil, cost: 4)
        let cheapTalent = makeCard(name: "Focus", type: .talent, gearSlot: nil, cost: 1, durability: nil)

        var state = makeAIState(resources: 10, hand: [cheapTalent, expensiveAbility])
        state.activeGear.equipRef(existingWeapon, in: .weapon)

        let action = ai.decideAction(state: state)
        // Should play highest cost card since weapon is equipped and HP is full
        XCTAssertEqual(action, .playCard(expensiveAbility))
    }

    func testAIPrioritizesAbilitiesWhenLowHP() {
        let engine = GameEngine()
        let ai = AIOpponent(engine: engine)

        let weapon = makeCard(name: "Sword", type: .gear, gearSlot: .weapon, cost: 2)
        let heal = makeCard(name: "Heal", type: .ability, gearSlot: nil, cost: 3)
        let gear = makeCard(name: "Helm", type: .gear, gearSlot: .head, cost: 4)

        // Weapon already equipped, HP below 50%
        var state = makeAIState(resources: 10, hp: 10, hand: [weapon, heal, gear])
        state.activeGear.equipRef(weapon, in: .weapon)

        let action = ai.decideAction(state: state)
        XCTAssertEqual(action, .playCard(heal))
    }

    func testAIPlaysHighestCostCardByDefault() {
        let engine = GameEngine()
        let ai = AIOpponent(engine: engine)

        let cheap = makeCard(name: "Cheap Helm", type: .gear, gearSlot: .head, cost: 1)
        let mid = makeCard(name: "Mid Chest", type: .gear, gearSlot: .chest, cost: 3)
        let expensive = makeCard(name: "Fancy Boots", type: .gear, gearSlot: .feet, cost: 5)

        // Weapon already equipped, full HP
        var state = makeAIState(resources: 10, hand: [cheap, mid, expensive])
        state.activeGear.equipRef(makeCard(), in: .weapon)

        let action = ai.decideAction(state: state)
        XCTAssertEqual(action, .playCard(expensive))
    }

    // MARK: - Full Turn Execution Tests

    func testExecuteTurnPlaysMultipleCards() {
        let engine = GameEngine()
        let ai = AIOpponent(engine: engine)

        let weapon = makeCard(name: "Sword", type: .gear, gearSlot: .weapon, cost: 2)
        let helm = makeCard(name: "Helm", type: .gear, gearSlot: .head, cost: 2)

        var state = makeAIState(resources: 5, hand: [weapon, helm])

        let actions = ai.executeTurn(state: &state)

        // Should play weapon first (priority), then helm, then end turn
        let playActions = actions.filter {
            if case .playCard = $0 { return true }
            return false
        }
        XCTAssertEqual(playActions.count, 2)
        XCTAssertEqual(state.resources, 0)
        XCTAssertTrue(state.hand.isEmpty)
    }

    func testExecuteTurnDrawsACard() {
        let engine = GameEngine()
        let ai = AIOpponent(engine: engine)

        let deckCard = makeCard(name: "Deck Card", type: .talent, gearSlot: nil, cost: 99, durability: nil)

        var state = makeAIState(resources: 0, hand: [])
        state.deck = [deckCard]

        _ = ai.executeTurn(state: &state)

        // Drew a card but couldn't play it (cost 99), hand should have 1 card
        XCTAssertEqual(state.hand.count, 1)
        XCTAssertEqual(state.hand.first?.name, "Deck Card")
        XCTAssertTrue(state.deck.isEmpty)
    }
}
