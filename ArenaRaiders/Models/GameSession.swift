import Foundation
import SwiftData

enum GamePhase: String, Codable {
    case waiting
    case mulligan
    case playing
    case ended
}

enum TurnPhase: String, Codable {
    case draw
    case main
    case combat
    case end
}

@Model
final class GameSession {
    var id: UUID
    var playerHealth: Int
    var opponentHealth: Int
    var playerMana: Int
    var opponentMana: Int
    var currentTurn: Int
    var isPlayerTurn: Bool
    var gamePhase: GamePhase
    var turnPhase: TurnPhase
    var startedAt: Date
    var endedAt: Date?
    var didPlayerWin: Bool?

    static let startingHealth = 30
    static let startingMana = 1
    static let maxMana = 10

    init() {
        self.id = UUID()
        self.playerHealth = GameSession.startingHealth
        self.opponentHealth = GameSession.startingHealth
        self.playerMana = GameSession.startingMana
        self.opponentMana = GameSession.startingMana
        self.currentTurn = 1
        self.isPlayerTurn = true
        self.gamePhase = .waiting
        self.turnPhase = .draw
        self.startedAt = Date()
    }
}
