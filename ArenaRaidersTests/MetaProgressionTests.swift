import XCTest
import SwiftData
@testable import ArenaRaiders

@MainActor
final class MetaProgressionTests: XCTestCase {

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            PlayerProfile.self,
            Champion.self,
            Card.self,
            Deck.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    private func makeRecord(didWin: Bool, gold: Int = 25) -> MatchRecord {
        MatchRecord(
            didWin: didWin,
            championName: "Test Champ",
            opponentName: "Test Opponent",
            turnsPlayed: 7,
            chestsBroken: 3,
            goldEarned: gold
        )
    }

    // MARK: - Match Recording

    func testRecordMatchWinUpdatesProfile() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let profile = PlayerProfile(currency: 100)
        context.insert(profile)
        try context.save()

        SaveSystem.recordMatch(makeRecord(didWin: true, gold: 25), context: context)

        XCTAssertEqual(profile.totalWins, 1)
        XCTAssertEqual(profile.totalLosses, 0)
        XCTAssertEqual(profile.currentWinStreak, 1)
        XCTAssertEqual(profile.bestWinStreak, 1)
        XCTAssertEqual(profile.currency, 125)
        XCTAssertEqual(profile.matchHistory.count, 1)
        XCTAssertTrue(profile.matchHistory[0].didWin)
    }

    func testLossResetsCurrentStreakButKeepsBest() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let profile = PlayerProfile(currency: 0)
        context.insert(profile)
        try context.save()

        SaveSystem.recordMatch(makeRecord(didWin: true), context: context)
        SaveSystem.recordMatch(makeRecord(didWin: true), context: context)
        SaveSystem.recordMatch(makeRecord(didWin: false, gold: 5), context: context)

        XCTAssertEqual(profile.totalWins, 2)
        XCTAssertEqual(profile.totalLosses, 1)
        XCTAssertEqual(profile.currentWinStreak, 0)
        XCTAssertEqual(profile.bestWinStreak, 2)

        // Newest match first
        XCTAssertFalse(profile.matchHistory[0].didWin)
    }

    func testMatchHistoryIsCapped() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let profile = PlayerProfile()
        context.insert(profile)
        try context.save()

        for _ in 0..<(SaveSystem.maxMatchHistoryEntries + 5) {
            SaveSystem.recordMatch(makeRecord(didWin: true, gold: 1), context: context)
        }

        XCTAssertEqual(profile.matchHistory.count, SaveSystem.maxMatchHistoryEntries)
    }

    // MARK: - Daily Bonus

    func testDailyBonusCanBeClaimedOncePerDay() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let profile = PlayerProfile(currency: 0)
        context.insert(profile)
        try context.save()

        let day1 = Date()
        XCTAssertTrue(SaveSystem.claimDailyBonus(context: context, now: day1))
        XCTAssertEqual(profile.currency, SaveSystem.dailyBonusAmount)

        // Immediate second claim is rejected
        XCTAssertFalse(SaveSystem.claimDailyBonus(context: context, now: day1.addingTimeInterval(60)))
        XCTAssertEqual(profile.currency, SaveSystem.dailyBonusAmount)

        // After 24h it becomes available again
        let day2 = day1.addingTimeInterval(SaveSystem.dailyBonusInterval + 1)
        XCTAssertTrue(SaveSystem.claimDailyBonus(context: context, now: day2))
        XCTAssertEqual(profile.currency, SaveSystem.dailyBonusAmount * 2)
    }

    // MARK: - Reset

    func testResetProgressClearsMetaProgression() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let profile = PlayerProfile(currency: 999)
        context.insert(profile)
        try context.save()

        SaveSystem.recordMatch(makeRecord(didWin: true), context: context)
        profile.packsOpened = 3
        profile.lastDailyBonusClaim = Date()

        SaveSystem.resetProgress(context: context)

        XCTAssertEqual(profile.totalWins, 0)
        XCTAssertEqual(profile.currentWinStreak, 0)
        XCTAssertEqual(profile.bestWinStreak, 0)
        XCTAssertEqual(profile.packsOpened, 0)
        XCTAssertNil(profile.lastDailyBonusClaim)
        XCTAssertTrue(profile.matchHistory.isEmpty)
        XCTAssertEqual(profile.currency, 100)
    }

    // MARK: - Deck Materialization

    func testDeckMaterializationExpandsQuantities() throws {
        let cardA = Card(stringId: "mat_a", name: "Card A", cardType: .ability)
        let cardB = Card(stringId: "mat_b", name: "Card B", cardType: .gear, gearSlot: .weapon, durability: 3)
        let catalog = [cardA, cardB]

        let deck = Deck(name: "Test Deck", cardSlots: [
            DeckCardSlot(card: cardA, quantity: 2),
            DeckCardSlot(card: cardB, quantity: 1)
        ])

        let refs = deck.materializedCards(from: catalog)

        XCTAssertEqual(refs.count, 3)
        XCTAssertEqual(refs.filter { $0.stringId == "mat_a" }.count, 2)
        XCTAssertEqual(refs.filter { $0.stringId == "mat_b" }.count, 1)

        // Every copy must have a unique identity for in-game tracking
        XCTAssertEqual(Set(refs.map(\.id)).count, refs.count)
    }

    func testDeckMaterializationSkipsUnknownCards() throws {
        let cardA = Card(stringId: "mat_known", name: "Known", cardType: .ability)

        let ghost = Card(stringId: "mat_ghost", name: "Ghost", cardType: .ability)
        let deck = Deck(name: "Test Deck", cardSlots: [
            DeckCardSlot(card: cardA, quantity: 1),
            DeckCardSlot(card: ghost, quantity: 2)
        ])

        // Catalog only knows cardA
        let refs = deck.materializedCards(from: [cardA])

        XCTAssertEqual(refs.count, 1)
        XCTAssertEqual(refs[0].stringId, "mat_known")
    }

    // MARK: - Match Record

    func testMatchRecordCodableRoundTrip() throws {
        let record = makeRecord(didWin: true, gold: 40)
        let data = try JSONEncoder().encode(record)
        let decoded = try JSONDecoder().decode(MatchRecord.self, from: data)
        XCTAssertEqual(record, decoded)
    }
}
