import Foundation
import SwiftData

struct SaveSystem {

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
