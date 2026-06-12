import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Game Assets
// Central registry for the AI-produced artwork in the asset catalog. Every
// lookup degrades gracefully to nil so views can fall back to SF Symbols and
// gradients when an asset is absent.

enum GameAssets {
    static let menuBackground = "bg_menu"
    static let raidBackground = "bg_raid"
    static let arenaBackground = "bg_arena"
    static let cardBack = "card_back"
    static let packArt = "pack_art"

    /// Maps a champion stringId (champ_001…champ_006) to its portrait asset, if present.
    static func portrait(forChampion stringId: String) -> String? {
        assetIfPresent("portrait_\(stringId)")
    }

    /// Chest artwork for a raid tier (clamped to 1...3).
    static func chestImage(tier: Int) -> String? {
        assetIfPresent("chest_tier\(min(max(tier, 1), 3))")
    }

    static func assetIfPresent(_ name: String) -> String? {
        #if canImport(UIKit)
        return UIImage(named: name) != nil ? name : nil
        #else
        return nil
        #endif
    }
}

// MARK: - Art Background
// Full-bleed painted backdrop with a darkening scrim so UI stays readable.
// Falls back to the existing navy gradient when the artwork is missing.

struct ArtBackground: View {
    let imageName: String
    var darken: Double = 0.45

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [GameTheme.darkNavy, GameTheme.cardBackground],
                startPoint: .top,
                endPoint: .bottom
            )

            if GameAssets.assetIfPresent(imageName) != nil {
                GeometryReader { geo in
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                }
                .overlay(Color.black.opacity(darken))
                .overlay(
                    // Extra bottom scrim so the hand of cards stays legible
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.45)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                )
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

// MARK: - Champion Portrait
// Painted portrait in a gold-ringed circle, falling back to the archetype's
// SF Symbol when no artwork exists for the champion.

struct ChampionPortraitView: View {
    var championId: String?
    var fallbackIcon: String = "person.fill"
    var size: CGFloat = 80
    var ringColor: Color = GameTheme.gold

    var body: some View {
        ZStack {
            if let championId, let asset = GameAssets.portrait(forChampion: championId) {
                Image(asset)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: size, height: size)
                    .overlay(
                        Image(systemName: fallbackIcon)
                            .font(.system(size: size * 0.38))
                            .foregroundColor(ringColor)
                    )
            }
        }
        .overlay(
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [ringColor, ringColor.opacity(0.35)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: max(2, size * 0.03)
                )
        )
        .shadow(color: ringColor.opacity(0.35), radius: size * 0.08)
    }
}

// MARK: - Archetype Icons

extension Archetype {
    var iconName: String {
        switch self {
        case .warrior: return "shield.fill"
        case .rogue: return "swift"
        case .mage: return "wand.and.stars"
        case .paladin: return "cross.fill"
        case .berserker: return "flame.fill"
        case .shadow: return "moon.fill"
        }
    }
}
