import Foundation

// MARK: - AI Decision

enum AIAction: Equatable {
    case playCard(CardReference)
    case endTurn
}

// MARK: - AI Opponent State

struct AIState {
    var champion: ChampionReference
    var hand: [CardReference]
    var deck: [CardReference]
    var resources: Int
    var hp: Int
    var activeGear: ActiveGearMap
    var activeTalents: [CardReference]

    var maxHP: Int { champion.hp }

    var hpPercentage: Double {
        guard maxHP > 0 else { return 0 }
        return Double(hp) / Double(maxHP)
    }

    var isLowHP: Bool {
        hpPercentage < 0.5
    }
}

// MARK: - AI Opponent (Simple Decision Tree)

final class AIOpponent {
    private let engine: GameEngine

    init(engine: GameEngine) {
        self.engine = engine
    }

    /// Returns the next action the AI should take.
    func decideAction(state: AIState) -> AIAction {
        let playableCards = state.hand.filter { $0.resourceCost <= state.resources }
        guard !playableCards.isEmpty else { return .endTurn }

        // Priority 1: Equip weapon if slot is empty
        if state.activeGear.card(in: .weapon) == nil {
            let weapons = playableCards.filter { $0.cardType == .gear && $0.gearSlot == .weapon }
            if let bestWeapon = weapons.max(by: { $0.resourceCost < $1.resourceCost }) {
                return .playCard(bestWeapon)
            }
        }

        // Priority 2: Use abilities if HP below 50%
        if state.isLowHP {
            let abilities = playableCards.filter { $0.cardType == .ability }
            if let bestAbility = abilities.max(by: { $0.resourceCost < $1.resourceCost }) {
                return .playCard(bestAbility)
            }
        }

        // Priority 3: Play the highest-cost card we can afford
        if let highestCost = playableCards.max(by: { $0.resourceCost < $1.resourceCost }) {
            return .playCard(highestCost)
        }

        return .endTurn
    }

    /// Executes a full AI turn, returning all actions taken.
    func executeTurn(state: inout AIState) -> [AIAction] {
        var actions: [AIAction] = []

        // Draw a card
        engine.drawCard(deck: &state.deck, hand: &state.hand)

        // Keep playing cards until we can't or choose to stop
        while true {
            let action = decideAction(state: state)
            actions.append(action)

            switch action {
            case .playCard(let card):
                guard state.resources >= card.resourceCost else { break }
                guard let index = state.hand.firstIndex(where: { $0.id == card.id }) else { break }

                state.resources -= card.resourceCost
                state.hand.remove(at: index)

                switch card.cardType {
                case .gear:
                    if let slot = card.gearSlot {
                        state.activeGear.equipRef(card, in: slot)
                    }
                case .talent:
                    state.activeTalents.append(card)
                case .ability, .adventure:
                    break
                }
                continue

            case .endTurn:
                state.resources = 0
                return actions
            }
            break
        }

        return actions
    }
}
