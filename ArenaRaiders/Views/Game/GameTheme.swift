import SwiftUI

enum GameTheme {
    // MARK: - Core Colors
    static let darkNavy = Color(red: 15/255, green: 23/255, blue: 42/255)
    static let deepNavy = Color(red: 10/255, green: 15/255, blue: 30/255)
    static let gold = Color(red: 255/255, green: 215/255, blue: 0/255)
    static let darkGold = Color(red: 218/255, green: 165/255, blue: 32/255)

    // MARK: - Surface Colors
    static let cardBackground = Color(red: 30/255, green: 41/255, blue: 59/255)
    static let surfaceDark = Color(red: 22/255, green: 30/255, blue: 48/255)
    static let feltGreen = Color(red: 25/255, green: 50/255, blue: 38/255)
    static let feltDark = Color(red: 18/255, green: 35/255, blue: 28/255)
    static let stoneGray = Color(red: 45/255, green: 50/255, blue: 60/255)
    static let stoneDark = Color(red: 28/255, green: 32/255, blue: 40/255)

    // MARK: - Status Colors
    static let hpGreen = Color(red: 34/255, green: 197/255, blue: 94/255)
    static let hpRed = Color(red: 239/255, green: 68/255, blue: 68/255)
    static let missGray = Color(red: 148/255, green: 163/255, blue: 184/255)
    static let manaBlue = Color(red: 80/255, green: 140/255, blue: 255/255)

    // MARK: - Rarity Colors
    static let rareSilver = Color(red: 180/255, green: 190/255, blue: 200/255)
    static let rareBlue = Color(red: 59/255, green: 130/255, blue: 246/255)
    static let epicPurple = Color(red: 168/255, green: 85/255, blue: 247/255)

    static func rarityColor(_ rarity: Rarity) -> Color {
        switch rarity {
        case .common: return rareSilver
        case .rare: return rareBlue
        case .epic: return epicPurple
        case .legendary: return gold
        }
    }

    static func rarityGlowRadius(_ rarity: Rarity) -> CGFloat {
        switch rarity {
        case .common: return 3
        case .rare: return 6
        case .epic: return 8
        case .legendary: return 10
        }
    }
}
