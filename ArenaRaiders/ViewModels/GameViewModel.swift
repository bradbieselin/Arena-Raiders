import Foundation
import SwiftUI
import Combine

@Observable
final class GameViewModel {
    // MARK: - Published State

    private(set) var session: GameSession
    private(set) var chest: TreasureChest?
    private(set) var chestMaxIntegrity: Int = 0

    // Roll animation state
    var rollResult: Int?
    var rollLabel: String = ""
    var rollColor: Color = .white
    var showRoll: Bool = false

    // Resource pulse
    var resourcePulse: Bool = false

    // Selection
    var selectedCardID: UUID?

    // Game over
    var isGameOver: Bool = false
    var winnerName: String = ""

    // AI state (for arena)
    private(set) var aiState: AIState?

    // MARK: - Private

    private let engine: GameEngine
    private let ai: AIOpponent

    // MARK: - Init

    init(session: GameSession, engine: GameEngine = GameEngine()) {
        self.session = session
        self.engine = engine
        self.ai = AIOpponent(engine: engine)

        engine.setupGame(session: &self.session)
        spawnChest()
    }

    // MARK: - Computed

    var phase: GamePhase { session.phase }
    var playerHP: Int { session.playerHP }
    var playerMaxHP: Int { session.playerMaxHP }
    var playerResources: Int { session.playerResources }
    var hand: [CardReference] { session.playerHand }
    var deckCount: Int { session.playerDeck.count }
    var activeGear: ActiveGearMap { session.activeGear }
    var chestHP: Int { chest?.integrity ?? 0 }
    var chestDestroyed: Bool { chest?.isDestroyed ?? true }

    var aiHP: Int { aiState?.hp ?? 0 }
    var aiMaxHP: Int { aiState?.champion.hp ?? 0 }
    var aiName: String { aiState?.champion.name ?? "Opponent" }
    var aiGear: ActiveGearMap { aiState?.activeGear ?? ActiveGearMap() }

    var championName: String {
        session.playerChampion?.name ?? "Champion"
    }

    // MARK: - Raid Actions

    func rollForChest() {
        guard let chest = chest, !chest.isDestroyed else { return }

        let roll = engine.rollD20()
        let outcome = engine.resolveChestRoll(roll: roll, chest: chest, session: session)
        let previousResources = session.playerResources
        session.playerResources += outcome.resources

        // Passive income from gear
        let passive = engine.computePassiveResourceIncome(session: session)
        session.playerResources += passive

        // Animate roll result
        rollResult = roll
        if outcome.result.isCrit {
            rollLabel = "CRIT!"
            rollColor = .red
        } else if outcome.result.isHit {
            rollLabel = "HIT"
            rollColor = .yellow
        } else {
            rollLabel = "MISS"
            rollColor = .gray
        }
        showRoll = true

        // Pulse resources if gained
        if session.playerResources > previousResources {
            resourcePulse = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.resourcePulse = false
            }
        }

