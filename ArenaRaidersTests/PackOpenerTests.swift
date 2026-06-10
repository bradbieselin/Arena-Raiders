import XCTest
@testable import ArenaRaiders

/// Deterministic random number generator (SplitMix64) for reproducible pulls.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

final class PackOpenerTests: XCTestCase {

    // MARK: - Helpers

    /// Builds a catalog with cards of every rarity.
    private func makeCatalog() -> [Card] {
        var cards: [Card] = []
        for (index, rarity) in Rarity.allCases.enumerated() {
            for copy in 0..<5 {
                cards.append(Card(
                    stringId: "cat_\(index)_\(copy)",
                    name: "\(rarity.displayName) Card \(copy)",
                    cardType: .ability,
                    rarity: rarity
                ))
            }
        }
        return cards
    }

    // MARK: - Rarity Rolls

    func testRollRarityDistributionMatchesPullWeights() {
        var rng = SeededGenerator(seed: 42)
        var counts: [Rarity: Int] = [:]
        let trials = 20_000

        for _ in 0..<trials {
            let rarity = PackOpener.rollRarity(using: &rng)
            counts[rarity, default: 0] += 1
        }

        // Allow generous tolerance around expected weights
        let common = Double(counts[.common] ?? 0) / Double(trials)
        let rare = Double(counts[.rare] ?? 0) / Double(trials)
        let epic = Double(counts[.epic] ?? 0) / Double(trials)
        let legendary = Double(counts[.legendary] ?? 0) / Double(trials)

        XCTAssertEqual(common, 0.60, accuracy: 0.05)
        XCTAssertEqual(rare, 0.25, accuracy: 0.05)
        XCTAssertEqual(epic, 0.12, accuracy: 0.04)
        XCTAssertEqual(legendary, 0.03, accuracy: 0.02)
    }

    // MARK: - Pack Opening

    func testOpenReturnsCorrectCardCount() {
        let catalog = makeCatalog()
        var rng = SeededGenerator(seed: 1)

        for pack in CardPack.allPacks {
            let pulls = PackOpener.open(pack: pack, catalog: catalog, using: &rng)
            XCTAssertEqual(pulls.count, pack.cardCount, "\(pack.name) should pull \(pack.cardCount) cards")
        }
    }

    func testFirstCardMeetsGuaranteedMinimumRarity() {
        let catalog = makeCatalog()

        // Try many seeds — the first pull must never be below the guarantee
        for seed in 0..<200 {
            var rng = SeededGenerator(seed: UInt64(seed))
            let pulls = PackOpener.open(pack: .gold, catalog: catalog, using: &rng)
            XCTAssertFalse(pulls.isEmpty)
            XCTAssertGreaterThanOrEqual(
                pulls[0].rarity, Rarity.epic,
                "Gold pack first card must be epic or better (seed \(seed))"
            )
        }

        for seed in 0..<200 {
            var rng = SeededGenerator(seed: UInt64(seed))
            let pulls = PackOpener.open(pack: .silver, catalog: catalog, using: &rng)
            XCTAssertGreaterThanOrEqual(pulls[0].rarity, Rarity.rare)
        }
    }

    func testOpenWithEmptyCatalogReturnsNoCards() {
        var rng = SeededGenerator(seed: 7)
        let pulls = PackOpener.open(pack: .bronze, catalog: [], using: &rng)
        XCTAssertTrue(pulls.isEmpty)
    }

    func testOpenFallsBackWhenRarityPoolIsEmpty() {
        // Catalog with only common cards — every pull (including guaranteed
        // epic upgrades) must fall back to the full catalog.
        let commonsOnly = (0..<5).map {
            Card(stringId: "common_\($0)", name: "Common \($0)", cardType: .ability, rarity: .common)
        }

        var rng = SeededGenerator(seed: 3)
        let pulls = PackOpener.open(pack: .gold, catalog: commonsOnly, using: &rng)

        XCTAssertEqual(pulls.count, CardPack.gold.cardCount)
        XCTAssertTrue(pulls.allSatisfy { $0.rarity == .common })
    }

    func testOpenIsDeterministicWithSameSeed() {
        let catalog = makeCatalog()

        var rngA = SeededGenerator(seed: 99)
        var rngB = SeededGenerator(seed: 99)

        let pullsA = PackOpener.open(pack: .silver, catalog: catalog, using: &rngA)
        let pullsB = PackOpener.open(pack: .silver, catalog: catalog, using: &rngB)

        XCTAssertEqual(pullsA.map(\.stringId), pullsB.map(\.stringId))
    }

    // MARK: - Pack Definitions

    func testPackDefinitionsAreSane() {
        XCTAssertEqual(CardPack.allPacks.count, 3)
        for pack in CardPack.allPacks {
            XCTAssertGreaterThan(pack.cardCount, 0)
            XCTAssertGreaterThan(pack.price, 0)
        }
        // Better packs cost more
        XCTAssertLessThan(CardPack.bronze.price, CardPack.silver.price)
        XCTAssertLessThan(CardPack.silver.price, CardPack.gold.price)
    }
}
