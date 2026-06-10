import Foundation

// MARK: - Card Pack

struct CardPack: Identifiable, Equatable {
    let id: String
    let name: String
    let tagline: String
    let cardCount: Int
    let price: Int
    /// The first card pulled is upgraded to at least this rarity.
    let guaranteedMinimumRarity: Rarity
    let icon: String

    static let bronze = CardPack(
        id: "pack_bronze",
        name: "Bronze Pack",
        tagline: "3 cards",
        cardCount: 3,
        price: 100,
        guaranteedMinimumRarity: .common,
        icon: "shippingbox.fill"
    )

    static let silver = CardPack(
        id: "pack_silver",
        name: "Silver Pack",
        tagline: "5 cards • Rare guaranteed",
        cardCount: 5,
        price: 200,
        guaranteedMinimumRarity: .rare,
        icon: "shippingbox.circle.fill"
    )

    static let gold = CardPack(
        id: "pack_gold",
        name: "Gold Pack",
        tagline: "5 cards • Epic guaranteed",
        cardCount: 5,
        price: 350,
        guaranteedMinimumRarity: .epic,
        icon: "sparkles"
    )

    static let allPacks: [CardPack] = [.bronze, .silver, .gold]
}

// MARK: - Pack Opener
// Pure pull logic, kept independent of SwiftData so it can be tested with a
// seeded random number generator.

enum PackOpener {

    /// Rolls a rarity using the pull weights defined on `Rarity`
    /// (60% common, 25% rare, 12% epic, 3% legendary).
    static func rollRarity<R: RandomNumberGenerator>(using rng: inout R) -> Rarity {
        let roll = Double.random(in: 0..<1, using: &rng)
        var cumulative = 0.0
        for rarity in Rarity.allCases {
            cumulative += rarity.pullWeight
            if roll < cumulative {
                return rarity
            }
        }
        return .common
    }

    /// Pulls cards for a pack from the catalog. The first card is upgraded to
    /// the pack's guaranteed minimum rarity. If the catalog has no card of a
    /// rolled rarity, the pull falls back to the whole catalog.
    static func open<R: RandomNumberGenerator>(
        pack: CardPack,
        catalog: [Card],
        using rng: inout R
    ) -> [Card] {
        guard !catalog.isEmpty else { return [] }

        var pulls: [Card] = []
        for index in 0..<pack.cardCount {
            var rarity = rollRarity(using: &rng)
            if index == 0, rarity < pack.guaranteedMinimumRarity {
                rarity = pack.guaranteedMinimumRarity
            }

            let pool = catalog.filter { $0.rarity == rarity }
            let candidates = pool.isEmpty ? catalog : pool
            if let card = candidates.randomElement(using: &rng) {
                pulls.append(card)
            }
        }
        return pulls
    }

    static func open(pack: CardPack, catalog: [Card]) -> [Card] {
        var rng = SystemRandomNumberGenerator()
        return open(pack: pack, catalog: catalog, using: &rng)
    }
}