        // Fade roll after 1.5s
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            withAnimation { self?.showRoll = false }
        }

        // Weapon durability on hit/crit
        if outcome.result.isHit || outcome.result.isCrit {
            if session.activeGear.card(in: .weapon) != nil {
                engine.applyGearDurabilityLoss(slot: .weapon, amount: 1, session: &session)
            }
        }

        // Check chest destroyed
        if chest.isDestroyed {
            engine.advanceChest(session: &session)
            if session.phase == .raid {
                spawnChest()
            } else {
                self.chest = nil
                setupArena()
            }
        }
    }

    func selectCard(_ card: CardReference) {
        if selectedCardID == card.id {
            // Second tap: play the card
            playSelectedCard(card)
        } else {
            selectedCardID = card.id
        }
    }

    func playSelectedCard(_ card: CardReference) {
        guard card.resourceCost <= session.playerResources else { return }
        engine.playCard(card: card, session: &session)
        selectedCardID = nil
    }

    func endTurn() {
        engine.endTurn(session: &session)
        selectedCardID = nil
    }

    // MARK: - Arena Actions

    func attackOpponent() {
        guard var ai = aiState, session.phase == .arena else { return }

        // Player attacks AI
        let roll = engine.rollD20()
        let result = engine.classifyRoll(roll, session: session)
        let atkMods = engine.computeAttackModifiers(session: session)
        let aiAV = ai.champion.avoidance
        let aiMG = ai.champion.mitigation

        let attack: AttackOutcome
        if result.isCrit {
            let critTotal = (roll + atkMods) * 2
            attack = engine.resolveAttack(
                attackerRoll: critTotal, attackerModifiers: 0,
                defenderAC: aiAV, defenderMG: aiMG
            )
        } else {
            attack = engine.resolveAttack(
                attackerRoll: roll, attackerModifiers: atkMods,
                defenderAC: aiAV, defenderMG: aiMG
            )
        }

        if attack.didHit {
            ai.hp -= attack.finalDamage
        }

        // Animate
        rollResult = roll
        if result.isCrit {
            rollLabel = "CRIT!"
            rollColor = .red
        } else if attack.didHit {
            rollLabel = "HIT"
            rollColor = .yellow
        } else {
            rollLabel = "MISS"
            rollColor = .gray
        }
        showRoll = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            withAnimation { self?.showRoll = false }
        }

        self.aiState = ai

        // Check AI defeated
        if ai.hp <= 0 {
            isGameOver = true
            winnerName = championName
            return
        }

        // AI counter-attacks after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.aiTurn()
        }
    }

    // MARK: - Private

    private func spawnChest() {
        let tier = session.currentChestTier
        let integrity = engine.chestIntegrity(forTier: tier)
        chest = TreasureChest(integrity: integrity, tier: tier)
        chestMaxIntegrity = integrity
    }

    private func setupArena() {
        // Create AI opponent with a basic deck
        let lyra = Champion(
            stringId: "champ_002", name: "Lyra Swiftblade", archetype: .rogue,
            hp: 24, avoidance: 16, mitigation: 1,
            innatePassive: InnatePassive(name: "First Blood", effectDescription: "First Hit deals double"),
            tierEffects: []
        )
        let lyraRef = ChampionReference(champion: lyra)

        // Simple AI deck
        var aiDeck: [CardReference] = []
        for i in 0..<20 {
            let c = Card(
                stringId: "ai_card_\(i)", name: "AI Card \(i)",
                cardType: i < 4 ? .gear : .ability,
                gearSlot: i < 2 ? .weapon : (i < 4 ? .chest : nil),
                resourceCost: (i % 3) + 1, durability: i < 4 ? 3 : nil,
                effectDescription: "AI"
            )
            aiDeck.append(CardReference(card: c))
        }

        var hand: [CardReference] = []
        for _ in 0..<min(5, aiDeck.count) {
            hand.append(aiDeck.removeFirst())
        }

        aiState = AIState(
            champion: lyraRef, hand: hand, deck: aiDeck,
            resources: GameSession.startingResources,
            hp: lyraRef.hp, activeGear: ActiveGearMap(), activeTalents: []
        )
    }

    private func aiTurn() {
        guard var ai = aiState else { return }

        // AI attacks player
        let aiRoll = engine.rollD20()
        var aiAtkBonus = 0
        if let weapon = ai.activeGear.card(in: .weapon),
           let effect = GameEffectHandler.forCard(weapon.stringId) {
            aiAtkBonus = effect.attackBonus
        }

        let playerAV = (session.playerChampion?.avoidance ?? 12)
            + engine.computeAvoidanceModifiers(session: session)
        let playerMG = (session.playerChampion?.mitigation ?? 3)
            + engine.computeMitigationModifiers(session: session)

        let aiAttack = engine.resolveAttack(
            attackerRoll: aiRoll, attackerModifiers: aiAtkBonus,
            defenderAC: playerAV, defenderMG: playerMG
        )

        if aiAttack.didHit {
            session.playerHP -= aiAttack.finalDamage
        }

        // AI plays cards
        _ = self.ai.executeTurn(state: &ai)
        ai.resources = GameSession.startingResources
        self.aiState = ai

        // End player turn
        engine.endTurn(session: &session)

        // Check player defeated
        if session.playerHP <= 0 {
            isGameOver = true
            winnerName = aiName
        }
    }
}
