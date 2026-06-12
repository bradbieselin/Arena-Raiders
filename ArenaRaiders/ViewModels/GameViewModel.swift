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

    // Pause menu
    var isPaused: Bool = false

    // Game over
    var isGameOver: Bool = false
    var winnerName: String = ""
    private(set) var didPlayerWin: Bool = false
    private(set) var goldReward: Int = 0
    private(set) var didRecordResult: Bool = false

    // Arena turn state
    private(set) var hasAttackedThisTurn: Bool = false
    private(set) var damageDealtToOpponent: Int = 0

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
    var discardCount: Int { session.playerDiscard.count }
    var currentTurn: Int { session.currentTurn }
    var chestsBroken: Int { session.chestCount }
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

    var playerChampionId: String? { session.playerChampion?.stringId }
    var aiChampionId: String? { aiState?.champion.stringId }

    var opponentDisplayName: String {
        aiState?.champion.name ?? "Treasure Vault"
    }

    // MARK: - Raid Actions

    func rollForChest() {
        guard !isGameOver, let chest = chest, !chest.isDestroyed else { return }

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
            SoundManager.shared.play(.crit)
            HapticsManager.shared.trigger(.heavy)
        } else if outcome.result.isHit {
            rollLabel = "HIT"
            rollColor = .yellow
            SoundManager.shared.play(.hit)
            HapticsManager.shared.trigger(.medium)
        } else {
            rollLabel = "MISS"
            rollColor = .gray
            SoundManager.shared.play(.miss)
            HapticsManager.shared.trigger(.light)
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
            SoundManager.shared.play(.chestBreak)
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
            HapticsManager.shared.trigger(.selection)
        }
    }

    func playSelectedCard(_ card: CardReference) {
        guard !isGameOver else { return }
        guard card.resourceCost <= session.playerResources else { return }
        let handCountBefore = session.playerHand.count
        engine.playCard(card: card, session: &session)
        selectedCardID = nil
        if session.playerHand.count < handCountBefore {
            SoundManager.shared.play(.cardPlay)
            HapticsManager.shared.trigger(.light)
        }
    }

    func endTurn() {
        guard !isGameOver else { return }
        selectedCardID = nil

        // In the arena the opponent acts before the turn rolls over.
        if session.phase == .arena {
            aiTurn()
            guard !isGameOver else { return }
        }

        engine.endTurn(session: &session)
        hasAttackedThisTurn = false

        // Status effects ticked in endTurn can be lethal.
        if session.playerHP <= 0 {
            finishGame(playerWon: false)
        }
    }

    // MARK: - Arena Actions

    func attackOpponent() {
        guard session.phase == .arena, !isGameOver, !hasAttackedThisTurn,
              var ai = aiState else { return }
        hasAttackedThisTurn = true

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
            damageDealtToOpponent += attack.finalDamage
        }

        // Animate
        rollResult = roll
        if result.isCrit {
            rollLabel = "CRIT!"
            rollColor = .red
            SoundManager.shared.play(.crit)
            HapticsManager.shared.trigger(.heavy)
        } else if attack.didHit {
            rollLabel = "HIT"
            rollColor = .yellow
            SoundManager.shared.play(.hit)
            HapticsManager.shared.trigger(.medium)
        } else {
            rollLabel = "MISS"
            rollColor = .gray
            SoundManager.shared.play(.miss)
            HapticsManager.shared.trigger(.light)
        }
        showRoll = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            withAnimation { self?.showRoll = false }
        }

        self.aiState = ai

        // Check AI defeated
        if ai.hp <= 0 {
            finishGame(playerWon: true)
        }
    }

    // MARK: - Game End

    func concede() {
        finishGame(playerWon: false, conceded: true)
    }

    func buildMatchRecord() -> MatchRecord {
        MatchRecord(
            didWin: didPlayerWin,
            championName: championName,
            opponentName: opponentDisplayName,
            turnsPlayed: session.currentTurn,
            chestsBroken: session.chestCount,
            goldEarned: goldReward
        )
    }

    /// Marks the result as persisted so it is recorded exactly once.
    func markResultRecorded() {
        didRecordResult = true
    }

    private func finishGame(playerWon: Bool, conceded: Bool = false) {
        guard !isGameOver else { return }

        didPlayerWin = playerWon
        winnerName = playerWon ? championName : aiName
        session.endedAt = Date()
        session.didPlayerWin = playerWon

        if conceded {
            goldReward = 0
        } else if playerWon {
            goldReward = 25 + 5 * session.chestCount
        } else {
            goldReward = 5 + 2 * session.chestCount
        }

        SoundManager.shared.play(playerWon ? .victory : .defeat)
        HapticsManager.shared.trigger(playerWon ? .success : .error)

        withAnimation(.easeInOut(duration: 0.3)) {
            isGameOver = true
        }
    }

    // MARK: - Private

    private func spawnChest() {
        let tier = session.currentChestTier
        let integrity = engine.chestIntegrity(forTier: tier)
        chest = TreasureChest(integrity: integrity, tier: tier)
        chestMaxIntegrity = integrity
    }

    /// AI opponents the player can face in the arena, mirroring the starter
    /// roster. Their string ids match the catalog so portrait art resolves;
    /// the engine never evaluates champion effects for the scripted opponent.
    private static let opponentRoster: [(stringId: String, name: String, archetype: Archetype, hp: Int, avoidance: Int, mitigation: Int, passive: String)] = [
        ("champ_002", "Lyra Swiftblade", .rogue, 24, 16, 1, "First Blood"),
        ("champ_001", "Vex the Ironclad", .warrior, 30, 12, 3, "Unyielding"),
        ("champ_005", "Grizzak the Unbroken", .berserker, 35, 9, 0, "Blood Rage"),
        ("champ_006", "Zara the Voidwalker", .shadow, 25, 14, 1, "Void Siphon")
    ]

    private func setupArena() {
        // Pick a random arena opponent
        let pick = Self.opponentRoster.randomElement() ?? Self.opponentRoster[0]
        let opponent = Champion(
            stringId: pick.stringId, name: pick.name, archetype: pick.archetype,
            hp: pick.hp, avoidance: pick.avoidance, mitigation: pick.mitigation,
            innatePassive: InnatePassive(name: pick.passive, effectDescription: pick.passive),
            tierEffects: []
        )
        let opponentRef = ChampionReference(champion: opponent)

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
            champion: opponentRef, hand: hand, deck: aiDeck,
            resources: GameSession.startingResources,
            hp: opponentRef.hp, activeGear: ActiveGearMap(), activeTalents: []
        )
    }

    private func aiTurn() {
        guard var ai = aiState, !isGameOver else { return }

        // AI plays its cards first (equipping gear), then attacks
        _ = self.ai.executeTurn(state: &ai)

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

        ai.resources = GameSession.startingResources
        self.aiState = ai

        // Check player defeated
        if session.playerHP <= 0 {
            finishGame(playerWon: false)
        }
    }
}
