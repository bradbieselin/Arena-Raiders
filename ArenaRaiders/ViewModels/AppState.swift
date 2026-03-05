import Foundation
import SwiftUI
import SwiftData

enum Screen: String, CaseIterable {
    case splash
    case main
    case game
}

enum Tab: String, CaseIterable {
    case play
    case collection
    case shop
    case profile

    var title: String {
        rawValue.capitalized
    }

    var systemImage: String {
        switch self {
        case .play: return "gamecontroller.fill"
        case .collection: return "rectangle.stack.fill"
        case .shop: return "cart.fill"
        case .profile: return "person.fill"
        }
    }
}

@Observable
final class AppState {
    var currentScreen: Screen = .splash
    var selectedTab: Tab = .play
    var playerProfile: PlayerProfile?
    var gameSession: GameSession?
    var isLoading: Bool = false

    func navigateTo(_ screen: Screen) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentScreen = screen
        }
    }

    func startNewGame(champion: Champion? = nil, deckCards: [CardReference] = []) {
        gameSession = GameSession(champion: champion, deckCards: deckCards)
        navigateTo(.game)
    }

    func endGame() {
        gameSession = nil
        navigateTo(.main)
    }
}
