import XCTest
@testable import ArenaRaiders

final class GameSimulationTests: XCTestCase {

    // MARK: - Card Factory

    /// Build a CardReference from minimal info matching real starter data.
    private func card(
        _ stringId: String,
        name: String,
        type: CardType,
        subtype: CardSubtype? = nil,
        slot: GearSlot? = nil,
        cost: Int = 1,
        durability: Int? = nil,
        rarity: Rarity = .common,
        isTwoHanded: Bool = false
    ) -> CardReference {
        CardReference(card: Card(
            stringId: stringId, name: name, cardType: type, subtype: subtype,
            gearSlot: type == .gear ? slot : nil, resourceCost: cost,
            durability: durability, effectDescription: "",
            rarity: rarity, isTwoHanded: isTwoHanded
        ))
    }

    // MARK: - Starter Deck Builders

    /// Iron & Blood deck (champ_001 / Vex the Ironclad) — 40 cards, 2x each
    private func ironBloodDeck() -> [CardReference] {
        let templates: [CardReference] = [
            card("card_001", name: "Iron Shortsword",  type: .gear, slot: .weapon,  cost: 2, durability: 4),
            card("card_006", name: "Leather Cap",      type: .gear, slot: .head,    cost: 1, durability: 3),
            card("card_010", name: "Hide Vest",        type: .gear, slot: .chest,   cost: 2, durability: 3),
            card("card_014", name: "Worn Gloves",      type: .gear, slot: .hands,   cost: 1, durability: 3),
            card("card_018", name: "Dusty Boots",      type: .gear, slot: .feet,    cost: 1, durability: 3),
            card("card_022", name: "Toughness",        type: .talent, cost: 2),
            card("card_023", name: "Quick Hands",      type: .talent, cost: 1),
            card("card_024", name: "Lucky Strike",     type: .talent, cost: 2),
            card("card_025", name: "Scavenger",        type: .talent, cost: 1),
            card("card_034", name: "Power Strike",     type: .ability, cost: 3),
            card("card_035", name: "Quick Patch",      type: .ability, cost: 1),
            card("card_036", name: "Bandage",          type: .ability, cost: 2),
            card("card_037", name: "Focused Aim",      type: .ability, cost: 2),
            card("card_038", name: "Feint",            type: .ability, subtype: .sabotage, cost: 1),
            card("card_039", name: "Backstab",         type: .ability, subtype: .sabotage, cost: 2),
            card("card_040", name: "Duel",             type: .ability, cost: 3),
            card("card_041", name: "Shield Wall",      type: .ability, cost: 2),
            card("card_053", name: "Loot Run",         type: .adventure, cost: 1),
            card("card_054", name: "Scout Ahead",      type: .adventure, cost: 2),
            card("card_044", name: "Battle Cry",       type: .ability, cost: 3),
        ]
        // 2 copies each = 40 cards
        return templates.flatMap { t in
            (0..<2).map { _ in
                // Each copy needs a unique UUID, so rebuild from Card
                card(t.stringId, name: t.name, type: t.cardType, subtype: t.subtype,
                     slot: t.gearSlot, cost: t.resourceCost, durability: t.durability,
                     rarity: t.rarity, isTwoHanded: t.isTwoHanded)
            }
        }
    }

