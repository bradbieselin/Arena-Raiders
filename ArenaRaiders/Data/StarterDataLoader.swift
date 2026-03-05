import Foundation
import SwiftData

// MARK: - JSON Decodable Structures

struct StarterData: Decodable {
    let meta: MetaInfo
    let champions: [ChampionJSON]
    let cards: [CardJSON]
    let starterDeckSuggestion: StarterDeckJSON
}

struct MetaInfo: Decodable {
    let game: String
    let version: String
    let set: String
    let totalCards: Int
    let totalChampions: Int
}

struct ChampionJSON: Decodable {
    let id: String
    let name: String
    let archetype: String
    let hp: Int
    let avoidance: Int
    let mitigation: Int
    let innatePassive: InnatePassiveJSON
    let tierEffects: [TierEffectJSON]
    let rarity: String
    let flavorText: String
}

struct InnatePassiveJSON: Decodable {
    let name: String
    let description: String
}

struct TierEffectJSON: Decodable {
    let tier: Int
    let name: String
    let description: String
}

struct CardJSON: Decodable {
    let id: String
    let name: String
    let type: String
    let subtype: String?
    let gearSlot: String?
    let resourceCost: Int
    let durability: Int?
    let rarity: String
    let effect: String
    let isInstant: Bool?
    let isTwoHanded: Bool?
    let turnsToComplete: Int?
    let flavorText: String
}

struct StarterDeckJSON: Decodable {
    let name: String
    let champion: String
    let cardList: [DeckCardEntry]
}

struct DeckCardEntry: Decodable {
    let id: String
    let qty: Int
}

// MARK: - Starter Data Loader

struct StarterDataLoader {

    /// Loads the JSON from the app bundle
    static func loadJSON() -> StarterData? {
        guard let url = Bundle.main.url(forResource: "arena_raiders_starter_data", withExtension: "json") else {
            print("StarterDataLoader: JSON file not found in bundle")
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(StarterData.self, from: data)
        } catch {
            print("StarterDataLoader: Failed to decode JSON: \(error)")
            return nil
        }
    }

    /// Seeds all champions, cards, starter deck, and player profile into the given context.
    /// Only runs if no champions exist yet (first launch).
    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        // Check if data already seeded
        let championDescriptor = FetchDescriptor<Champion>()
        let existingChampions = (try? context.fetch(championDescriptor)) ?? []
        guard existingChampions.isEmpty else { return }

        guard let starterData = loadJSON() else { return }

        // Seed champions
        var championMap: [String: Champion] = [:]
        for cJSON in starterData.champions {
            let champion = Champion(
                stringId: cJSON.id,
                name: cJSON.name,
                archetype: Archetype(rawValue: cJSON.archetype) ?? .warrior,
                hp: cJSON.hp,
                avoidance: cJSON.avoidance,
                mitigation: cJSON.mitigation,
                innatePassive: InnatePassive(
                    name: cJSON.innatePassive.name,
                    description: cJSON.innatePassive.description
                ),
                tierEffects: cJSON.tierEffects.map {
                    TierEffect(tier: $0.tier, name: $0.name, description: $0.description)
                },
                rarity: Rarity(rawValue: cJSON.rarity) ?? .common,
                flavorText: cJSON.flavorText
            )
            context.insert(champion)
            championMap[cJSON.id] = champion
        }

        // Seed cards
        var cardMap: [String: Card] = [:]
        for cardJSON in starterData.cards {
            let card = Card(
                stringId: cardJSON.id,
                name: cardJSON.name,
                cardType: CardType(rawValue: cardJSON.type) ?? .ability,
                subtype: cardJSON.subtype.flatMap { CardSubtype(rawValue: $0) },
                gearSlot: cardJSON.gearSlot.flatMap { GearSlot(rawValue: $0) },
                resourceCost: cardJSON.resourceCost,
                durability: cardJSON.durability,
                effectDescription: cardJSON.effect,
                rarity: Rarity(rawValue: cardJSON.rarity) ?? .common,
                isInstant: cardJSON.isInstant ?? false,
                isTwoHanded: cardJSON.isTwoHanded ?? false,
                turnsToComplete: cardJSON.turnsToComplete,
                flavorText: cardJSON.flavorText
            )
            context.insert(card)
            cardMap[cardJSON.id] = card
        }

        // Ensure player profile exists
        let profileDescriptor = FetchDescriptor<PlayerProfile>()
        let existingProfiles = (try? context.fetch(profileDescriptor)) ?? []
        let profile: PlayerProfile
        if let existing = existingProfiles.first {
            profile = existing
        } else {
            profile = PlayerProfile()
            context.insert(profile)
        }

        // Give player the first champion (Vex) unlocked
        if let vex = championMap["champ_001"] {
            profile.unlockedChampions.append(vex)
        }

        // Give player 2 copies of each starter deck card
        let starterDeck = starterData.starterDeckSuggestion
        for entry in starterDeck.cardList {
            if let card = cardMap[entry.id] {
                profile.addCard(card, quantity: entry.qty)
            }
        }

        // Build the starter deck
        if let deckChampion = championMap[starterDeck.champion] {
            var deckCards: [Card] = []
            for entry in starterDeck.cardList {
                if let card = cardMap[entry.id] {
                    for _ in 0..<entry.qty {
                        deckCards.append(card)
                    }
                }
            }

            let deck = Deck(
                name: starterDeck.name,
                champion: deckChampion,
                cards: deckCards
            )
            context.insert(deck)
            profile.savedDecks.append(deck)
        }

        profile.hasCompletedFirstLaunch = true

        do {
            try context.save()
            print("StarterDataLoader: Seeded \(championMap.count) champions, \(cardMap.count) cards, and starter deck")
        } catch {
            print("StarterDataLoader: Failed to save seeded data: \(error)")
        }
    }
}
