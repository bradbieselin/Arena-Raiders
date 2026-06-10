import Foundation

// MARK: - Achievement Definitions

enum AchievementKind: String, CaseIterable, Identifiable {
    case firstVictory
    case veteran
    case gladiator
    case onARoll
    case unstoppable
    case collector
    case hoarder
    case packRat
    case dedicated

    var id: String { rawValue }
}

struct Achievement: Identifiable {
    let kind: AchievementKind
    let title: String
    let detail: String
    let icon: String
    let target: Int

    var id: String { kind.rawValue }
}

/// Snapshot of a player's progress toward one achievement.
struct AchievementProgress: Identifiable {
    let achievement: Achievement
    let current: Int

    var id: String { achievement.id }

    var isUnlocked: Bool { current >= achievement.target }

    var fraction: Double {
        guard achievement.target > 0 else { return 1 }
        return min(1, Double(current) / Double(achievement.target))
    }
}

// MARK: - Achievement Catalog & Evaluation
// Achievements are derived from profile stats, so they need no extra storage
// and stay correct even after schema changes or progress resets.

enum Achievements {
    static let all: [Achievement] = [
        Achievement(kind: .firstVictory, title: "First Victory", detail: "Win your first match", icon: "trophy.fill", target: 1),
        Achievement(kind: .veteran, title: "Veteran", detail: "Win 10 matches", icon: "medal.fill", target: 10),
        Achievement(kind: .gladiator, title: "Gladiator", detail: "Win 25 matches", icon: "crown.fill", target: 25),
        Achievement(kind: .onARoll, title: "On a Roll", detail: "Win 3 matches in a row", icon: "flame.fill", target: 3),
        Achievement(kind: .unstoppable, title: "Unstoppable", detail: "Win 5 matches in a row", icon: "bolt.fill", target: 5),
        Achievement(kind: .collector, title: "Collector", detail: "Own 30 unique cards", icon: "rectangle.stack.fill", target: 30),
        Achievement(kind: .hoarder, title: "Hoarder", detail: "Own 60 unique cards", icon: "archivebox.fill", target: 60),
        Achievement(kind: .packRat, title: "Pack Rat", detail: "Open 5 card packs", icon: "shippingbox.fill", target: 5),
        Achievement(kind: .dedicated, title: "Dedicated", detail: "Play 20 matches", icon: "gamecontroller.fill", target: 20)
    ]

    static func value(of kind: AchievementKind, profile: PlayerProfile) -> Int {
        switch kind {
        case .firstVictory, .veteran, .gladiator:
            return profile.totalWins
        case .onARoll, .unstoppable:
            return profile.bestWinStreak
        case .collector, .hoarder:
            return profile.uniqueCardsOwned
        case .packRat:
            return profile.packsOpened
        case .dedicated:
            return profile.totalGames
        }
    }

    static func progress(for profile: PlayerProfile) -> [AchievementProgress] {
        all.map { achievement in
            AchievementProgress(
                achievement: achievement,
                current: value(of: achievement.kind, profile: profile)
            )
        }
    }

    static func unlockedCount(for profile: PlayerProfile) -> Int {
        progress(for: profile).filter(\.isUnlocked).count
    }
}