    /// Cut and Run deck (champ_002 / Lyra Swiftblade) — 40 cards, 2x each
    private func cutAndRunDeck() -> [CardReference] {
        let templates: [CardReference] = [
            card("card_003", name: "Serpent Fang Dagger", type: .gear, slot: .weapon, cost: 4, durability: 3, rarity: .rare),
            card("card_006", name: "Leather Cap",        type: .gear, slot: .head,   cost: 1, durability: 3),
            card("card_012", name: "Chainmail Hauberk",  type: .gear, slot: .chest,  cost: 4, durability: 4, rarity: .rare),
            card("card_015", name: "Merchant's Grips",   type: .gear, slot: .hands,  cost: 2, durability: 3),
            card("card_020", name: "Boots of Haste",     type: .gear, slot: .feet,   cost: 4, durability: 3, rarity: .rare),
            card("card_024", name: "Lucky Strike",       type: .talent, cost: 2),
            card("card_026", name: "Resourceful",        type: .talent, cost: 2),
            card("card_029", name: "Ambush Tactics",     type: .talent, cost: 3, rarity: .rare),
            card("card_030", name: "Evasive Footwork",   type: .talent, cost: 2),
            card("card_037", name: "Focused Aim",        type: .ability, cost: 2),
            card("card_038", name: "Feint",              type: .ability, subtype: .sabotage, cost: 1),
            card("card_039", name: "Backstab",           type: .ability, subtype: .sabotage, cost: 2),
            card("card_042", name: "Poison Flask",       type: .ability, subtype: .sabotage, cost: 3),
            card("card_043", name: "Smoke Bomb",         type: .ability, subtype: .sabotage, cost: 2),
            card("card_045", name: "Second Wind",        type: .ability, cost: 4, rarity: .rare),
            card("card_047", name: "Execution Strike",   type: .ability, cost: 5, rarity: .epic),
            card("card_049", name: "Perfect Dodge",      type: .ability, cost: 3, rarity: .epic),
            card("card_053", name: "Loot Run",           type: .adventure, cost: 1),
            card("card_055", name: "Treasure Map",       type: .adventure, cost: 2),
            card("card_058", name: "Wandering Merchant", type: .adventure, cost: 3, rarity: .rare),
        ]
        return templates.flatMap { t in
            (0..<2).map { _ in
                card(t.stringId, name: t.name, type: t.cardType, subtype: t.subtype,
                     slot: t.gearSlot, cost: t.resourceCost, durability: t.durability,
                     rarity: t.rarity, isTwoHanded: t.isTwoHanded)
            }
        }
    }

    // MARK: - Champion Builders

    private func vexChampion() -> Champion {
        Champion(
            stringId: "champ_001", name: "Vex the Ironclad", archetype: .warrior,
            hp: 30, avoidance: 12, mitigation: 3,
            innatePassive: InnatePassive(name: "Unyielding", effectDescription: "Reduce all damage by 1"),
            tierEffects: [
                TierEffect(tier: 1, name: "Battle Forged", effectDescription: "+5 Attack on Hit"),
                TierEffect(tier: 2, name: "Warlord's Resolve", effectDescription: "Roll 2 D20s pick highest")
            ]
        )
    }

    private func lyraChampion() -> Champion {
        Champion(
            stringId: "champ_002", name: "Lyra Swiftblade", archetype: .rogue,
            hp: 24, avoidance: 16, mitigation: 1,
            innatePassive: InnatePassive(name: "First Blood", effectDescription: "First Hit deals double damage"),
            tierEffects: [
                TierEffect(tier: 1, name: "Shadow Step", effectDescription: "+5 Attack, first attack unblockable"),
                TierEffect(tier: 2, name: "Death Mark", effectDescription: "Roll 15+ applies Bleed")
            ]
        )
    }

    // MARK: - Simulation State

    private struct SimState {
        var playerSession: GameSession
        var aiState: AIState
        var chests: [TreasureChest]
        var currentChestIndex: Int
        var turn: Int
        var log: [String]
        var redFlags: [String]

        var currentChest: TreasureChest? {
            guard currentChestIndex < chests.count else { return nil }
            return chests[currentChestIndex]
        }

        mutating func print(_ msg: String) {
            log.append(msg)
        }
    }

    // MARK: - Seeded RNG Dice Provider

    /// Linear congruential generator for reproducible rolls.
    private class SeededDiceProvider: DiceProvider {
        private var state: UInt64

        init(seed: UInt64) {
            self.state = seed
        }

        func rollD20() -> Int {
            // LCG: state = state * 6364136223846793005 + 1442695040888963407
            state = state &* 6364136223846793005 &+ 1442695040888963407
            let value = Int((state >> 33) % 20) + 1
            return value
        }
    }

    // MARK: - Simulation Core

