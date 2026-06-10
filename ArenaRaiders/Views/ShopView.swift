import SwiftUI
import SwiftData

struct ShopView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [PlayerProfile]
    @Query private var allCards: [Card]

    @State private var openedCards: [Card] = []
    @State private var openedPackName: String = ""
    @State private var showPackOpening = false
    @State private var purchaseMessage: String?

    private var profile: PlayerProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ZStack {
                GameTheme.darkNavy.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        balanceHeader
                        dailyBonusSection
                        packSection

                        if let purchaseMessage {
                            Text(purchaseMessage)
                                .font(.caption.bold())
                                .foregroundColor(GameTheme.hpRed)
                                .transition(.opacity)
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Shop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .fullScreenCover(isPresented: $showPackOpening) {
                PackOpeningView(
                    packName: openedPackName,
                    cards: openedCards
                )
            }
        }
    }

    // MARK: - Balance

    private var balanceHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "dollarsign.circle.fill")
                .font(.title3)
                .foregroundColor(GameTheme.gold)

            Text("\(profile?.currency ?? 0)")
                .font(.title3.bold())
                .foregroundColor(GameTheme.gold)

            Text("GOLD")
                .font(.caption.bold())
                .tracking(1)
                .foregroundColor(GameTheme.gold.opacity(0.6))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(GameTheme.gold.opacity(0.1))
        .clipShape(Capsule())
        .accessibilityLabel("Balance: \(profile?.currency ?? 0) gold")
    }

    // MARK: - Daily Bonus

    @ViewBuilder
    private var dailyBonusSection: some View {
        if let profile {
            let canClaim = SaveSystem.canClaimDailyBonus(profile: profile)

            HStack(spacing: 12) {
                Image(systemName: "gift.fill")
                    .font(.title2)
                    .foregroundColor(canClaim ? GameTheme.gold : .gray)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily Bonus")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)

                    Text(canClaim
                         ? "+\(SaveSystem.dailyBonusAmount) gold is waiting for you"
                         : nextClaimText(profile: profile))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                Button {
                    claimDaily()
                } label: {
                    Text(canClaim ? "CLAIM" : "CLAIMED")
                        .font(.caption.bold())
                        .foregroundColor(canClaim ? GameTheme.darkNavy : .gray)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(canClaim ? GameTheme.gold : Color.white.opacity(0.08))
                        .clipShape(Capsule())
                }
                .disabled(!canClaim)
                .accessibilityLabel(canClaim ? "Claim daily bonus" : "Daily bonus already claimed")
            }
            .padding(14)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 20)
        }
    }

    private func nextClaimText(profile: PlayerProfile) -> String {
        guard let last = profile.lastDailyBonusClaim else { return "Available now" }
        let nextDate = last.addingTimeInterval(SaveSystem.dailyBonusInterval)
        let remaining = max(0, nextDate.timeIntervalSinceNow)
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        if hours > 0 {
            return "Next bonus in \(hours)h \(minutes)m"
        }
        return "Next bonus in \(minutes)m"
    }

    private func claimDaily() {
        guard SaveSystem.claimDailyBonus(context: modelContext) else { return }
        SoundManager.shared.play(.coin)
        HapticsManager.shared.trigger(.success)
    }

    // MARK: - Packs

    private var packSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CARD PACKS")
                .font(.caption.bold())
                .tracking(1)
                .foregroundColor(GameTheme.gold)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(CardPack.allPacks) { pack in
                        packCard(pack)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    @ViewBuilder
    private func packCard(_ pack: CardPack) -> some View {
        let affordable = (profile?.currency ?? 0) >= pack.price

        VStack(spacing: 8) {
            Image(systemName: pack.icon)
                .font(.system(size: 34))
                .foregroundStyle(packColor(pack))
                .frame(height: 44)

            Text(pack.name)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(pack.tagline)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .frame(height: 28)

            Button {
                buy(pack)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 12))
                    Text("\(pack.price)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                .foregroundColor(affordable ? GameTheme.darkNavy : .gray)
                .frame(width: 110)
                .padding(.vertical, 9)
                .background(affordable ? GameTheme.gold : Color.white.opacity(0.08))
                .clipShape(Capsule())
            }
            .disabled(!affordable)
            .accessibilityLabel("Buy \(pack.name) for \(pack.price) gold")
        }
        .padding(16)
        .frame(width: 160)
        .background(GameTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(packColor(pack).opacity(0.4), lineWidth: 1.5)
        )
    }

    private func packColor(_ pack: CardPack) -> Color {
        switch pack.guaranteedMinimumRarity {
        case .common: return GameTheme.rareSilver
        case .rare: return GameTheme.rareBlue
        case .epic: return GameTheme.epicPurple
        case .legendary: return GameTheme.gold
        }
    }

    private func buy(_ pack: CardPack) {
        guard let profile else { return }
        guard profile.currency >= pack.price else {
            showPurchaseMessage("Not enough gold")
            HapticsManager.shared.trigger(.error)
            return
        }

        let pulls = PackOpener.open(pack: pack, catalog: allCards)
        guard !pulls.isEmpty else {
            showPurchaseMessage("Shop is restocking — try again later")
            return
        }

        profile.currency -= pack.price
        for card in pulls {
            profile.addCard(card)
        }
        profile.packsOpened += 1
        try? modelContext.save()

        SoundManager.shared.play(.packOpen)
        HapticsManager.shared.trigger(.success)

        openedCards = pulls
        openedPackName = pack.name
        showPackOpening = true
    }

    private func showPurchaseMessage(_ message: String) {
        withAnimation { purchaseMessage = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { purchaseMessage = nil }
        }
    }
}

