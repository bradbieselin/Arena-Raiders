import Foundation

// MARK: - Roll Result

enum RollResult: Equatable {
    case miss(roll: Int)
    case hit(roll: Int)
    case crit

    var isMiss: Bool {
        if case .miss = self { return true }
        return false
    }

    var isHit: Bool {
        if case .hit = self { return true }
        return false
    }

    var isCrit: Bool {
        self == .crit
    }
}

// MARK: - Chest Roll Outcome

struct ChestRollOutcome: Equatable {
    let roll: Int
    let result: RollResult
    let damage: Int
    let resources: Int
}

// MARK: - Attack Outcome

struct AttackOutcome: Equatable {
    let roll: Int
    let rawDamage: Int
    let mitigated: Int
    let finalDamage: Int
    let didHit: Bool
}

// MARK: - Dice Provider (injectable for testing)

protocol DiceProvider {
    func rollD20() -> Int
}

struct RandomDiceProvider: DiceProvider {
    func rollD20() -> Int {
        Int.random(in: 1...20)
    }
}

struct FixedDiceProvider: DiceProvider {
    let values: [Int]
    private let counter = Counter()

    private class Counter {
        var index = 0
    }

    func rollD20() -> Int {
        let value = values[counter.index % values.count]
        counter.index += 1
        return value
    }
}

// MARK: - Game Engine

final class GameEngine {
    private let dice: DiceProvider
    static let defaultHandSize = 5

    init(dice: DiceProvider = RandomDiceProvider()) {
        self.dice = dice
    }

    // MARK: - Dice

    func rollD20() -> Int {
        dice.rollD20()
    }

    func classifyRoll(_ roll: Int) -> RollResult {
        switch roll {
        case 1...9: return .miss(roll: roll)
        case 10...19: return .hit(roll: roll)
        case 20: return .crit
        default: return .miss(roll: roll)
        }
    }

    // MARK: - Raid Phase

    func resolveChestRoll(roll: Int, chest: TreasureChest) -> ChestRollOutcome {
        let result = classifyRoll(roll)

        switch result {
        case .miss:
            return ChestRollOutcome(roll: roll, result: result, damage: 0, resources: 1)

        case .hit(let rollValue):
            let damage = chest.takeDamage(rollValue)
            return ChestRollOutcome(roll: roll, result: result, damage: damage, resources: 3)

        case .crit:
            let doubleDamage = 20 * 2
            let damage = chest.takeDamage(doubleDamage)
            return ChestRollOutcome(roll: roll, result: result, damage: damage, resources: 5)
        }
    }

    func applyPassiveIncome(gear: [CardReference]) -> Int {
        gear.reduce(0) { total, card in
            guard card.cardType == .gear else { return total }
            // Each equipped gear provides 1 passive resource per turn
            total + 1
        }
    }

    func discardForResource(card: CardReference, session: inout GameSession) -> Int {
        if let index = session.playerHand.firstIndex(where: { $0.id == card.id }) {
            session.playerHand.remove(at: index)
        }
        return 1
    }

    func playCard(card: CardReference, session: inout GameSession) {
        guard session.playerResources >= card.resourceCost else { return }
        guard let handIndex = session.playerHand.firstIndex(where: { $0.id == card.id }) else { return }

        session.playerResources -= card.resourceCost
        session.playerHand.remove(at: handIndex)

        switch card.cardType {
        case .gear:
            if let slot = card.gearSlot {
                session.activeGear.equipRef(card, in: slot)
            }

        case .talent:
            session.activeTalents.append(card)

        case .ability:
            // Abilities have immediate effects and are consumed
            // Effect resolution is handled by the caller based on effectDescription
            break

        case .adventure:
            // Adventure cards modify the raid scenario
            // Effect resolution is handled by the caller based on effectDescription
            break
        }
    }

    func checkChestDefeated(chest: TreasureChest) -> Bool {
        chest.isDestroyed
    }

    func awardTierEffect(tier: Int, champion: inout ChampionReference) -> TierEffect? {
        guard tier >= 1, tier <= 2 else { return nil }
        return champion.tierEffects.first { $0.tier == tier }
    }

    // MARK: - Arena Phase

    func resolveAttack(
        attackerRoll: Int,
        attackerModifiers: Int,
        defenderAC: Int,
        defenderMG: Int
    ) -> AttackOutcome {
        let totalAttack = attackerRoll + attackerModifiers
        let didHit = totalAttack >= defenderAC

        guard didHit else {
            return AttackOutcome(
                roll: attackerRoll,
                rawDamage: 0,
                mitigated: 0,
                finalDamage: 0,
                didHit: false
            )
        }

        let rawDamage = totalAttack
        let mitigated = min(defenderMG, rawDamage)
        let finalDamage = max(0, rawDamage - mitigated)

        return AttackOutcome(
            roll: attackerRoll,
            rawDamage: rawDamage,
            mitigated: mitigated,
            finalDamage: finalDamage,
            didHit: true
        )
    }

    func applyDurabilityLoss(card: inout CardReference, amount: Int) {
        guard var durability = card.durability else { return }
        durability = max(0, durability - amount)
        card.durability = durability
    }

    func applyGearDurabilityLoss(slot: GearSlot, amount: Int, session: inout GameSession) {
        guard var card = session.activeGear.card(in: slot) else { return }
        applyDurabilityLoss(card: &card, amount: amount)
        if card.durability == 0 {
            session.activeGear.unequip(slot)
        } else {
            session.activeGear.equipRef(card, in: slot)
        }
    }

    func checkChampionDefeated(hp: Int) -> Bool {
        hp <= 0
    }

    // MARK: - General

    func drawCard(
        deck: inout [CardReference],
        hand: inout [CardReference],
        handSize: Int = defaultHandSize
    ) {
        guard hand.count < handSize, !deck.isEmpty else { return }
        let drawn = deck.removeFirst()
        hand.append(drawn)
    }

    func drawCards(
        count: Int,
        deck: inout [CardReference],
        hand: inout [CardReference],
        handSize: Int = defaultHandSize
    ) {
        for _ in 0..<count {
            guard hand.count < handSize, !deck.isEmpty else { break }
            let drawn = deck.removeFirst()
            hand.append(drawn)
        }
    }

    func shuffleDeck(_ deck: inout [CardReference]) {
        deck.shuffle()
    }

    func endTurn(session: inout GameSession) {
        session.playerResources = 0

        // Draw a card for next turn
        drawCard(
            deck: &session.playerDeck,
            hand: &session.playerHand
        )
    }

    // MARK: - Session Setup

    func setupGame(session: inout GameSession) {
        shuffleDeck(&session.playerDeck)

        // Draw opening hand
        drawCards(
            count: GameEngine.defaultHandSize,
            deck: &session.playerDeck,
            hand: &session.playerHand
        )

        // Set up first chest
        session.currentChestIntegrity = chestIntegrity(forTier: 1)
        session.currentChestTier = 1
    }

    func chestIntegrity(forTier tier: Int) -> Int {
        switch tier {
        case 1: return 20
        case 2: return 35
        case 3: return 50
        default: return 20
        }
    }

    func advanceChest(session: inout GameSession) {
        session.chestCount += 1
        guard session.chestCount < GameSession.maxChests else {
            // All chests defeated — transition to arena
            session.phase = .arena
            return
        }
        let nextTier = session.chestCount + 1
        session.currentChestTier = nextTier
        session.currentChestIntegrity = chestIntegrity(forTier: nextTier)
    }
}
