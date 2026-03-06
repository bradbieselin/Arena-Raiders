import SwiftUI

enum GameTheme {
    static let darkNavy = Color(red: 15/255, green: 23/255, blue: 42/255)
    static let gold = Color(red: 255/255, green: 215/255, blue: 0/255)
    static let darkGold = Color(red: 218/255, green: 165/255, blue: 32/255)

    static func rarityColor(_ rarity: Rarity) -> Color {
        switch rarity {
        case .common: return .gray
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return gold
        }
    }

    static let cardBackground = Color(red: 30/255, green: 41/255, blue: 59/255)
    static let surfaceDark = Color(red: 22/255, green: 30/255, blue: 48/255)
    static let hpGreen = Color(red: 34/255, green: 197/255, blue: 94/255)
    static let hpRed = Color(red: 239/255, green: 68/255, blue: 68/255)
    static let missGray = Color(red: 148/255, green: 163/255, blue: 184/255)
}
