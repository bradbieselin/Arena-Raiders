import Foundation
import SwiftData

struct SaveSystem {

    static let maxMatchHistoryEntries = 50
    static let dailyBonusAmount = 50
    static let dailyBonusInterval: TimeInterval = 24 * 60 * 60

    // MARK: - Game End

    /// Records a game result: updates wins/losses, grants currency, saves immediately.
    @MainActor
    static func recordGameResult(
        didWin: Bool,
        context: ModelContext
    ) {
        guard let profile = fetchProfile(context: context) else { return }

        if didWin {
            profile.totalWins += 1
            profile.currency += 10
        } else {
            profile.totalLosses += 1
            profile.currency += 3
        }

        save(context: context)
    }

    /// Records a full match result: wins/losses, win streaks, gold reward,
    /// and match history. Saves immediately.
    @MainActor
    static func recordMatch(_ record: MatchRecord, context: ModelContext) {
        guard let profile = fetchProfile(context: context) else { return }

        if record.didWin {
            profile.totalWins += 1
            profile.currentWinStreak += 1
            profile.bestWinStreak = max(profile.bestWinStreak, profile.currentWinStreak)
        } else {
            profile.totalLosses += 1
            profile.currentWinStreak = 0
        }

        profile.currency += record.goldEarned
        profile.matchHistory.insert(record, at: 0)
        if profile.matchHistory.count > maxMatchHistoryEntries {
            profile.matchHistory = Array(profile.matchHistory.prefix(maxMatchHistoryEntries))
        }

        save(context: context)
    }

    // MARK: - Daily Bonus

    static func canClaimDailyBonus(profile: PlayerProfile, now: Date = Date()) -> Bool {
        guard let lastClaim = profile.lastDailyBonusClaim else { return true }
        return now.timeIntervalSince(lastClaim) >= dailyBonusInterval
    }

    /// Grants the daily bonus if available. Returns true when claimed.
    @MainActor
    @discardableResult
    static func claimDailyBonus(context: ModelContext, now: Date = Date()) -> Bool {
        guard let profile = fetchProfile(context: context),
              canClaimDailyBonus(profile: profile, now: now) else { return false }

        profile.currency += dailyBonusAmount
        profile.lastDailyBonusClaim = now
        save(context: context)
        return true
    }

    // MARK: - Profile Helpers

    @MainActor
    static func fetchProfile(context: ModelContext) -> PlayerProfile? {
        let descriptor = FetchDescriptor<PlayerProfile>()
        return (try? context.fetch(descriptor))?.first
    }

    @MainActor
    static func updateDisplayName(_ name: String, context: ModelContext) {
        guard let profile = fetchProfile(context: context) else { return }
        profile.displayName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        save(context: context)
    }

    @MainActor
    static func toggleRemoveAds(context: ModelContext) {
        guard let profile = fetchProfile(context: context) else { return }
        profile.hasRemovedAds = true
        save(context: context)
    }

    @MainActor
    static func resetProgress(context: ModelContext) {
        guard let profile = fetchProfile(context: context) else { return }
        profile.totalWins = 0
        profile.totalLosses = 0
        profile.currency = 100
        profile.hasRemovedAds = false
        profile.currentWinStreak = 0
        profile.bestWinStreak = 0
        profile.packsOpened = 0
        profile.lastDailyBonusClaim = nil
        profile.matchHistory = []
        save(context: context)
    }

    // MARK: - Deck Persistence

    @MainActor
    static func saveDeck(_ deck: Deck, to profile: PlayerProfile, context: ModelContext) {
        if !profile.savedDecks.contains(where: { $0.id == deck.id }) {
            context.insert(deck)
            profile.savedDecks.append(deck)
        }
        save(context: context)
    }

    // MARK: - Private

    @MainActor
    static func save(context: ModelContext) {
        do {
            try context.save()
        } catch {
            print("SaveSystem: Failed to save — \(error)")
        }
    }
}
