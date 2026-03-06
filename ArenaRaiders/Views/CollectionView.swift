import SwiftUI
import SwiftData

// MARK: - Collection View

struct CardCollectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [PlayerProfile]
    @Query private var allCards: [Card]

    @State private var typeFilter: CardTypeFilter = .all
    @State private var rarityFilter: RarityFilter = .all
    @State private var selectedCard: Card?
    @State private var showDeckBuilder = false

    private var profile: PlayerProfile? { profiles.first }

    private var filteredCards: [Card] {
        guard let profile else { return [] }
        let ownedIds = Set(profile.cardCollection.map(\.cardStringId))
        return allCards
            .filter { ownedIds.contains($0.stringId) }
            .filter { typeFilter == .all || $0.cardType.rawValue == typeFilter.rawValue }
            .filter { rarityFilter == .all || $0.rarity.rawValue == rarityFilter.rawValue }
            .sorted { $0.stringId < $1.stringId }
    }

    private func quantityOf(_ card: Card) -> Int {
        profile?.cardCollection.first(where: { $0.cardStringId == card.stringId })?.quantity ?? 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GameTheme.darkNavy.ignoresSafeArea()

                VStack(spacing: 0) {
                    filterBar
                    cardGrid
                    deckBuilderButton
                }
            }
            .navigationTitle("Collection")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(item: $selectedCard) { card in
                CardDetailPopup(card: card, quantity: quantityOf(card))
            }
            .fullScreenCover(isPresented: $showDeckBuilder) {
                DeckBuilderView()
            }
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        VStack(spacing: 8) {
            // Type filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(CardTypeFilter.allCases, id: \.self) { filter in
                        FilterChip(
                            title: filter.displayName,
                            isSelected: typeFilter == filter
                        ) {
                            typeFilter = filter
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Rarity filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(RarityFilter.allCases, id: \.self) { filter in
                        FilterChip(
                            title: filter.displayName,
                            isSelected: rarityFilter == filter,
                            color: filter.color
                        ) {
                            rarityFilter = filter
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Card Grid

    private var cardGrid: some View {
        ScrollView {
            if filteredCards.isEmpty {
                VStack(spacing: 12) {
                    Spacer(minLength: 60)
                    Image(systemName: "rectangle.stack.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.4))
                    Text("No cards match filters")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
            } else {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 100), spacing: 12)
                ], spacing: 12) {
                    ForEach(filteredCards) { card in
                        CollectionCardCell(
                            card: card,
                            quantity: quantityOf(card)
                        ) {
                            selectedCard = card
                        }
                    }
                }
                .padding()
            }
        }
    }

    // MARK: - Deck Builder Button

    private var deckBuilderButton: some View {
        Button {
            showDeckBuilder = true
        } label: {
            Text("OPEN DECK BUILDER")
                .font(.headline)
                .foregroundColor(GameTheme.darkNavy)
                .frame(maxWidth: .infinity)
                .padding()
                .background(GameTheme.gold)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
    }
}

// MARK: - Filter Enums

enum CardTypeFilter: String, CaseIterable {
    case all = "All"
    case gear = "Gear"
    case talent = "Talent"
    case ability = "Ability"
    case adventure = "Adventure"

    var displayName: String { rawValue }
}

enum RarityFilter: String, CaseIterable {
    case all = "All Rarities"
    case common = "Common"
    case rare = "Rare"
    case epic = "Epic"
    case legendary = "Legendary"

    var displayName: String { rawValue }

    var color: Color {
        switch self {
        case .all: return .white
        case .common: return .gray
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return GameTheme.gold
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var color: Color = GameTheme.gold
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? GameTheme.darkNavy : .white.opacity(0.7))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? color : Color.white.opacity(0.08))
                .clipShape(Capsule())
        }
    }
}

// MARK: - Collection Card Cell

