import XCTest
@testable import ArenaRaiders

final class AchievementsTests: XCTestCase {

    func testCatalogHasUniqueKinds() {
        let kinds = Achievements.all.map(\.kind)
        XCTAssertEqual(kinds.count, Set(kinds).count)
        XCTAssertEqual(Achievements.all.count, AchievementKind.allCases.count)
    }

    func testFreshProfileHasNoUnlockedAchievements() {
        let profile = PlayerProfile()
        XCTAssertEqual(Achievements.unlockedCount(for: profile), 0)
    }

    func testFirstVictoryUnlocksAfterOneWin() {
        let profile = PlayerProfile()
        profile.totalWins = 1

        let progress = Achievements.progress(for: profile)
        let firstVictory = progress.first { $0.achievement.kind == .firstVictory }

        XCTAssertNotNil(firstVictory)
        XCTAssertTrue(firstVictory!.isUnlocked)

        // Veteran (10 wins) should still be locked, with partial progress
        let veteran = progress.first { $0.achievement.kind == .veteran }
        XCTAssertFalse(veteran!.isUnlocked)
        XCTAssertEqual(veteran!.current, 1)
    }

    func testStreakAchievementsUseBestStreak() {
        let profile = PlayerProfile()
        profile.bestWinStreak = 4
        profile.currentWinStreak = 0

        let progress = Achievements.progress(for: profile)
        XCTAssertTrue(progress.first { $0.achievement.kind == .onARoll }!.isUnlocked)
        XCTAssertFalse(progress.first { $0.achievement.kind == .unstoppable }!.isUnlocked)
    }

    func testCollectorTracksUniqueCards() {
        let profile = PlayerProfile()
        for i in 0..<30 {
            profile.addCard(Card(stringId: "ach_card_\(i)", name: "Card \(i)", cardType: .ability))
        }

        let collector = Achievements.progress(for: profile).first { $0.achievement.kind == .collector }
        XCTAssertEqual(collector!.current, 30)
        XCTAssertTrue(collector!.isUnlocked)
    }

    func testProgressFractionIsClamped() {
        let profile = PlayerProfile()
        profile.totalWins = 100 // far beyond every wins target

        for progress in Achievements.progress(for: profile) {
            XCTAssertGreaterThanOrEqual(progress.fraction, 0)
            XCTAssertLessThanOrEqual(progress.fraction, 1)
        }
    }

    func testPackRatTracksPacksOpened() {
        let profile = PlayerProfile()
        profile.packsOpened = 5

        let packRat = Achievements.progress(for: profile).first { $0.achievement.kind == .packRat }
        XCTAssertTrue(packRat!.isUnlocked)
    }
}
