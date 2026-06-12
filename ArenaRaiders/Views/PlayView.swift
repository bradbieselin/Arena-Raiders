import SwiftUI
import SwiftData

struct PlayView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [PlayerProfile]
    @Query private var allCards: [Card]
    @Query private var allChampions: [Champion]

    @State private var selectedDeckID: UUID?
    @State private var showHowToPlay = false

    private var profile: PlayerProfile? { profiles.first }

    private var decks: [Deck] {
        (profile?.savedDecks ?? []).sorted { $0.name < $1.name }
    }

    private var selectedDeck: Deck? {
        decks.first { $0.id == selectedDeckID } ?? decks.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ArtBackground(imageName: GameAssets.menuBackground, darken: 0.55)

                ScrollView {
                    VStack(spacing: 20) {
                        header
                        deckSection
                        startButtons
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Play")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        SoundManager.shared.play(.buttonTap)
                        showHowToPlay = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(GameTheme.gold)
                    }
                    .accessibilityLabel("How to play")
                }
            }
            .sheet(isPresented: $showHowToPlay, onDismiss: {
                GameSettings.shared.hasSeenTutorial = true
            }) {
                HowToPlayView()
            }
            .onAppear {
                if !GameSettings.shared.hasSeenTutorial {
                    showHowToPlay = true
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 44))
                .foregroundStyle(GameTheme.gold)

            Text("Ready for Battle, \(profile?.displayName ?? "Raider")?")
                .font(.title3.bold())
                .foregroundColor(.white)

            if let profile, profile.totalGames > 0 {
                Text("\(profile.totalWins)W – \(profile.totalLosses)L" +
                     (profile.currentWinStreak > 1 ? "  •  \(profile.currentWinStreak) win streak 🔥" : ""))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }

    // MARK: - Deck Selection

    private var deckSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("YOUR DECK")
                .font(.caption.bold())
                .tracking(1)
                .foregroundColor(GameTheme.gold)
                .padding(.horizontal, 24)

            if decks.isEmpty {
                Text("No decks yet — a starter deck is created on first launch, or build one in the Collection tab.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 24)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(decks) { deck in
                            deckCard(deck, isSelected: deck.id == selectedDeck?.id)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
    }

    @ViewBuilder
    private func deckCard(_ deck: Deck, isSelected: Bool) -> some View {
        Button {
            selectedDeckID = deck.id
            HapticsManager.shared.trigger(.selection)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    ChampionPortraitView(
                        championId: deck.champion?.stringId,
                        fallbackIcon: archetypeIcon(deck.champion?.archetype),
                        size: 40,
                        ringColor: isSelected ? GameTheme.gold : GameTheme.gold.opacity(0.4)
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(deck.name)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(deck.champion?.name ?? "No champion")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(1)
                    }
                }

                HStack(spacing: 10) {
                    if let champ = deck.champion {
                        statChip(icon: "heart.fill", value: champ.hp, color: GameTheme.hpGreen)
                        statChip(icon: "wind", value: champ.avoidance, color: GameTheme.manaBlue)
                        statChip(icon: "shield.fill", value: champ.mitigation, color: GameTheme.missGray)
                    }

                    Spacer()

                    Text("\(deck.cardCount)/\(DeckRules.deckSize)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(deck.isComplete ? GameTheme.hpGreen : .orange)
                }
            }
            .padding(12)
            .frame(width: 220, alignment: .leading)
            .background(isSelected ? GameTheme.gold.opacity(0.12) : GameTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? GameTheme.gold : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(deck.name), \(deck.champion?.name ?? "no champion"), \(deck.cardCount) cards")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func statChip(icon: String, value: Int, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9))
            Text("\(value)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
        }
        .foregroundColor(color)
    }

    // MARK: - Start Buttons

    private var startButtons: some View {
        VStack(spacing: 12) {
            Button {
                startMatch()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "flag.checkered")
                    Text("START RAID")
                        .font(.headline)
                }
                .foregroundColor(GameTheme.darkNavy)
                .frame(maxWidth: .infinity)
                .padding()
                .background(GameTheme.gold)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 40)
            .accessibilityLabel("Start raid with selected deck")

            Button {
                SoundManager.shared.play(.buttonTap)
                showHowToPlay = true
            } label: {
                Text("HOW TO PLAY")
                    .font(.headline)
                    .foregroundColor(GameTheme.gold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(GameTheme.gold.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(GameTheme.gold.opacity(0.3), lineWidth: 1)
                    )
            }
            .padding(.horizontal, 40)
        }
    }

    // MARK: - Match Start

    private func startMatch() {
        SoundManager.shared.play(.buttonTap)
        HapticsManager.shared.trigger(.medium)

        if let deck = selectedDeck {
            let cards = deck.materializedCards(from: allCards)
            if !cards.isEmpty {
                appState.startNewGame(champion: deck.champion, deckCards: cards.shuffled())
                return
            }
        }

        // Fallback: no usable deck — build a random legal deck from the catalog
        let champion = allChampions.randomElement()
        appState.startNewGame(champion: champion, deckCards: randomDeck())
    }

    /// Builds a random 40-card deck from the card catalog (max 2 copies each).
    private func randomDeck() -> [CardReference] {
        var refs: [CardReference] = []
        for card in allCards.shuffled() {
            for _ in 0..<DeckRules.maxCopiesPerCard where refs.count < DeckRules.deckSize {
                refs.append(CardReference(card: card, copyId: UUID()))
            }
            if refs.count >= DeckRules.deckSize { break }
        }
        return refs.shuffled()
    }

    private func archetypeIcon(_ archetype: Archetype?) -> String {
        switch archetype {
        case .warrior: return "shield.fill"
        case .rogue: return "swift"
        case .mage: return "wand.and.stars"
        case .paladin: return "cross.fill"
        case .berserker: return "flame.fill"
        case .shadow: return "moon.fill"
        case nil: return "person.fill"
        }
    }
}

#Preview {
    PlayView()
        .environment(AppState())
        .modelContainer(for: [PlayerProfile.self, Card.self, Champion.self, Deck.self], inMemory: true)
}
