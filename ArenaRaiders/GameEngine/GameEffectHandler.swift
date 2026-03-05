import Foundation

// MARK: - Game Effect Handler
// Maps every card and champion effect from the JSON data to a concrete enum case.
// The GameEngine dispatches on these to apply effects during gameplay.

enum GameEffectHandler: String, Codable, CaseIterable {

    // MARK: - Weapon Effects
    case weaponAttackBonus3          // Iron Shortsword: +3 Attack
    case weaponAttackBonus4CritBonus // Reinforced Crossbow: +4 Attack, +5 on Crit
    case weaponAttackBonus4Poison    // Serpent Fang Dagger: +4 Attack, Poison on hit
    case weaponAttackBonus5CritMGReduce // Stormcaller Staff: +5, Crit reduces MG by 2
    case weaponAttackBonus8IgnoreMG  // Voidbreaker Greatsword: +8, ignore MG, Crit discards

    // MARK: - Head Gear Effects
    case headAvoidance1              // Leather Cap: +1 AV
    case headAvoidance2MG1           // Steel Helm: +2 AV, +1 MG
    case headAvoidance2DrawExtra     // Crown of Clarity: +2 AV, draw 1 extra/turn
    case headAvoidance3MG2OnBreak    // Warlord's Warhelm: +3 AV, +2 MG, 5 dmg on break

    // MARK: - Chest Gear Effects
    case chestMG2                    // Hide Vest: +2 MG
    case chestMG3                    // Chainmail Hauberk: +3 MG
    case chestMG3AbsorbBigHit        // Dragonscale Coat: +3 MG, absorb 8+ hits
    case chestMG4AV1Heal2            // Aegis Plate: +4 MG, +1 AV, heal 2/turn

    // MARK: - Hands Gear Effects
    case handsResource1              // Worn Gloves: +1 Resource/turn
    case handsResource2              // Merchant's Grips: +2 Resources/turn
    case handsResource2CritBonus3    // Plunderer's Gauntlets: +2 Res, +3 on Crit
    case handsResource3CarryOver     // Goldweave Mitts: +3 Res, carry over 3 once

    // MARK: - Feet Gear Effects
    case feetAvoidance1              // Dusty Boots: +1 AV
    case feetAvoidance2Reroll        // Sprinter's Cleats: +2 AV, re-roll miss once
    case feetAvoidance3SabotageDodge // Shadowstep Boots: +3 AV, 50% sabotage dodge
    case feetAvoidance3FreeInstant   // Windrider Greaves: +3 AV, free instant/turn

    // MARK: - Talent Effects
    case talentToughness             // +3 Max HP
    case talentQuickHands            // +1 hand size
    case talentLuckyStrike           // 19 counts as Crit
    case talentScavenger             // Discard gives +2 instead of +1
    case talentIronWill              // Below 10 HP: +2 MG, +2 AV until end of turn
    case talentBattleRhythm          // 3 consecutive hits: +2 Resources
    case talentVengeance             // After damage: +1 Attack per 2 damage taken
    case talentTacticalEye           // Peek at top card once/turn
    case talentLifesteal             // Heal 25% of damage dealt (rounded up)
    case talentOverclock             // +1 Resource from every Raid roll
    case talentShatterproof          // All gear gets +1 max durability
    case talentApexPredator          // +1 Attack per equipped gear (max +5)

    // MARK: - Ability Effects
    case abilityPowerStrike          // 6 direct damage
    case abilityQuickPatch           // Restore 1 durability to gear
    case abilityBandage              // Heal 4 HP
    case abilityFocusedAim           // +5 to next attack roll
    case abilityFeint                // Instant: opponent disadvantage on attack
    case abilityBackstab             // Sabotage: opponent weapon -1 durability
    case abilityDuel                 // Both roll, winner +2 Res, loser loses attack
    case abilityShieldWall           // Instant: +4 MG for one attack
    case abilityPoisonFlask          // Sabotage: 3 HP/turn for 3 turns
    case abilitySmokeBomb            // Instant Sabotage: disadvantage all rolls this turn
    case abilityBattleCry            // +3 Resources, draw 1
    case abilitySecondWind           // Instant: Heal 8 HP (below 50% only)
    case abilityGearCrush            // Sabotage: target gear -2 durability
    case abilityExecutionStrike      // D20 + Attack + 10 (must hit 10+)
    case abilityFullRepair           // All gear to max durability
    case abilityPerfectDodge         // Instant: negate one attack (once/game)
    case abilityCursedBlade          // Sabotage: destroy opponent weapon
    case abilityTheKillingBlow       // Triple D20 + Attack, Crit resets
    case abilityChaosNova            // All opponent gear -1 dur, D20 direct damage

