import Foundation
import SwiftData

struct DataManager {
    static let shared = DataManager()

    let modelContainer: ModelContainer

    init() {
        let schema = Schema([
            PlayerProfile.self,
            Champion.self,
            Card.self,
            Deck.self,
            TreasureChest.self,
            GameSession.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    /// Seeds starter data on first launch and ensures a player profile exists
    @MainActor
    func seedOnFirstLaunch() {
        let context = modelContainer.mainContext
        StarterDataLoader.seedIfNeeded(context: context)
    }
}