    private func runSimulation(seed: UInt64) -> SimState {
        let dice = SeededDiceProvider(seed: seed)
        let engine = GameEngine(dice: dice)
        let ai = AIOpponent(engine: engine)

        // Build player session (Vex) with Iron & Blood deck
        var playerSession = GameSession(phase: .raid, champion: vexChampion())
        playerSession.playerDeck = ironBloodDeck().shuffled()
        playerSession.playerResources = GameSession.startingResources

        // Draw opening hand
        engine.drawCards(
            count: GameSession.defaultHandSize,
            deck: &playerSession.playerDeck,
            hand: &playerSession.playerHand
        )

        // Build AI state (Lyra) with Cut and Run deck
        let lyraRef = ChampionReference(champion: lyraChampion())
        var aiDeck = cutAndRunDeck().shuffled()
        var aiHand: [CardReference] = []
        for _ in 0..<min(GameSession.defaultHandSize, aiDeck.count) {
            aiHand.append(aiDeck.removeFirst())
        }

        var aiState = AIState(
            champion: lyraRef,
            hand: aiHand,
            deck: aiDeck,
            resources: GameSession.startingResources,
            hp: lyraRef.hp,
            activeGear: ActiveGearMap(),
            activeTalents: []
        )

        // Chest sequence: Battered (30 HP), Ironbound (45 HP)
        let chests = [
            TreasureChest(integrity: 30, tier: 1),
            TreasureChest(integrity: 45, tier: 2)
        ]

        var state = SimState(
            playerSession: playerSession,
            aiState: aiState,
            chests: chests,
            currentChestIndex: 0,
            turn: 0,
            log: [],
            redFlags: []
        )

        state.print("========== GAME SIMULATION (Seed: \(seed)) ==========")
        state.print("Player: Vex the Ironclad (HP: 30, AV: 12, MG: 3)")
        state.print("AI:     Lyra Swiftblade  (HP: 24, AV: 16, MG: 1)")
        state.print("Chests: Battered (30 HP), Ironbound (45 HP)")
        state.print("")

        let maxTurns = 50

        // --- RAID PHASE ---
        while state.playerSession.phase == .raid && state.turn < maxTurns {
            guard let chest = state.currentChest, !chest.isDestroyed else {
                // Advance to next chest or arena
                if state.currentChestIndex + 1 < state.chests.count {
                    state.currentChestIndex += 1
                    state.playerSession.chestCount += 1
                    state.playerSession.currentChestTier = state.chests[state.currentChestIndex].tier
                    state.print("  >>> Advancing to chest \(state.currentChestIndex + 1)")
                } else {
                    state.playerSession.chestCount += 1
                    state.playerSession.phase = .arena
                    state.print("  >>> ALL CHESTS DESTROYED — ENTERING ARENA PHASE")
                }
                continue
            }

            state.turn += 1
            state.print("--- Turn \(state.turn) [RAID] | Chest \(state.currentChestIndex + 1) HP: \(chest.integrity) ---")

            // Player roll
            let roll = engine.rollD20()
            let outcome = engine.resolveChestRoll(roll: roll, chest: chest, session: state.playerSession)
            state.playerSession.playerResources += outcome.resources
            let passiveIncome = engine.computePassiveResourceIncome(session: state.playerSession)
            state.playerSession.playerResources += passiveIncome

            let rollType: String
            if outcome.result.isCrit { rollType = "CRIT" }
            else if outcome.result.isHit { rollType = "HIT" }
            else { rollType = "MISS" }

            state.print("  Roll: \(roll) → \(rollType) | Damage: \(outcome.damage) | Chest HP: \(chest.integrity)")
            state.print("  Resources: +\(outcome.resources) (roll) +\(passiveIncome) (passive) = \(state.playerSession.playerResources) total")

            // Player plays cards (simple AI-like: highest cost gear first, then others)
            var cardsPlayed: [String] = []
            var keepPlaying = true
            while keepPlaying {
                let playable = state.playerSession.playerHand.filter {
                    $0.resourceCost <= state.playerSession.playerResources
                }
                guard !playable.isEmpty else { break }

                // Prioritize gear for empty slots, then highest cost
                let gearForEmpty = playable.filter { c in
                    guard c.cardType == .gear, let slot = c.gearSlot else { return false }
                    return state.playerSession.activeGear.card(in: slot) == nil
                }

                let toPlay: CardReference
                if let gear = gearForEmpty.max(by: { $0.resourceCost < $1.resourceCost }) {
                    toPlay = gear
                } else if let best = playable.filter({ $0.cardType != .gear || $0.gearSlot == nil })
                    .max(by: { $0.resourceCost < $1.resourceCost }) {
                    toPlay = best
                } else {
                    break
                }

                let resBefore = state.playerSession.playerResources
                engine.playCard(card: toPlay, session: &state.playerSession)
                let spent = resBefore - state.playerSession.playerResources
                if spent > 0 {
                    cardsPlayed.append("\(toPlay.name) (\(toPlay.cardType.rawValue), cost \(spent))")
                } else {
                    break // playCard didn't go through
                }
            }

            if !cardsPlayed.isEmpty {
                state.print("  Player played: \(cardsPlayed.joined(separator: ", "))")
            }
            state.print("  Player: HP \(state.playerSession.playerHP)/\(state.playerSession.playerMaxHP), Resources \(state.playerSession.playerResources), Hand \(state.playerSession.playerHand.count), Deck \(state.playerSession.playerDeck.count)")

            // Durability tick: lose 1 durability on weapon per roll (if hit/crit)
            if outcome.result.isHit || outcome.result.isCrit {
                if state.playerSession.activeGear.card(in: .weapon) != nil {
                    let durBefore = state.playerSession.activeGear.card(in: .weapon)?.durability
                    engine.applyGearDurabilityLoss(slot: .weapon, amount: 1, session: &state.playerSession)
                    let durAfter = state.playerSession.activeGear.card(in: .weapon)?.durability
                    if durBefore != durAfter {
                        if durAfter == nil {
                            state.print("  Durability: Weapon BROKE!")
                        } else {
                            state.print("  Durability: Weapon \(durBefore ?? 0) → \(durAfter ?? 0)")
                        }
                    }
                }
            }

            // Check chest destroyed
            if chest.isDestroyed {
                let tierToAward = state.currentChestIndex + 1
                state.print("  >>> CHEST \(state.currentChestIndex + 1) DESTROYED! (Tier \(tierToAward) effect unlocked)")
            }

            // End player turn
            engine.endTurn(session: &state.playerSession)

            // Red flag checks
            checkRedFlags(state: &state)
        }

        // --- ARENA PHASE ---
        if state.playerSession.phase == .arena {
            state.print("")
            state.print("===== ARENA PHASE =====")
            state.print("Vex HP: \(state.playerSession.playerHP) | Lyra HP: \(state.aiState.hp)")
            state.print("")

            while state.playerSession.playerHP > 0 && state.aiState.hp > 0 && state.turn < maxTurns {
                state.turn += 1
                state.print("--- Turn \(state.turn) [ARENA] ---")

                // --- Player attacks AI ---
                let playerRoll = engine.rollD20()
                let playerResult = engine.classifyRoll(playerRoll, session: state.playerSession)
                let playerAtkMods = engine.computeAttackModifiers(session: state.playerSession)
                let aiAV = state.aiState.champion.avoidance
                let aiMG = state.aiState.champion.mitigation

                let playerAttack: AttackOutcome
                if playerResult.isCrit {
                    let critTotal = (playerRoll + playerAtkMods) * 2
                    playerAttack = engine.resolveAttack(
                        attackerRoll: critTotal, attackerModifiers: 0,
                        defenderAC: aiAV, defenderMG: aiMG
                    )
                } else {
                    playerAttack = engine.resolveAttack(
                        attackerRoll: playerRoll, attackerModifiers: playerAtkMods,
                        defenderAC: aiAV, defenderMG: aiMG
                    )
                }

                if playerAttack.didHit {
                    state.aiState.hp -= playerAttack.finalDamage
                }

                let pRollType = playerResult.isCrit ? "CRIT" : (playerResult.isHit ? "HIT" : "MISS")
                state.print("  Vex attacks: roll \(playerRoll) \(pRollType) | raw \(playerAttack.rawDamage) - \(playerAttack.mitigated) MG = \(playerAttack.finalDamage) dmg → Lyra HP: \(state.aiState.hp)")

                if state.aiState.hp <= 0 { break }

                // Player plays cards
                var playerPlayed: [String] = []
                for _ in 0..<3 { // up to 3 card plays per arena turn
                    let playable = state.playerSession.playerHand.filter {
                        $0.resourceCost <= state.playerSession.playerResources
                    }
                    let gearForEmpty = playable.filter { c in
                        guard c.cardType == .gear, let slot = c.gearSlot else { return false }
                        return state.playerSession.activeGear.card(in: slot) == nil
                    }
                    let toPlay: CardReference?
                    if let gear = gearForEmpty.max(by: { $0.resourceCost < $1.resourceCost }) {
                        toPlay = gear
                    } else if let best = playable.filter({ $0.cardType != .gear || $0.gearSlot == nil })
                        .max(by: { $0.resourceCost < $1.resourceCost }) {
                        toPlay = best
                    } else {
                        toPlay = nil
                    }
                    guard let cardToPlay = toPlay else { break }
                    let resBefore = state.playerSession.playerResources
                    engine.playCard(card: cardToPlay, session: &state.playerSession)
                    let spent = resBefore - state.playerSession.playerResources
                    if spent > 0 {
                        playerPlayed.append("\(cardToPlay.name) (cost \(spent))")
                    } else { break }
                }
                if !playerPlayed.isEmpty {
                    state.print("  Vex played: \(playerPlayed.joined(separator: ", "))")
                }

                // --- AI attacks player ---
                let aiRoll = engine.rollD20()
                let aiAtkBonus: Int
                if let weapon = state.aiState.activeGear.card(in: .weapon),
                   let effect = GameEffectHandler.forCard(weapon.stringId) {
                    aiAtkBonus = effect.attackBonus
                } else {
                    aiAtkBonus = 0
                }
                let playerAV = state.playerSession.playerChampion?.avoidance ?? 12
                let playerAVMod = playerAV + engine.computeAvoidanceModifiers(session: state.playerSession)
                let playerMG = (state.playerSession.playerChampion?.mitigation ?? 3)
                    + engine.computeMitigationModifiers(session: state.playerSession)

                let aiAttack = engine.resolveAttack(
                    attackerRoll: aiRoll, attackerModifiers: aiAtkBonus,
                    defenderAC: playerAVMod, defenderMG: playerMG
                )

                if aiAttack.didHit {
                    state.playerSession.playerHP -= aiAttack.finalDamage
                }

                let aRollType = aiRoll == 20 ? "CRIT" : (aiAttack.didHit ? "HIT" : "MISS")
                state.print("  Lyra attacks: roll \(aiRoll) +\(aiAtkBonus) \(aRollType) | raw \(aiAttack.rawDamage) - \(aiAttack.mitigated) MG = \(aiAttack.finalDamage) dmg → Vex HP: \(state.playerSession.playerHP)")

                if state.playerSession.playerHP <= 0 { break }

                // AI plays cards
                let aiActions = ai.executeTurn(state: &state.aiState)
                let aiPlayed = aiActions.compactMap { action -> String? in
                    if case .playCard(let c) = action { return c.name }
                    return nil
                }
                if !aiPlayed.isEmpty {
                    state.print("  Lyra played: \(aiPlayed.joined(separator: ", "))")
                }

                // AI resources for next turn
                var aiPassive = 0
                for aiCard in state.aiState.activeGear.allEquippedCards {
                    if let eff = GameEffectHandler.forCard(aiCard.stringId) {
                        aiPassive += eff.resourcePerTurn
                    }
                }
                state.aiState.resources = GameSession.startingResources + aiPassive

                // End player turn
                engine.endTurn(session: &state.playerSession)

                state.print("  Status: Vex HP \(state.playerSession.playerHP) (hand \(state.playerSession.playerHand.count), deck \(state.playerSession.playerDeck.count)) | Lyra HP \(state.aiState.hp) (hand \(state.aiState.hand.count), deck \(state.aiState.deck.count))")

                checkRedFlags(state: &state)
            }
        }

        // --- GAME OVER ---
        state.print("")
        let winner: String
        if state.playerSession.playerHP <= 0 && state.aiState.hp <= 0 {
            winner = "DRAW"
        } else if state.aiState.hp <= 0 {
            winner = "Vex the Ironclad"
        } else if state.playerSession.playerHP <= 0 {
            winner = "Lyra Swiftblade"
        } else {
            winner = "NO WINNER (turn limit)"
            state.redFlags.append("Game reached \(state.turn)-turn limit without a winner")
        }

        state.print("========== GAME OVER ==========")
        state.print("Winner: \(winner)")
        state.print("Total turns: \(state.turn)")
        state.print("Vex final HP: \(state.playerSession.playerHP)")
        state.print("Lyra final HP: \(state.aiState.hp)")
        state.print("Vex deck remaining: \(state.playerSession.playerDeck.count) cards")
        state.print("Lyra deck remaining: \(state.aiState.deck.count) cards")

        // Turn count red flags
        if state.turn < 6 {
            state.redFlags.append("RED FLAG: Game lasted only \(state.turn) turns (< 6, too fast)")
        }
        if state.turn > 40 {
            state.redFlags.append("RED FLAG: Game lasted \(state.turn) turns (> 40, too slow)")
        }

        if state.redFlags.isEmpty {
            state.print("Red flags: NONE")
        } else {
            state.print("Red flags:")
            for flag in state.redFlags {
                state.print("  ⚠ \(flag)")
            }
        }
        state.print("================================\n")

        return state
    }

