# Arena Raiders

A dice-driven card battler for iOS, built with SwiftUI and SwiftData. Raid the treasure vault, gear up your champion, then duel an AI opponent in the arena.

## Gameplay

Each match plays out in two acts, driven by D20 rolls:

1. **The Raid** — crack open three treasure chests of increasing toughness. Rolls of 1–9 miss (+1 resource), 10–18 hit (damage + 3 resources), and 19–20 can crit for double damage and 5 resources. Spend resources on cards: equip gear, learn talents, fire off abilities, and start multi-turn adventures.
2. **The Arena** — face a random AI champion in a duel to zero HP. You get one attack per turn; your roll plus attack bonuses must beat their Avoidance, and Mitigation soaks damage. End your turn and the opponent strikes back.

Winning earns gold (more for every chest you broke). Conceding earns nothing.

## Features

- **6 champions**, each with an archetype, innate passive, and tier effects
- **60-card starter set** across gear, talents, abilities, and adventures, with durability, sabotage, and carry-over mechanics handled by a dedicated effect engine
- **Deck builder** — 40-card decks, max 2 copies per card, one gear card per slot
- **Shop** — three card pack tiers with rarity-weighted pulls (60/25/12/3), guaranteed-rarity slots, a pack-opening reveal, and a daily gold bonus
- **Meta progression** — win streaks, match history, and stat-derived achievements
- **Production polish** — synthesized sound effects (no bundled assets), haptics, persisted settings, first-launch tutorial, pause/concede menu, victory & defeat screens with rewards, accessibility labels, custom app icon

## Architecture

```
ArenaRaiders/
├── Core/            GameSettings (persisted prefs), AudioHaptics, Achievements
├── Models/          SwiftData models (Card, Champion, Deck, PlayerProfile)
│                    + value-type game state (GameSession, CardReference)
├── GameEngine/      Pure game rules: dice, combat resolution, card effects,
│                    AI decision tree. Dice are injectable for deterministic tests.
├── ViewModels/      AppState (navigation), GameViewModel (match orchestration)
├── Data/            SwiftData container, starter-data seeding, save system,
│                    pack-opening economy
└── Views/           SwiftUI screens (landscape): Play, Collection, Deck Builder,
                     Shop, Profile, and the in-game board
```

Key design points:

- **Engine purity** — `GameEngine` has no UI or persistence dependencies and takes a `DiceProvider`, so every rule is unit-testable with fixed rolls.
- **Snapshot state** — matches operate on lightweight `CardReference` / `ChampionReference` snapshots rather than live SwiftData models.
- **Derived achievements** — computed from profile stats, so they need no extra storage and survive schema changes.
- **Result recording** — match results are persisted exactly once by the game-over screen, updating currency, streaks, and history atomically.

## Requirements

- Xcode 15+, iOS 17.0+
- No third-party dependencies

## Building & Testing

Open `ArenaRaiders.xcodeproj` in Xcode and run the `ArenaRaiders` scheme (landscape orientation), or from the command line:

```sh
xcodebuild -project ArenaRaiders.xcodeproj -scheme ArenaRaiders \
  -destination 'platform=iOS Simulator,name=iPhone 15' build

xcodebuild -project ArenaRaiders.xcodeproj -scheme ArenaRaiders \
  -destination 'platform=iOS Simulator,name=iPhone 15' test
```

The test suite covers the game engine (roll classification, combat, durability, economy, phase progression), the view model, data seeding, pack-opening odds (seeded RNG), achievements, and meta progression.

## Roadmap

- Online multiplayer (Game Center matchmaking)
- StoreKit integration for the existing Remove Ads placeholder
- Card art and richer board animations
- New card sets and champions