// MARK: - Pack Opening Reveal

struct PackOpeningView: View {
    let packName: String
    let cards: [Card]

    @Environment(\.dismiss) private var dismiss
    @State private var revealed: Set<Int> = []

    private var allRevealed: Bool { revealed.count == cards.count }

    var body: some View {
        ZStack {
            GameTheme.deepNavy.ignoresSafeArea()

            VStack(spacing: 16) {
                Text(packName.uppercased())
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .tracking(3)
                    .foregroundColor(GameTheme.gold)
                    .padding(.top, 16)

                Text(allRevealed ? "Added to your collection!" : "Tap the cards to reveal")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))

                Spacer()

                HStack(spacing: 14) {
                    ForEach(Array(cards.enumerated()), id: \.offset) { index, card in
                        revealCard(card, index: index)
                    }
                }

                Spacer()

                Button {
                    SoundManager.shared.play(.buttonTap)
                    if allRevealed {
                        dismiss()
                    } else {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            revealed = Set(cards.indices)
                        }
                        SoundManager.shared.play(.crit)
                    }
                } label: {
                    Text(allRevealed ? "DONE" : "REVEAL ALL")
                        .font(.headline)
                        .foregroundColor(GameTheme.darkNavy)
                        .frame(width: 220)
                        .padding(.vertical, 13)
                        .background(GameTheme.gold)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.bottom, 20)
                .accessibilityLabel(allRevealed ? "Done" : "Reveal all cards")
            }
        }
    }

    @ViewBuilder
    private func revealCard(_ card: Card, index: Int) -> some View {
        let isRevealed = revealed.contains(index)

        ZStack {
            if isRevealed {
                cardFront(card)
                    .transition(.scale.combined(with: .opacity))
            } else {
                cardBack
            }
        }
        .onTapGesture {
            guard !isRevealed else { return }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                _ = revealed.insert(index)
            }
            SoundManager.shared.play(.cardPlay)
            HapticsManager.shared.trigger(card.rarity >= .epic ? .heavy : .light)
        }
        .accessibilityLabel(isRevealed ? "\(card.name), \(card.rarity.displayName)" : "Face-down card")
        .accessibilityHint(isRevealed ? "" : "Tap to reveal")
    }

    private var cardBack: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(GameTheme.cardBackground)
            .frame(width: 110, height: 150)
            .overlay(
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 30))
                    .foregroundColor(GameTheme.gold.opacity(0.4))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(GameTheme.gold.opacity(0.3), lineWidth: 1.5)
            )
    }

    private func cardFront(_ card: Card) -> some View {
        VStack(spacing: 6) {
            HStack {
                HStack(spacing: 2) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                    Text("\(card.resourceCost)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                }
                .foregroundColor(GameTheme.gold)
                Spacer()
            }

            Spacer()

            Text(card.name)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(3)
                .multilineTextAlignment(.center)

            Spacer()

            Text(card.rarity.displayName.uppercased())
                .font(.system(size: 8, weight: .heavy))
                .tracking(1)
                .foregroundColor(GameTheme.rarityColor(card.rarity))
        }
        .padding(8)
        .frame(width: 110, height: 150)
        .background(GameTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(GameTheme.rarityColor(card.rarity), lineWidth: 2)
        )
        .shadow(
            color: GameTheme.rarityColor(card.rarity).opacity(0.5),
            radius: GameTheme.rarityGlowRadius(card.rarity)
        )
    }
}

#Preview {
    ShopView()
        .modelContainer(for: [PlayerProfile.self, Card.self], inMemory: true)
}