    private func checkRedFlags(state: inout SimState) {
        // Negative HP check
        if state.playerSession.playerHP < 0 {
            state.redFlags.append("Turn \(state.turn): Player HP negative (\(state.playerSession.playerHP))")
        }
        if state.aiState.hp < 0 {
            state.redFlags.append("Turn \(state.turn): AI HP negative (\(state.aiState.hp))")
        }
        // Negative resources check
        if state.playerSession.playerResources < 0 {
            state.redFlags.append("Turn \(state.turn): Player resources negative (\(state.playerSession.playerResources))")
        }
        if state.aiState.resources < 0 {
            state.redFlags.append("Turn \(state.turn): AI resources negative (\(state.aiState.resources))")
        }
        // Gear slot conflict: multiple items in same slot not possible with ActiveGearMap (replaces)
        // but verify count never exceeds 5
        if state.playerSession.activeGear.equippedCount > GearSlot.allCases.count {
            state.redFlags.append("Turn \(state.turn): Player gear count exceeds slot count (\(state.playerSession.activeGear.equippedCount))")
        }
    }

    // MARK: - Test: 3 Simulations

    func testThreeFullGameSimulations() {
        let seeds: [UInt64] = [42, 1337, 99999]
        var allRedFlags: [String] = []

        for seed in seeds {
            let result = runSimulation(seed: seed)

            // Print full log
            for line in result.log {
                Swift.print(line)
            }

            allRedFlags.append(contentsOf: result.redFlags)

            // Basic sanity: game ran
            XCTAssertGreaterThan(result.turn, 0, "Seed \(seed): Game should have played at least 1 turn")
        }

        if allRedFlags.isEmpty {
            Swift.print("\n✅ ALL 3 SIMULATIONS PASSED — NO RED FLAGS")
        } else {
            Swift.print("\n⚠ RED FLAGS FOUND:")
            for flag in allRedFlags {
                Swift.print("  - \(flag)")
            }
            // Red flags are warnings, not hard failures for balance issues
            // But crashes/negatives are real failures
            let criticalFlags = allRedFlags.filter {
                $0.contains("negative") || $0.contains("crash") || $0.contains("conflict")
            }
            if !criticalFlags.isEmpty {
                XCTFail("Critical red flags: \(criticalFlags.joined(separator: "; "))")
            }
        }
    }
}