    // MARK: - Adventure Effects
    case adventureLootRun            // 3 turns: +1 Res/turn, draw 2 on complete
    case adventureScoutAhead         // 2 turns: rearrange top 4 cards
    case adventureBountyHunt         // 3 turns: 2x hits as Resources
    case adventureSupplyRun          // 3 turns: recover gear from discard
    case adventureFieldMedicine      // 2 turns: heal 10 HP
    case adventureTheLongCon         // 4 turns: Sabotage, discard from opponent hand
    case adventureAncientRuinDive    // 4 turns: add random Epic/Legendary to hand
    case adventureTheFinalRaid       // 5 turns: 20 damage + heal 5, uncancellable

    // MARK: - Champion Innate Passives
    case innateUnyielding            // Vex: reduce damage by 1 (stacks with MG)
    case innateFirstBlood            // Lyra: first hit deals double (once/game)
    case innateArcaneSurge           // Aldric: Crit on chest → +1 Resource
    case innateHolyMending           // Seraphine: heal 1 HP start of Raid turn
    case innateBloodRage             // Grizzak: +2 Attack per 5 HP below max
    case innateVoidSiphon            // Zara: gain 1 Resource when opponent plays card

    // MARK: - Champion Tier 1 Effects
    case tier1BattleForged           // Vex T1: +5 Attack, heal 2 on Hit
    case tier1ShadowStep             // Lyra T1: +5 Attack, first attack bypasses AV
    case tier1Overcharge             // Aldric T1: +5 Attack, Abilities cost -1
    case tier1DivineVerdict          // Seraphine T1: +5 Attack, Talent play heals 3
    case tier1Rampage                // Grizzak T1: +5 Attack, kill chest → extra turn
    case tier1EntropyBlade           // Zara T1: +5 Attack, Sabotage costs 0

    // MARK: - Champion Tier 2 Effects
    case tier2WarlordsResolve        // Vex T2: roll 2 D20s, pick highest
    case tier2DeathMark              // Lyra T2: 15+ applies Bleed (2 dmg/turn)
    case tier2ChainLightning         // Aldric T2: Crit → splash dmg (half roll, bypasses MG)
    case tier2AuraOfWrath            // Seraphine T2: opponent -2 HP start of Arena turn
    case tier2Unstoppable            // Grizzak T2: roll 2 D20s, immune to disadvantage
    case tier2Nullfield              // Zara T2: cancel 1 opponent instant/turn

    // MARK: - Lookup by card/champion string ID

    static func forCard(_ stringId: String) -> GameEffectHandler? {
        cardEffectMap[stringId]
    }

    static func forChampionInnate(_ stringId: String) -> GameEffectHandler? {
        championInnateMap[stringId]
    }

    static func forChampionTier(_ stringId: String, tier: Int) -> GameEffectHandler? {
        championTierMap["\(stringId)_t\(tier)"]
    }

    private static let cardEffectMap: [String: GameEffectHandler] = [
        "card_001": .weaponAttackBonus3,
        "card_002": .weaponAttackBonus4CritBonus,
        "card_003": .weaponAttackBonus4Poison,
        "card_004": .weaponAttackBonus5CritMGReduce,
        "card_005": .weaponAttackBonus8IgnoreMG,
        "card_006": .headAvoidance1,
        "card_007": .headAvoidance2MG1,
        "card_008": .headAvoidance2DrawExtra,
        "card_009": .headAvoidance3MG2OnBreak,
        "card_010": .chestMG2,
        "card_011": .chestMG3,
        "card_012": .chestMG3AbsorbBigHit,
        "card_013": .chestMG4AV1Heal2,
        "card_014": .handsResource1,
        "card_015": .handsResource2,
        "card_016": .handsResource2CritBonus3,
        "card_017": .handsResource3CarryOver,
        "card_018": .feetAvoidance1,
        "card_019": .feetAvoidance2Reroll,
        "card_020": .feetAvoidance3SabotageDodge,
        "card_021": .feetAvoidance3FreeInstant,
        "card_022": .talentToughness,
        "card_023": .talentQuickHands,
        "card_024": .talentLuckyStrike,
        "card_025": .talentScavenger,
        "card_026": .talentIronWill,
        "card_027": .talentBattleRhythm,
        "card_028": .talentVengeance,
        "card_029": .talentTacticalEye,
        "card_030": .talentLifesteal,
        "card_031": .talentOverclock,
        "card_032": .talentShatterproof,
        "card_033": .talentApexPredator,
        "card_034": .abilityPowerStrike,
        "card_035": .abilityQuickPatch,
        "card_036": .abilityBandage,
        "card_037": .abilityFocusedAim,
        "card_038": .abilityFeint,
        "card_039": .abilityBackstab,
        "card_040": .abilityDuel,
        "card_041": .abilityShieldWall,
        "card_042": .abilityPoisonFlask,
        "card_043": .abilitySmokeBomb,
        "card_044": .abilityBattleCry,
        "card_045": .abilitySecondWind,
        "card_046": .abilityGearCrush,
        "card_047": .abilityExecutionStrike,
        "card_048": .abilityFullRepair,
        "card_049": .abilityPerfectDodge,
        "card_050": .abilityCursedBlade,
        "card_051": .abilityTheKillingBlow,
        "card_052": .abilityChaosNova,
        "card_053": .adventureLootRun,
        "card_054": .adventureScoutAhead,
        "card_055": .adventureBountyHunt,
        "card_056": .adventureSupplyRun,
        "card_057": .adventureFieldMedicine,
        "card_058": .adventureTheLongCon,
        "card_059": .adventureAncientRuinDive,
        "card_060": .adventureTheFinalRaid,
    ]

