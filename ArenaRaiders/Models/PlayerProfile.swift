import Foundation
import SwiftData

@Model
final class PlayerProfile {
    var id: UUID
    var username: String
    var avatarName: String
    var gold: Int
    var gems: Int
    var trophies: Int
    var level: Int
    var experience: Int
    var gamesPlayed: Int
    var gamesWon: Int
    var createdAt: Date

    @Relationship(deleteRule: .cascade)
    var decks: [Deck]

    @Relationship(deleteRule: .cascade)
    var cardCollection: [Card]

    init(
        username: String = "Raider",
        avatarName: String = "avatar_default",
        gold: Int = 500,
        gems: Int = 50,
        trophies: Int = 0,
        level: Int = 1,
        experience: Int = 0
    ) {
        self.id = UUID()
        self.username = username
        self.avatarName = avatarName
        self.gold = gold
        self.gems = gems
        self.trophies = trophies
        self.level = level
        self.experience = experience
        self.gamesPlayed = 0
        self.gamesWon = 0
        self.createdAt = Date()
        self.decks = []
        self.cardCollection = []
    }

    var winRate: Double {
        guard gamesPlayed > 0 else { return 0 }
        return Double(gamesWon) / Double(gamesPlayed)
    }
}
