import SwiftUI
import SwiftData

struct DeckBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [PlayerProfile]
    @Query private var allCards: [Card]
    @Query private var allChampions: [Champion]

    @State private var selectedChampion: Champion?
    @State private var deckSlots: [DeckBuilderSlot] = []
    @State private var deckName: String = ""
    @State private var typeFilter: CardTypeFilter = .all
    @State private var rarityFilter: RarityFilter = .all
    @State private var errorMessage: String?
    @State private var showSavedAlert = false

    private var profile: PlayerProfile? { profiles.first }

    private var deckCardCount: Int {
        deckSlots.reduce(0) { $0 + $1.quantity }
    }

    private var ownedCards: [Card] {
        guard let profile else { return [] }
        let ownedIds = Set(profile.cardCollection.map(\.cardStringId))
        return allCards
            .filter { ownedIds.contains($0.stringId) }
            .filter { typeFilter == .all || $0.cardType.rawValue == typeFilter.rawValue }
            .filter { rarityFilter == .all || $0.rarity.rawValue == rarityFilter.rawValue }
            .sorted { $0.stringId < $1.stringId }
    }

    private func ownedQuantity(of card: Card) -> Int {
        profile?.cardCollection.first(where: { $0.cardStringId == card.stringId })?.quantity ?? 0
    }

    private func deckQuantity(of card: Card) -> Int {
        deckSlots.first(where: { $0.cardStringId == card.stringId })?.quantity ?? 0
    }

    private func canAddCard(_ card: Card) -> Bool {
        guard deckCardCount < DeckRules.deckSize else { return false }
        let inDeck = deckQuantity(of: card)
        let owned = ownedQuantity(of: card)
        guard inDeck < DeckRules.maxCopiesPerCard, inDeck < owned else { return false }

        // Gear slot rule: only 1 per slot
        if card.isGear, let slot = card.gearSlot {
            let slotOccupied = deckSlots.contains { slotEntry in
                allCards.first(where: { $0.stringId == slotEntry.cardStringId })?.gearSlot == slot
            }
            if slotOccupied { return false }
        }

        return true
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GameTheme.darkNavy.ignoresSafeArea()

                VStack(spacing: 0) {
                    championSelector
                    Divider().background(Color.white.opacity(0.1))
                    cardBrowserAndDeck
                    Divider().background(Color.white.opacity(0.1))
                    bottomBar
                }
            }
            .navigationTitle("Deck Builder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(GameTheme.gold)
                }
            }
            .alert("Deck Saved!", isPresented: $showSavedAlert) {
                Button("OK") { dismiss() }
            }
        }
    }

    // MARK: - Champion Selector

    private var championSelector: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("CHAMPION")
                .font(.caption.bold())
                .foregroundColor(GameTheme.gold)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(allChampions) { champion in
                        let isSelected = selectedChampion?.id == champion.id
                        Button {
                            selectedChampion = champion
                        } label: {
                            VStack(spacing: 4) {
                                ChampionPortraitView(
                                    championId: champion.stringId,
                                    fallbackIcon: archetypeIcon(champion.archetype),
                                    size: 56,
                                    ringColor: isSelected ? GameTheme.gold : Color.white.opacity(0.25)
                                )
                                .opacity(isSelected ? 1.0 : 0.75)

                                Text(champion.name)
                                    .font(.system(size: 9, weight: isSelected ? .bold : .medium))
                                    .foregroundColor(isSelected ? GameTheme.gold : .white.opacity(0.6))
                                    .lineLimit(1)
                                    .frame(width: 60)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Card Browser + Deck List

    private var cardBrowserAndDeck: some View {
        HStack(spacing: 0) {
            // Left: card browser
            VStack(spacing: 0) {
                // Filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(CardTypeFilter.allCases, id: \.self) { filter in
                            FilterChip(
                                title: filter.displayName,
                                isSelected: typeFilter == filter
                            ) {
                                typeFilter = filter
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .padding(.vertical, 6)

                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 90), spacing: 8)
                    ], spacing: 8) {
                        ForEach(ownedCards) { card in
                            let addable = canAddCard(card)
                            Button {
                                addCardToDeck(card)
                            } label: {
                                DeckBuilderCardCell(
                                    card: card,
                                    ownedQty: ownedQuantity(of: card),
                                    deckQty: deckQuantity(of: card),
                                    canAdd: addable
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(!addable)
                        }
                    }
                    .padding(8)
                }
            }
            .frame(maxWidth: .infinity)

            // Right: deck list
            VStack(spacing: 0) {
                Text("DECK  \(deckCardCount)/\(DeckRules.deckSize)")
                    .font(.caption.bold())
                    .foregroundColor(deckCardCount == DeckRules.deckSize ? GameTheme.hpGreen : GameTheme.gold)
                    .padding(.vertical, 8)

                if deckSlots.isEmpty {
                    Spacer()
                    Text("Tap cards\nto add")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(deckSlots) { slot in
                                deckSlotRow(slot)
                            }
                        }
                    }
                }
            }
            .frame(width: 140)
            .background(Color.white.opacity(0.03))
        }
    }

    @ViewBuilder
    private func deckSlotRow(_ slot: DeckBuilderSlot) -> some View {
        HStack(spacing: 6) {
            Text(slot.cardName)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)

            Spacer()

            if slot.quantity > 1 {
                Text("x\(slot.quantity)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(GameTheme.gold)
            }

            Button {
                removeCardFromDeck(slot)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(GameTheme.hpRed.opacity(0.7))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.05))
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 8) {
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(GameTheme.hpRed)
            }

            HStack(spacing: 12) {
                TextField("Deck Name", text: $deckName)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Button {
                    saveDeck()
                } label: {
                    Text("SAVE DECK")
                        .font(.headline)
                        .foregroundColor(GameTheme.darkNavy)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(canSave ? GameTheme.gold : GameTheme.gold.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(!canSave)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 10)
    }

    private var canSave: Bool {
        selectedChampion != nil && deckCardCount == DeckRules.deckSize && !deckName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Actions

    private func addCardToDeck(_ card: Card) {
        guard canAddCard(card) else { return }
        errorMessage = nil

        if let idx = deckSlots.firstIndex(where: { $0.cardStringId == card.stringId }) {
            deckSlots[idx].quantity += 1
        } else {
            deckSlots.append(DeckBuilderSlot(
                cardStringId: card.stringId,
                cardName: card.name,
                quantity: 1
            ))
        }
    }

    private func removeCardFromDeck(_ slot: DeckBuilderSlot) {
        guard let idx = deckSlots.firstIndex(where: { $0.id == slot.id }) else { return }
        deckSlots[idx].quantity -= 1
        if deckSlots[idx].quantity <= 0 {
            deckSlots.remove(at: idx)
        }
    }

    private func saveDeck() {
        guard let profile, let champion = selectedChampion else {
            errorMessage = "Select a champion first"
            return
        }
        guard deckCardCount == DeckRules.deckSize else {
            errorMessage = "Deck needs exactly \(DeckRules.deckSize) cards (\(deckCardCount)/\(DeckRules.deckSize))"
            return
        }

        let trimmedName = deckName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            errorMessage = "Enter a deck name"
            return
        }

        let cardSlots = deckSlots.map { slot in
            DeckCardSlot(
                card: Card(stringId: slot.cardStringId, name: slot.cardName, cardType: .ability),
                quantity: slot.quantity
            )
        }

        let deck = Deck(name: trimmedName, champion: champion, cardSlots: cardSlots)
        SaveSystem.saveDeck(deck, to: profile, context: modelContext)
        showSavedAlert = true
    }

    private func archetypeIcon(_ archetype: Archetype) -> String {
        switch archetype {
        case .warrior: return "shield.fill"
        case .rogue: return "swift"
        case .mage: return "wand.and.stars"
        case .paladin: return "cross.fill"
        case .berserker: return "flame.fill"
        case .shadow: return "moon.fill"
        }
    }
}

