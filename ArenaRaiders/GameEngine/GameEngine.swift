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

    init(dice: DiceProvider = RandomDiceProvider()) {
        self.dice = dice
    }

    // MARK: - Dice

    func rollD20() -> Int {
        dice.rollD20()
    }

    /// Rolls with advantage (2 D20s, pick highest)
    func rollWithAdvantage() -> Int {
        max(dice.rollD20(), dice.rollD20())
    }

    /// Rolls with disadvantage (2 D20s, pick lowest)
    func rollWithDisadvantage() -> Int {
        min(dice.rollD20(), dice.rollD20())
    }

    func classifyRoll(_ roll: Int, session: GameSession? = nil) -> RollResult {
        // Check for Lucky Strike talent (19 counts as Crit)
        let hasLuckyStrike = session?.activeTalents.contains { $0.stringId == "card_024" } ?? false

        switch roll {
        case 1...9: return .miss(roll: roll)
        case 10...18: return .hit(roll: roll)
        case 19: return hasLuckyStrike ? .crit : .hit(roll: roll)
        case 20: return .crit
        default: return .miss(roll: roll)
        }
    }

    // MARK: - Attack Modifier Calculation

    func computeAttackModifiers(session: GameSession) -> Int {
        var bonus = 0

        // Weapon attack bonus
        if let weapon = session.activeGear.card(in: .weapon),
           let effect = GameEffectHandler.forCard(weapon.stringId) {
            bonus += effect.attackBonus
        }

        // Tier effect attack bonuses
        if let champ = session.playerChampion {
            for te in champ.tierEffects {
                if let handler = GameEffectHandler.forChampionTier(champ.stringId, tier: te.tier) {
                    bonus += handler.attackBonus
                }
            }

            // Blood Rage: +2 Attack per 5 HP below max
            if GameEffectHandler.forChampionInnate(champ.stringId) == .innateBloodRage {
                let hpLost = session.playerMaxHP - session.playerHP
                bonus += (hpLost / 5) * 2
            }
        }

        // Apex Predator: +1 per equipped gear (max +5)
        if session.activeTalents.contains(where: { $0.stringId == "card_033" }) {
            bonus += min(5, session.activeGear.equippedCount)
        }

        return bonus
    }

    func computeAvoidanceModifiers(session: GameSession) -> Int {
        var bonus = 0
        for card in session.activeGear.allEquippedCards {
            if let effect = GameEffectHandler.forCard(card.stringId) {
                bonus += effect.avoidanceBonus
            }
        }
        return bonus
    }

    func computeMitigationModifiers(session: GameSession) -> Int {
        var bonus = 0
        for card in session.activeGear.allEquippedCards {
            if let effect = GameEffectHandler.forCard(card.stringId) {
                bonus += effect.mitigationBonus
            }
        }
        return bonus
    }

    // MARK: - Resource Calculation

    func computePassiveResourceIncome(session: GameSession) -> Int {
        var income = 0
        for card in session.activeGear.allEquippedCards {
            if let effect = GameEffectHandler.forCard(card.stringId) {
                income += effect.resourcePerTurn
            }
        }
        return income
    }

    // MARK: - Raid Phase

    func resolveChestRoll(roll: Int, chest: TreasureChest, session: GameSession? = nil) -> ChestRollOutcome {
        let result = classifyRoll(roll, session: session)
        var resources: Int

        switch result {
        case .miss:
            resources = 1
            // Overclock: +1 resource from every roll
            if session?.activeTalents.contains(where: { $0.stringId == "card_031" }) == true {
                resources += 1
            }
            return ChestRollOutcome(roll: roll, result: result, damage: 0, resources: resources)

        case .hit(let rollValue):
            let attackMods = session.map { computeAttackModifiers(session: $0) } ?? 0
            let totalDamage = rollValue + attackMods
            let damage = chest.takeDamage(totalDamage)
            resources = 3
            if session?.activeTalents.contains(where: { $0.stringId == "card_031" }) == true {
                resources += 1
            }
            return ChestRollOutcome(roll: roll, result: result, damage: damage, resources: resources)

        case .crit:
            let attackMods = session.map { computeAttackModifiers(session: $0) } ?? 0
            let totalDamage = (20 + attackMods) * 2
            let damage = chest.takeDamage(totalDamage)
            resources = 5
            if session?.activeTalents.contains(where: { $0.stringId == "card_031" }) == true {
                resources += 1
            }
            // Arcane Surge: +1 resource on Crit
            if let champ = session?.playerChampion,
               GameEffectHandler.forChampionInnate(champ.stringId) == .innateArcaneSurge {
                resources += 1
            }
            // Plunderer's Gauntlets: +3 bonus on Crit
            if let hands = session?.activeGear.card(in: .hands),
               GameEffectHandler.forCard(hands.stringId) == .handsResource2CritBonus3 {
                resources += 3
            }
            return ChestRollOutcome(roll: roll, result: result, damage: damage, resources: resources)
        }
    }

    func discardForResource(card: CardReference, session: inout GameSession) -> Int {
        if let index = session.playerHand.firstIndex(where: { $0.id == card.id }) {
            let discarded = session.playerHand.remove(at: index)
            session.playerDiscard.append(discarded)
        }
        // Scavenger talent: +2 instead of +1
        if session.activeTalents.contains(where: { $0.stringId == "card_025" }) {
            return 2
        }
        return 1
    }

    func playCard(card: CardReference, session: inout GameSession) {
        var effectiveCost = card.resourceCost

        // Overcharge (Aldric T1): Abilities cost 1 less
        if card.isAbility,
           let champ = session.playerChampion,
           GameEffectHandler.forChampionTier(champ.stringId, tier: 1) == .tier1Overcharge {
            effectiveCost = max(1, effectiveCost - 1)
        }

        // Entropy Blade (Zara T1): Sabotage costs 0
        if card.isSabotage,
           let champ = session.playerChampion,
           GameEffectHandler.forChampionTier(champ.stringId, tier: 1) == .tier1EntropyBlade {
            effectiveCost = 0
        }

        guard session.playerResources >= effectiveCost else { return }
        guard let handIndex = session.playerHand.firstIndex(where: { $0.id == card.id }) else { return }

        session.playerResources -= effectiveCost
        session.playerHand.remove(at: handIndex)

        switch card.cardType {
        case .gear:
            if let slot = card.gearSlot {
                // Check Shatterproof talent: +1 max durability
                var equipped = card
                if session.activeTalents.contains(where: { $0.stringId == "card_032" }),
                   let dur = equipped.durability {
                    equipped.durability = dur + 1
                }
                session.activeGear.equipRef(equipped, in: slot)
            }

        case .talent:
            session.activeTalents.append(card)
            // Apply immediate talent effects
            if let effect = GameEffectHandler.forCard(card.stringId) {
                applyTalentEffect(effect, session: &session)
            }
            // Divine Verdict (Seraphine T1): heal 3 on talent play
            if let champ = session.playerChampion,
               GameEffectHandler.forChampionTier(champ.stringId, tier: 1) == .tier1DivineVerdict {
                session.playerHP = min(session.playerMaxHP, session.playerHP + 3)
            }

        case .ability:
            applyAbilityEffect(card, session: &session)
            session.playerDiscard.append(card)

        case .adventure:
            session.activeAdventures.append(ActiveAdventure(card: card))
        }
    }

    private func applyTalentEffect(_ effect: GameEffectHandler, session: inout GameSession) {
        switch effect {
        case .talentToughness:
            session.playerMaxHP += 3
            session.playerHP += 3
        case .talentQuickHands:
            session.handSizeBonus += 1
        default:
            break // Passive effects are checked during gameplay
        }
    }

    private func applyAbilityEffect(_ card: CardReference, session: inout GameSession) {
        guard let effect = GameEffectHandler.forCard(card.stringId) else { return }

        switch effect {
        case .abilityPowerStrike:
            // 6 direct damage — applied to chest or opponent by caller
            break
        case .abilityBandage:
            session.playerHP = min(session.playerMaxHP, session.playerHP + 4)
        case .abilityBattleCry:
            session.playerResources += 3
            drawCard(deck: &session.playerDeck, hand: &session.playerHand,
                     handSize: session.effectiveHandSize)
        case .abilitySecondWind:
            if session.playerHP < session.playerMaxHP / 2 {
                session.playerHP = min(session.playerMaxHP, session.playerHP + 8)
            }
        case .abilityQuickPatch:
            // Restore 1 durability to a gear card — target chosen by caller
            break
        case .abilityFullRepair:
            for slot in session.activeGear.equippedSlots {
                if var gear = session.activeGear.card(in: slot) {
                    gear.durability = gear.maxDurability
                    session.activeGear.equipRef(gear, in: slot)
                }
            }
        case .abilityPoisonFlask:
            session.opponentStatusEffects.append(
                StatusEffect(type: .poison, turnsRemaining: 3, damagePerTurn: 3)
            )
        case .abilityPerfectDodge:
            session.perfectDodgeUsed = true
        default:
            break // Other abilities resolved by caller
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
        defenderMG: Int,
        ignoreMitigation: Bool = false
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
        let effectiveMG = ignoreMitigation ? 0 : defenderMG
        let mitigated = min(effectiveMG, rawDamage)
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
            // Warlord's Warhelm: deal 5 damage on break
            if GameEffectHandler.forCard(card.stringId) == .headAvoidance3MG2OnBreak {
                // Damage applied to opponent — tracked via return or callback
            }
            session.activeGear.unequip(slot)
            session.playerDiscard.append(card)
        } else {
            session.activeGear.equipRef(card, in: slot)
        }
    }

    func checkChampionDefeated(hp: Int) -> Bool {
        hp <= 0
    }

    // MARK: - Status Effects

    func processStatusEffects(effects: inout [StatusEffect]) -> Int {
        var totalDamage = 0
        for i in (0..<effects.count).reversed() {
            totalDamage += effects[i].damagePerTurn
            effects[i].turnsRemaining -= 1
            if effects[i].isExpired {
                effects.remove(at: i)
            }
        }
        return totalDamage
    }

    // MARK: - Adventures

    func tickAdventures(session: inout GameSession) {
        for i in (0..<session.activeAdventures.count).reversed() {
            session.activeAdventures[i].turnsRemaining -= 1

            // Per-turn adventure effects
            if let effect = GameEffectHandler.forCard(session.activeAdventures[i].card.stringId) {
                if effect == .adventureLootRun {
                    session.playerResources += 1
                }
            }

            if session.activeAdventures[i].isComplete {
                let adventure = session.activeAdventures.remove(at: i)
                resolveCompletedAdventure(adventure, session: &session)
            }
        }
    }

    private func resolveCompletedAdventure(_ adventure: ActiveAdventure, session: inout GameSession) {
        guard let effect = GameEffectHandler.forCard(adventure.card.stringId) else { return }

        switch effect {
        case .adventureLootRun:
            drawCards(count: 2, deck: &session.playerDeck, hand: &session.playerHand,
                      handSize: session.effectiveHandSize)
        case .adventureBountyHunt:
            session.playerResources += adventure.hitsDuringAdventure * 2
        case .adventureFieldMedicine:
            session.playerHP = min(session.playerMaxHP, session.playerHP + 10)
        case .adventureTheFinalRaid:
            // 20 damage to opponent + heal 5 — opponent damage tracked by caller
            session.playerHP = min(session.playerMaxHP, session.playerHP + 5)
        default:
            break // Other adventures resolved by caller (scoutAhead, supplyRun, etc.)
        }
    }

    // MARK: - General

    func drawCard(
        deck: inout [CardReference],
        hand: inout [CardReference],
        handSize: Int = GameSession.defaultHandSize
    ) {
        guard hand.count < handSize, !deck.isEmpty else { return }
        let drawn = deck.removeFirst()
        hand.append(drawn)
    }

    func drawCards(
        count: Int,
        deck: inout [CardReference],
        hand: inout [CardReference],
        handSize: Int = GameSession.defaultHandSize
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
        // Tick adventures
        tickAdventures(session: &session)

        // Process status effects on player
        let statusDamage = processStatusEffects(effects: &session.playerStatusEffects)
        session.playerHP -= statusDamage

        // Clear resources (unless Goldweave Mitts carry-over)
        if !session.goldweaveMittsUsed,
           session.activeGear.card(in: .hands).flatMap({ GameEffectHandler.forCard($0.stringId) }) == .handsResource3CarryOver,
           session.playerResources > 0 {
            let carryOver = min(3, session.playerResources)
            session.playerResources = carryOver
            session.goldweaveMittsUsed = true
        } else {
            session.playerResources = 0
        }

        session.currentTurn += 1

        // Draw a card for next turn
        drawCard(
            deck: &session.playerDeck,
            hand: &session.playerHand,
            handSize: session.effectiveHandSize
        )

        // Crown of Clarity: draw 1 extra
        if let head = session.activeGear.card(in: .head),
           GameEffectHandler.forCard(head.stringId) == .headAvoidance2DrawExtra {
            drawCard(deck: &session.playerDeck, hand: &session.playerHand,
                     handSize: session.effectiveHandSize + 1) // bonus draw ignores hand size
        }

        // Holy Mending: heal 1 at start of raid turn
        if session.phase == .raid,
           let champ = session.playerChampion,
           GameEffectHandler.forChampionInnate(champ.stringId) == .innateHolyMending {
            session.playerHP = min(session.playerMaxHP, session.playerHP + 1)
        }

        // Aegis Plate: heal 2 at start of arena turn
        if session.phase == .arena,
           let chest = session.activeGear.card(in: .chest),
           GameEffectHandler.forCard(chest.stringId) == .chestMG4AV1Heal2 {
            session.playerHP = min(session.playerMaxHP, session.playerHP + 2)
        }

        // Add passive resource income
        session.playerResources += computePassiveResourceIncome(session: session)
        session.playerResources += GameSession.startingResources
    }

    // MARK: - Session Setup

    func setupGame(session: inout GameSession) {
        shuffleDeck(&session.playerDeck)

        // Draw opening hand
        drawCards(
            count: GameSession.defaultHandSize,
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
            session.phase = .arena
            return
        }
        let nextTier = session.chestCount + 1
        session.currentChestTier = nextTier
        session.currentChestIntegrity = chestIntegrity(forTier: nextTier)
    }
}