struct CollectionCardCell: View {
    let card: Card
    let quantity: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 4) {
                    // Cost badge
                    HStack {
                        HStack(spacing: 2) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 8))
                                .foregroundColor(GameTheme.gold)
                            Text("\(card.resourceCost)")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(GameTheme.gold)
                        }
                        Spacer()
                        if let dur = card.durability {
                            HStack(spacing: 2) {
                                Image(systemName: "shield.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(.white.opacity(0.7))
                                Text("\(dur)")
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }

                    // Card type icon
                    cardIcon
                        .font(.system(size: 22))
                        .foregroundColor(.white.opacity(0.9))
                        .frame(height: 28)

                    // Name
                    Text(card.name)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .frame(height: 26)

                    // Type label
                    Text(card.cardType.displayName)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(8)
                .frame(width: 100, height: 130)
                .background(GameTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(GameTheme.rarityColor(card.rarity), lineWidth: 1.5)
                )

                // Quantity badge
                if quantity > 1 {
                    Text("x\(quantity)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(GameTheme.gold.opacity(0.9))
                        .clipShape(Capsule())
                        .offset(x: 4, y: -4)
                }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var cardIcon: some View {
        switch card.cardType {
        case .gear:
            if let slot = card.gearSlot {
                Image(systemName: gearIcon(slot))
            } else {
                Image(systemName: "wrench.fill")
            }
        case .talent:
            Image(systemName: "star.fill")
        case .ability:
            Image(systemName: "bolt.fill")
        case .adventure:
            Image(systemName: "map.fill")
        }
    }

    private func gearIcon(_ slot: GearSlot) -> String {
        switch slot {
        case .head: return "crown.fill"
        case .chest: return "tshirt.fill"
        case .hands: return "hand.raised.fill"
        case .feet: return "shoe.fill"
        case .weapon: return "swift"
        }
    }
}

// MARK: - Card Detail Popup

struct CardDetailPopup: View {
    let card: Card
    let quantity: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            GameTheme.darkNavy.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Close button
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal)

                    // Large card art
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(GameTheme.cardBackground)
                            .frame(width: 200, height: 280)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(GameTheme.rarityColor(card.rarity), lineWidth: 3)
                            )

                        VStack(spacing: 12) {
                            // Cost
                            HStack(spacing: 4) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(GameTheme.gold)
                                Text("\(card.resourceCost)")
                                    .font(.title3.bold())
                                    .foregroundColor(GameTheme.gold)
                            }

                            // Icon
                            detailIcon
                                .font(.system(size: 48))
                                .foregroundColor(.white)

                            // Name
                            Text(card.name)
                                .font(.title3.bold())
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)

                            // Type + slot
                            HStack(spacing: 4) {
                                Text(card.cardType.displayName)
                                if let slot = card.gearSlot {
                                    Text("• \(slot.displayName)")
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))

                            if let dur = card.durability {
                                HStack(spacing: 4) {
                                    Image(systemName: "shield.fill")
                                        .font(.caption)
                                    Text("Durability: \(dur)")
                                        .font(.caption.bold())
                                }
                                .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding()
                    }

                    // Rarity badge
                    Text(card.rarity.displayName.uppercased())
                        .font(.caption.bold())
                        .tracking(2)
                        .foregroundColor(GameTheme.rarityColor(card.rarity))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(GameTheme.rarityColor(card.rarity).opacity(0.15))
                        .clipShape(Capsule())

                    // Quantity
                    Text("Owned: x\(quantity)")
                        .font(.subheadline)
                        .foregroundColor(GameTheme.gold)

                    // Effect text
                    VStack(alignment: .leading, spacing: 8) {
                        Text("EFFECT")
                            .font(.caption.bold())
                            .foregroundColor(GameTheme.gold)

                        Text(card.effectDescription)
                            .font(.body)
                            .foregroundColor(.white)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)

                    // Flavor text
                    if !card.flavorText.isEmpty {
                        Text(card.flavorText)
                            .font(.subheadline.italic())
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top, 20)
            }
        }
        .presentationBackground(GameTheme.darkNavy)
    }

    @ViewBuilder
    private var detailIcon: some View {
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
    CardCollectionView()
        .environment(AppState())
        .modelContainer(for: [PlayerProfile.self, Card.self], inMemory: true)
}