// MARK: - Deck Builder Slot

struct DeckBuilderSlot: Identifiable, Equatable {
    let id = UUID()
    let cardStringId: String
    let cardName: String
    var quantity: Int
}

// MARK: - Deck Builder Card Cell

struct DeckBuilderCardCell: View {
    let card: Card
    let ownedQty: Int
    let deckQty: Int
    let canAdd: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 2) {
                HStack {
                    HStack(spacing: 2) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 7))
                            .foregroundColor(GameTheme.gold)
                        Text("\(card.resourceCost)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(GameTheme.gold)
                    }
                    Spacer()
                }

                cardIcon
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(height: 22)

                Text(card.name)
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(height: 22)

                // Deck quantity indicator
                if deckQty > 0 {
                    Text("\(deckQty)/\(Swift.min(ownedQty, DeckRules.maxCopiesPerCard))")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(GameTheme.hpGreen)
                }
            }
            .padding(6)
            .frame(width: 85, height: 105)
            .background(GameTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        deckQty > 0 ? GameTheme.hpGreen : GameTheme.rarityColor(card.rarity),
                        lineWidth: deckQty > 0 ? 2 : 1
                    )
            )
            .opacity(canAdd || deckQty > 0 ? 1.0 : 0.4)
        }
    }

    @ViewBuilder
    private var cardIcon: some View {
        switch card.cardType {
        case .gear:
            if let slot = card.gearSlot {
                switch slot {
                case .head: Image(systemName: "crown.fill")
                case .chest: Image(systemName: "tshirt.fill")
                case .hands: Image(systemName: "hand.raised.fill")
                case .feet: Image(systemName: "shoe.fill")
                case .weapon: Image(systemName: "swift")
                }
            } else {
                Image(systemName: "wrench.fill")
            }
        case .talent: Image(systemName: "star.fill")
        case .ability: Image(systemName: "bolt.fill")
        case .adventure: Image(systemName: "map.fill")
        }
    }
}

#Preview {
    DeckBuilderView()
        .modelContainer(for: [PlayerProfile.self, Card.self, Champion.self], inMemory: true)
}