    private static let championInnateMap: [String: GameEffectHandler] = [
        "champ_001": .innateUnyielding,
        "champ_002": .innateFirstBlood,
        "champ_003": .innateArcaneSurge,
        "champ_004": .innateHolyMending,
        "champ_005": .innateBloodRage,
        "champ_006": .innateVoidSiphon,
    ]

    private static let championTierMap: [String: GameEffectHandler] = [
        "champ_001_t1": .tier1BattleForged,
        "champ_001_t2": .tier2WarlordsResolve,
        "champ_002_t1": .tier1ShadowStep,
        "champ_002_t2": .tier2DeathMark,
        "champ_003_t1": .tier1Overcharge,
        "champ_003_t2": .tier2ChainLightning,
        "champ_004_t1": .tier1DivineVerdict,
        "champ_004_t2": .tier2AuraOfWrath,
        "champ_005_t1": .tier1Rampage,
        "champ_005_t2": .tier2Unstoppable,
        "champ_006_t1": .tier1EntropyBlade,
        "champ_006_t2": .tier2Nullfield,
    ]

    // MARK: - Effect Metadata

    /// The static attack bonus this effect grants (for gear weapons/tier effects)
    var attackBonus: Int {
        switch self {
        case .weaponAttackBonus3: return 3
        case .weaponAttackBonus4CritBonus, .weaponAttackBonus4Poison: return 4
        case .weaponAttackBonus5CritMGReduce: return 5
        case .weaponAttackBonus8IgnoreMG: return 8
        case .tier1BattleForged, .tier1ShadowStep, .tier1Overcharge,
             .tier1DivineVerdict, .tier1Rampage, .tier1EntropyBlade: return 5
        default: return 0
        }
    }

    /// The static avoidance bonus this effect grants
    var avoidanceBonus: Int {
        switch self {
        case .headAvoidance1, .feetAvoidance1: return 1
        case .headAvoidance2MG1, .headAvoidance2DrawExtra,
             .feetAvoidance2Reroll: return 2
        case .headAvoidance3MG2OnBreak, .feetAvoidance3SabotageDodge,
             .feetAvoidance3FreeInstant: return 3
        case .chestMG4AV1Heal2: return 1
        default: return 0
        }
    }

    /// The static mitigation bonus this effect grants
    var mitigationBonus: Int {
        switch self {
        case .headAvoidance2MG1: return 1
        case .headAvoidance3MG2OnBreak: return 2
        case .chestMG2: return 2
        case .chestMG3, .chestMG3AbsorbBigHit: return 3
        case .chestMG4AV1Heal2: return 4
        default: return 0
        }
    }

    /// Resource income per turn from this effect
    var resourcePerTurn: Int {
        switch self {
        case .handsResource1: return 1
        case .handsResource2, .handsResource2CritBonus3: return 2
        case .handsResource3CarryOver: return 3
        default: return 0
        }
    }

    /// Whether this effect ignores mitigation
    var ignoresMitigation: Bool {
        switch self {
        case .weaponAttackBonus8IgnoreMG, .tier2ChainLightning: return true
        default: return false
        }
    }

    /// Whether this effect grants advantage (roll 2 D20s, pick highest)
    var grantsAdvantage: Bool {
        switch self {
        case .tier2WarlordsResolve, .tier2Unstoppable: return true
        default: return false
        }
    }
}
